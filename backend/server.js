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

function matchesFilter(event, c) {
  if (!c.enabled) return false;
  if (event.type === 'sale' && !c.salesAlerts) return false;
  if (event.type === 'bid' && !c.bidAlerts) return false;
  if (event.type === 'floor_drop' && !c.floorDropAlerts) return false;
  if (event.type === 'sale' && Number(event.priceSol || 0) < Number(c.minSalePrice || 0)) return false;
  if (event.type === 'floor_drop' && Number(event.dropPct || 0) < Number(c.floorDropThreshold || 0)) return false;
  const trait = String(c.traitContains || '').toLowerCase();
  if (trait && !String(event.traitsText || '').toLowerCase().includes(trait)) return false;
  return true;
}

async function fanoutNotification(event) {
  const usersSnap = await db.collection('users').get();

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    if (!user.fcmToken) continue;

    const collectionsSnap = await userDoc.ref.collection('collections').get();
    const hit = collectionsSnap.docs
      .map(d => d.data())
      .find(c => c.slug === event.collectionSlug && matchesFilter(event, c));

    if (!hit) continue;

    await admin.messaging().send({
      token: user.fcmToken,
      notification: {
        title: `New ${event.type} on ${event.collectionName || event.collectionSlug}!`,
        body: `${event.priceSol ?? '--'} SOL • ${event.nftName ?? 'NFT'}`,
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
        deeplink: `https://tensor.trade/item/${event.mint}`,
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
        type: msg.type,
        collectionSlug: msg.collectionSlug,
        collectionName: msg.collectionName,
        priceSol: msg.priceSol,
        nftName: msg.nftName,
        imageUrl: msg.imageUrl,
        mint: msg.mint,
        dropPct: msg.dropPct,
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
