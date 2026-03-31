# TSA Eats — Claude Code Context

## Deployment Rule

**Never deploy autonomously.** Only deploy when James explicitly asks.

When asked to deploy:

1. **If no description of what has changed is provided, ask for one before proceeding.**

2. **Bump the version** — increment the minor version by 1 in `package.json`:
   - `0.1` → `0.2`, `0.9` → `0.10`, `0.10` → `0.11`, `2.1` → `2.2`, `2.10` → `2.11`
   - The patch component is always `0` (stored as `X.Y.0` in `package.json`)
   - Current version: `0.1.0`

3. **Build and deploy to production** using these steps (always use absolute paths):
   ```bash
   cd /Users/jawDev/Development/HarrierCentral/tsa-eats && npm run build

   cp -r /Users/jawDev/Development/HarrierCentral/tsa-eats/public \
         /Users/jawDev/Development/HarrierCentral/tsa-eats/.next/standalone/public
   cp -r /Users/jawDev/Development/HarrierCentral/tsa-eats/.next/static \
         /Users/jawDev/Development/HarrierCentral/tsa-eats/.next/standalone/.next/static

   cd /Users/jawDev/Development/HarrierCentral/tsa-eats/.next/standalone
   zip -r /Users/jawDev/Development/HarrierCentral/tsa-eats/deploy.zip . -x "*.DS_Store" -q

   az webapp deploy \
     --name harriercentraltsaeats \
     --resource-group harrier \
     --src-path /Users/jawDev/Development/HarrierCentral/tsa-eats/deploy.zip \
     --type zip

   rm /Users/jawDev/Development/HarrierCentral/tsa-eats/deploy.zip
   ```

4. **Commit to master** once deployment is confirmed successful:
   - Commit message: `X.Y: <description of what changed>`
   - Stage all changed source files (do NOT commit `.next/`, `deploy.zip`, or `node_modules/`)

---

## App Service

- Name: `harriercentraltsaeats`
- Resource group: `harrier`
- Custom domains: `tsaeats.org`, `www.tsaeats.org`, `admin.tsaeats.org`, `signup.tsaeats.org`, `restaurant.tsaeats.org`

## Subdomain Routing (middleware.ts)

| Subdomain | Routes to | Notes |
|-----------|-----------|-------|
| `admin.tsaeats.org` | `/admin` | Auth-gated; login at `admin.tsaeats.org/login` |
| `signup.tsaeats.org` | `/register` | Public; convenience link for new user signup |
| `restaurant.tsaeats.org` | `/restaurant-portal` | Auth-gated; login at `restaurant.tsaeats.org/login`; scan at `/scan/{token}` |
| `www.tsaeats.org` | `tsaeats.org` (301) | Canonical redirect via `next.config.ts` |
