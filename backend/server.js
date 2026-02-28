import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import admin from 'firebase-admin';
import WebSocket from 'ws';

const app = express();
app.use(cors());
app.use(express.json());

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  }),
});

const db = admin.firestore();
const port = process.env.PORT || 8080;

// Lightweight in-memory cooldown/rate limiter for proactive floor alerts.
const alertState = new Map(); // key: deviceId:slug -> { lastSentAt, hourStart, hourCount, lastFloor }

app.get('/health', (_, res) => res.json({ ok: true }));

app.post('/register-device', async (req, res) => {
  const { deviceId, fcmToken, tensorApiKey } = req.body;
  if (!deviceId || !fcmToken) return res.status(400).json({ error: 'deviceId and fcmToken required' });
  await db.collection('users').doc(deviceId).set({
    fcmToken,
    tensorApiKey: tensorApiKey ?? null,
    updatedAt: Date.now(),
  }, { merge: true });
  res.json({ ok: true });
});

app.post('/upsert-collection', async (req, res) => {
  const { deviceId, collection } = req.body;
  if (!deviceId || !collection?.slug) return res.status(400).json({ error: 'invalid payload' });
  await db.collection('users').doc(deviceId).collection('collections').doc(collection.slug).set(collection, { merge: true });
  res.json({ ok: true });
});

function passesCadence(deviceId, c, event) {
  const key = `${deviceId}:${c.slug}`;
  const now = Date.now();
  const state = alertState.get(key) ?? {
    lastSentAt: 0,
    hourStart: now,
    hourCount: 0,
    lastFloor: Number(c.floorPrice || 0),
  };

  const minIntervalMs = (Number(c.minIntervalMinutes || 30) * 60 * 1000);
  if (now - state.lastSentAt < minIntervalMs) return false;

  if (now - state.hourStart > 60 * 60 * 1000) {
    state.hourStart = now;
    state.hourCount = 0;
  }
  if (state.hourCount >= Number(c.maxAlertsPerHour || 4)) return false;

  if (event.type === 'floor') {
    const previous = Number(state.lastFloor || 0);
    const current = Number(event.floorPriceSol || 0);
    const absSol = Math.abs(current - previous);
    const pct = previous > 0 ? (absSol / previous) * 100 : 0;

    const minPct = Number(c.floorMovePercentThreshold || 2);
    const minSol = Number(c.floorMoveSolThreshold || 0.2);
    if (pct < minPct && absSol < minSol) return false;
  }

  state.lastSentAt = now;
  state.hourCount += 1;
  if (event.type === 'floor') state.lastFloor = Number(event.floorPriceSol || state.lastFloor);
  alertState.set(key, state);
  return true;
}

function matchesFilter(event, c) {
  if (!c.enabled) return false;
  if (event.type === 'sale' && !c.salesAlerts) return false;
  if (event.type === 'bid' && !c.bidAlerts) return false;
  if (event.type === 'floor' && !c.floorDropAlerts) return false;

  if (event.type === 'sale' && Number(event.priceSol || 0) < Number(c.minSalePrice || 0)) return false;
  if (event.type === 'floor' && Number(event.dropPct || 0) < Number(c.floorDropThreshold || 0)) return false;

  const trait = String(c.traitContains || '').toLowerCase();
  if (trait && !String(event.traitsText || '').toLowerCase().includes(trait)) return false;
  return true;
}

function buildNotification(event) {
  if (event.type === 'floor') {
    const direction = Number(event.deltaPct || 0) >= 0 ? '+' : '';
    return {
      title: `Tensor Alert • ${event.collectionName || event.collectionSlug}`,
      body: `Floor moved ${direction}${Number(event.deltaPct || 0).toFixed(2)}% (${Number(event.deltaSol || 0).toFixed(2)} SOL)`
    };
  }
  if (event.type === 'sale') {
    return {
      title: `New sale on ${event.collectionName || event.collectionSlug}!`,
      body: `${event.priceSol ?? '--'} SOL • ${event.nftName ?? 'NFT'}`,
    };
  }
  return {
    title: `New bid on ${event.collectionName || event.collectionSlug}!`,
    body: `${event.priceSol ?? '--'} SOL • ${event.nftName ?? 'NFT'}`,
  };
}

async function fanoutNotification(event) {
  const usersSnap = await db.collection('users').get();

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    if (!user.fcmToken) continue;

    const collectionsSnap = await userDoc.ref.collection('collections').get();
    const matching = collectionsSnap.docs
      .map(d => d.data())
      .find(c => c.slug === event.collectionSlug && matchesFilter(event, c) && passesCadence(userDoc.id, c, event));

    if (!matching) continue;

    const payload = buildNotification(event);
    await admin.messaging().send({
      token: user.fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
        imageUrl: event.imageUrl || undefined,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'tensor-alerts',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      data: {
        deeplink: event.mint ? `https://tensor.trade/item/${event.mint}` : `https://tensor.trade/trade/${event.collectionSlug}`,
      },
    });
  }
}

function connectTensor() {
  const ws = new WebSocket(process.env.TENSOR_WS_URL, {
    headers: { 'x-tensor-api-key': process.env.TENSOR_API_KEY || '' },
  });

  ws.on('open', () => {
    console.log('[tensor] connected');
    ws.send(JSON.stringify({ action: 'subscribe', channels: ['sales', 'bids', 'floor'] }));
  });

  ws.on('message', async (raw) => {
    try {
      const msg = JSON.parse(raw.toString());
      const event = {
        type: msg.type, // sale | bid | floor
        collectionSlug: msg.collectionSlug,
        collectionName: msg.collectionName,
        priceSol: msg.priceSol,
        floorPriceSol: msg.floorPriceSol,
        deltaSol: msg.deltaSol,
        deltaPct: msg.deltaPct,
        dropPct: msg.dropPct,
        nftName: msg.nftName,
        imageUrl: msg.imageUrl,
        mint: msg.mint,
        traitsText: msg.traitsText,
      };
      await fanoutNotification(event);
    } catch (e) {
      console.error('message parse/send error', e.message);
    }
  });

  ws.on('close', () => {
    console.warn('[tensor] disconnected, reconnecting in 5s');
    setTimeout(connectTensor, 5000);
  });

  ws.on('error', (e) => console.error('[tensor] ws error', e.message));
}

connectTensor();
app.listen(port, () => console.log(`tensor-alerts backend running on :${port}`));
