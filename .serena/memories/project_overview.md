# Harrier Central — Project Overview

Hash running club management platform. Solo developer (James), nights/weekends.

## Architecture

```
Next.js Public Websites (/public-web)    Flutter Web Admin Portal (/portal)
                ↓                                      ↓
         Azure Function .NET API Shim (/api) — transport layer only
                            ↓
         SQL Server Stored Procedures — ALL domain logic lives here
                            ↓
                    SQL Server Tables (/db/schema/tables/)
```

- All frontends call stored procedures via the API shim only
- No direct DB access from any frontend. No dynamic SQL. Ever.
- Auth (Flutter portal): device-bound shared secret → short-lived (30s) token
- Auth (Next.js public web): standard email/password via NextAuth.js

## Current Focus

Migrating `hcportal_` stored procedures from HC5 → HC6.

Work sequence per SP:
1. Read HC5 SP from `/db/hc5/portal/`
2. Read table definitions from `/db/schema/tables/`
3. Extract contract JSON → `/db/contracts/hc5/<sp_name>.json`
4. Refactor into HC6 → `/db/hc6/portal/<sp_name>.sql`
5. Save HC6 contract → `/db/contracts/hc6/<sp_name>.json`
6. Commit — one SP per commit

App SPs and internal SPs are out of scope. Do not touch them.
