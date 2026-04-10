# Suggested Commands

## Public Web (`/public-web` — Next.js)

```bash
# Dev server
cd public-web && npm run dev

# Build
cd public-web && npm run build

# Lint
cd public-web && npm run lint

# Start production server locally
cd public-web && npm start
```

## Flutter Portal (`/portal`)

```bash
# Run on web (dev)
cd portal && flutter run -d chrome

# Build for web
cd portal && flutter build web --release

# Analyse
cd portal && flutter analyze

# Tests
cd portal && flutter test
```

## Database — Deploy HC6 SPs

```bash
# Deploy all HC6 SPs (run from repo root)
./tools/deploy_hc6.sh
```

## Contract Extraction

```bash
# Extract contract for one SP
node tools/extract_contracts.js hcportal_addEditEvent2

# Extract all portal SP contracts
node tools/extract_contracts.js
# Output: /db/contracts/hc5/<sp_name>.json
# Report: /db/contracts/hc5/_extraction_report.md
# Requires: ANTHROPIC_API_KEY in .env
```

## Deploy Public Web (only when James explicitly asks)

```bash
cd public-web
npm run build
cp -r public .next/standalone/public
cp -r .next/static .next/standalone/.next/static
cd .next/standalone && zip -rq ../../deploy.zip . && cd ../..
az webapp deploy --name harriercentralpublicweb --resource-group harrier --src-path deploy.zip --type zip
rm deploy.zip
```

## Deploy Flutter Portal (only when James explicitly asks)

```bash
cd portal
flutter clean && flutter build web --release
# Then upload /portal/build/web to Azure Blob Storage
```

## Git Convention
- One SP per commit
- Commit message format: `hcportal_<name>: HC5→HC6 migration`
