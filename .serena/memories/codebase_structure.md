# Codebase Structure

```
/
├── db/
│   ├── hc5/portal/          ← HC5 portal SPs (archived, read-only baseline)
│   ├── hc5/app/             ← HC5 app SPs (out of scope)
│   ├── hc5/internal/        ← HC5 internal SPs (out of scope)
│   ├── hc6/portal/          ← Active HC6 portal SPs (hcportal_*.sql)
│   ├── hc6/public-web/      ← Active HC6 public web SPs (publicWeb_*.sql)
│   ├── schema/tables/       ← Base table CREATE OR ALTER statements (source of truth for types)
│   └── contracts/
│       ├── hc5/             ← Extracted HC5 SP contracts (JSON)
│       └── hc6/             ← HC6 SP contracts (JSON)
│
├── api/                     ← Azure Functions .NET API shim
│   └── Endpoints/
│       └── PublicWebApi.cs  ← Unauthenticated GET shim for public web SPs
│
├── portal/                  ← Flutter Web admin portal
│   └── lib/                 ← Dart source
│
├── public-web/              ← Next.js multi-tenant kennel websites
│   ├── app/                 ← App Router pages
│   ├── components/          ← React components
│   │   ├── ui/              ← shadcn/ui base
│   │   └── kennel/          ← Kennel-specific composed components
│   ├── lib/
│   │   └── api.ts           ← Server-side API client (calls PublicWebApi shim)
│   └── public/
│
├── docs/
│   ├── contracts/           ← Auto-generated markdown from contracts
│   └── screens/             ← Screen Behaviour Audits
│
├── agents/
│   ├── prompts/             ← Reusable agent prompt templates
│   └── fixtures/            ← Sanitised sample SP payloads
│
├── tools/                   ← Automation scripts
│   ├── extract_contracts.js ← Contract extraction tool
│   └── deploy_hc6.sh        ← Full HC6 SP deploy script
│
├── tsa-eats/                ← Separate sub-project
├── CLAUDE.md                ← Root project instructions for Claude Code
└── .env                     ← Credentials (DB connection string, ANTHROPIC_API_KEY)
```

## Key Files
- `db/schema/tables/` — always reference these for column types, never assume from memory
- `public-web/CLAUDE.md` — detailed Next.js app rules (theming, animations, API layer)
- `portal/lib/util/uuid_utils.dart` — UUID normalisation utilities
- `portal/lib/imports.dart` — global exports including uuid_utils
