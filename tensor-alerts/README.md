# Tensor Alerts (Flutter + Node backend)

Minimal Android-only Solana-themed NFT alert app.

## What this app does
- 3 screens only: Home, Add Collection, Filters
- Stores settings in Firestore
- Gets Tensor floor data via REST
- Receives native push notifications via FCM
- Backend keeps one Tensor realtime websocket and fans out matching notifications

---

## 1) Quick start (beginner)

### Prerequisites
- Flutter 3.24+
- Android Studio + SDK
- Firebase project (Firestore + Cloud Messaging)
- Tensor API key from https://dev.tensor.trade/

### Create base Flutter project
```bash
flutter create tensor_alerts
cd tensor_alerts
```

Now copy this repository files into that project folder (overwrite).

### Install deps
```bash
flutter pub get
```

---

## 2) Firebase setup (Android)
1. Firebase Console → create project
2. Add Android app id: `ai.tensor.alerts`
3. Download `google-services.json`
4. Put it at: `android/app/google-services.json`
5. Enable Firestore + Firebase Cloud Messaging

---

## 3) Backend deploy (Render/Railway)

### Files
Backend is in `backend/`.

### Environment variables (from `backend/.env.example`)
- `PORT`
- `TENSOR_WS_URL`
- `TENSOR_API_KEY`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

### Run locally
```bash
cd backend
npm install
npm start
```

### Deploy to Render
1. New Web Service from repo
2. Root directory: `backend`
3. Build command: `npm install`
4. Start command: `npm start`
5. Add environment variables above

After deploy, copy URL like `https://your-backend.onrender.com`.

### Connect app to backend
Build with dart define:
```bash
flutter run --dart-define=BACKEND_BASE_URL=https://your-backend.onrender.com
```

---

## 4) Android release signing (required)

### Generate dedicated keystore
```bash
keytool -genkeypair -v -storetype JKS -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Move keystore to `android/app/upload-keystore.jks`.

Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

`android/app/build.gradle` is already configured for release signing + `minSdk 33`.

### Build signed release APK
```bash
flutter build apk --release --dart-define=BACKEND_BASE_URL=https://your-backend.onrender.com
```

APK path:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 5) Phone-only cloud APK build (GitHub Actions)

Workflow file: `.github/workflows/android-apk.yml`

1. Push this project to GitHub
2. In GitHub: Actions → Build Android APK → Run workflow
3. Download artifact `tensor-alerts-apk`
4. Inside artifact: `app-release.apk`

---

## 6) Publishing to Solana dApp Store

1. Sign up & KYC at https://publish.solanamobile.com
2. Connect Solana wallet & fund ~0.2 SOL for ArDrive
3. Prepare assets:
   - 512×512 icon
   - 1200×600 banner
   - screenshots
4. Build signed release APK with dedicated keystore (never used on Google Play)
5. Upload APK + metadata via portal (or CLI if available)
6. Submit for review

Official docs: https://docs.solanamobile.com/dapp-store/submit-new-app

---

## Notes
- First launch requests push permission
- User pastes Tensor API key via Home → API Key button
- Notifications respect Android system settings / DND / opt-in behavior
- App intentionally excludes wallet connect, chat, trading, sniper features
