# Tech Stack

## Public Web (`/public-web`)
- Next.js 16 App Router (React 19)
- TypeScript
- Tailwind CSS v4
- shadcn/ui (Radix primitives, copy-into-project model)
- Framer Motion (scroll-triggered entrances)
- Lenis / react-lenis (smooth scroll)
- NextAuth.js (email/password auth)
- React-Leaflet (maps, GPX trails)
- Recharts (elevation profiles)

## Admin Portal (`/portal`)
- Flutter Web (Dart), version 1.3.5+606, Flutter ^3.41.2, SDK >=3.3.1

## API Shim (`/api`)
- Azure Functions, .NET
- Key file: `api/Endpoints/PublicWebApi.cs` — unauthenticated GET shim for public web SPs

## Database
- SQL Server
- All logic in stored procedures
- HC5 SPs: `/db/hc5/portal/`
- HC6 SPs: `/db/hc6/portal/` (portal), `/db/hc6/public-web/` (public web)
- Table schemas: `/db/schema/tables/`
- Contracts: `/db/contracts/hc5/` and `/db/contracts/hc6/`

## Key Tables
- `HC.Event`, `HC.Kennel`, `HC.Hasher`, `HC.HasherKennelMap`, `HC.HasherEventMap`
- `HC.ErrorLog`, `LOG.GeneralLog`, `HC.KennelWebsite`
