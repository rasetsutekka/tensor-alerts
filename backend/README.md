# Tensor Alerts Backend

## Run
```bash
npm install
cp .env.example .env
npm start
```

## Endpoints
- `GET /health`
- `GET /solana/status` (checks Solana Agent Kit wiring)
- `GET /solana/balance` (defaults to agent wallet)
- `GET /solana/balance?wallet=<base58_pubkey>`
- `POST /register-device`
- `POST /upsert-collection`

## Solana Agent Kit setup
1. Add to `.env`:
   - `SOLANA_PRIVATE_KEY` (base58 private key)
   - `SOLANA_RPC_URL` (optional, defaults to mainnet RPC)
2. Restart backend and test:
```bash
curl http://localhost:8080/solana/status
curl http://localhost:8080/solana/balance
```

## Deploy
Use Render/Railway as a Node web service with start command:
`npm start`
