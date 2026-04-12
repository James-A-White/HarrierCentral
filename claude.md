# Harrier Central — Claude Code Context

This file gives Claude Code the project context it needs to work effectively
on the Harrier Central codebase. Read this before making any changes.

---

## Serena MCP — Semantic Code Tools

Serena is configured for this project and provides symbol-level code navigation.
Prefer Serena tools over basic Read/Grep for these tasks:

- **Finding a symbol** (function, class, method, type): `mcp__serena__find_symbol`
- **Understanding a file's structure** without reading the whole thing: `mcp__serena__get_symbols_overview`
- **Finding all usages** of a symbol across the codebase: `mcp__serena__find_referencing_symbols`
- **Editing a function/method body** precisely: `mcp__serena__replace_symbol_body`
- **Locating a file by name pattern**: `mcp__serena__find_file`
- **Regex search across files**: `mcp__serena__search_for_pattern`

Use Read for files you need to read top-to-bottom. Use Grep for exact string
matches. Use Serena when you need to understand structure, navigate relationships,
or edit at the symbol level.

---

## What This Project Is

Harrier Central is a hash running club management platform built and
maintained by a solo developer (James) working nights and weekends.

**Two important principles:**
1. Don't assume previous AI advice was correct. Think independently and push
   back when you have a better idea.
2. James is using this project to learn modern agentic software development
   practices. Always explain *why* you're recommending something, not just
   *what*. Label learning moments with 🧠.

---

## Architecture

```
Next.js Public Websites (active)     Flutter Web Admin Portal
              ↓                                ↓
         Azure Function .NET Shim (stable, rarely changes)
                            ↓
         SQL Server Stored Procedures (domain logic lives here)
                            ↓
                    SQL Server Tables
```

**Key rules:**
- All frontends call stored procedures only via the API shim
- No direct DB access from any frontend. Ever.
- No dynamic SQL. Ever.
- The API is a transport layer only — logic lives in the database

**Auth (Flutter portal):** Device-bound shared secret → short-lived (30s) cryptographic token

**Auth (Next.js public web):** Standard email/password (NextAuth.js or similar) — separate
from the portal's device-bound auth. The public web has three user populations with
different access levels (see Public Web section below).

---

## Repository Structure

```
/db
  /hc5
    /portal        ← HC5 portal SPs (archived, read-only baseline)
    /app           ← HC5 app SPs (untouched for now)
    /internal      ← HC5 internal SPs (untouched for now)
  /hc6
    /portal        ← New HC6 portal SPs (active work happens here)
    /public-web    ← New HC6 public web SPs (publicWeb_ prefix)
  /schema
    /tables        ← Base table CREATE OR ALTER TABLE statements
  /contracts
    /hc5           ← Extracted HC5 SP contracts (JSON)
    /hc6           ← HC6 SP contracts (JSON)
/api               ← Azure Function .NET source
  /Endpoints/PublicWebApi.cs  ← Unauthenticated GET shim for HC6 public web SPs
/portal            ← Flutter Web admin portal source
/public-web        ← Next.js multi-tenant kennel websites (active — see Public Web section)
  /lib/api.ts      ← Server-side API client (calls PublicWebApi shim)
/docs
  /contracts       ← Auto-generated markdown from contracts
  /screens         ← Screen Behaviour Audits
/agents
  /prompts         ← Reusable agent prompt templates
  /fixtures        ← Sanitised sample SP payloads
/tools             ← Prompt assembly and automation scripts
```

---

## Public Web — Multi-Tenant Kennel Websites

The `/public-web` Next.js app hosts a separate website for every registered kennel
from a single deployment. It is entirely separate from the Flutter admin portal.

### URL / Tenancy Tiers

| Tier | URL Form | Who controls DNS? | Notes |
|------|----------|-------------------|-------|
| 2 (default) | `a.harriercentral.com` | Harrier Central (wildcard `*.harriercentral.com`) | Every kennel gets this automatically |
| 3 (upgrade) | `a.com` | The kennel | Custom domain; requires a domain→slug mapping record in DB |

Tier 1 (`harriercentral.com/a/`) is intentionally skipped — subdomains give each
kennel a cleaner identity and the custom domain upgrade is a hostname swap, not a
URL structure change.

### Tenant Resolution

Next.js middleware inspects each request's hostname to derive the kennel slug:

- `a.harriercentral.com` → slug `a`
- `a.com` → slug looked up from `Kennel.customDomain` in DB → `a`

All page templates receive the resolved kennel context and fetch only that kennel's data.

### User Populations (three tiers)

The public web has three distinct user populations. **Auth is separate from the
Flutter portal's device-bound token system — public web uses standard
email/password (NextAuth.js or similar).**

| Population | Who | What they see |
|------------|-----|---------------|
| **Public** | Anyone, no login | Run calendar, recent trails, club info, social links |
| **Member** | Logged-in registered member of that kennel | All public content + member roster, GPS trails, mis-management contacts, member-only pages |
| **Admin** | Logged-in committee member or mis-management | All member content + kennel management pages (edit runs, manage members, content admin) |

**Key rules:**
- An admin of kennel A must not see admin content for kennel B — auth is always
  scoped to the resolved kennel slug
- Admin access here is for web content management, not the same as Flutter portal
  admin access (which is for platform-level administration)
- A user can be a Member of multiple kennels; their role is kennel-scoped

### Theming

Each kennel has its own visual identity stored in the DB:
- Primary colour, accent colour
- Logo URL
- Club name / short name / tagline

Theme tokens are injected at the tenant-resolution layer and applied via CSS custom
properties. One set of page templates; appearance varies per kennel.

### SEO

- ISR (Incremental Static Regeneration) for performance — Google sees fully-rendered HTML
- Per-tenant `<title>`, `<meta description>`, Open Graph tags
- Canonical URLs: if a kennel is on tier 3, tier 2 URLs redirect to the custom domain
- Per-tenant `sitemap.xml` and `robots.txt`

---

## Current Focus

Migrating `hcportal_` stored procedures from HC5 to HC6.

**Work sequence per SP:**
1. Read the HC5 SP from `/db/hc5/portal/`
2. Read relevant table definitions from `/db/schema/tables/`
3. Extract contract JSON → save to `/db/contracts/hc5/<sp_name>.json`
4. Refactor into HC6 → save to `/db/hc6/portal/<sp_name>.sql`
5. Save HC6 contract → `/db/contracts/hc6/<sp_name>.json`
6. Commit — one SP per commit

**App SPs and internal SPs are out of scope for now. Do not touch them.**

---

## HC6 SP Standards

Every HC6 stored procedure MUST:

```sql
-- 1. Use CREATE OR ALTER
CREATE OR ALTER PROCEDURE [HC6].[hcportal_yourProcName]

-- 2. Have a header block
-- =====================================================================
-- Procedure: HC6.hcportal_yourProcName
-- Description: What this SP does
-- Parameters: List key params
-- Returns: Describe rowsets
-- Author: Harrier Central
-- Created: YYYY-MM-DD
-- HC5 Source: HC5.hcportal_yourProcName
-- Breaking Changes: List any vs HC5
-- =====================================================================

-- 3. SET NOCOUNT and XACT_ABORT
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 4. Wrap main body in TRY/CATCH
BEGIN TRY
    BEGIN TRANSACTION;
    -- logic here
    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;  -- standard success envelope
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;  -- standard error envelope
END CATCH
```

---

## Code Quality Rules

**Always use:**
- `LEN()` for string length checks (not `DATALENGTH`)
- `DECIMAL(10,4)` for monetary values (not `FLOAT`)
- `CREATE OR ALTER PROCEDURE` (not `CREATE` or `ALTER` alone)
- `BIT` for boolean columns (match the table definition exactly)

**UUID normalisation (Flutter/Dart):**

All UUID strings in this project must be lowercase. SQL Server returns
`UNIQUEIDENTIFIER` columns as uppercase; the `uuid` package normalises to
lowercase via `UuidValue.fromString()`. Comparing the two without
normalisation silently returns `false`.

Rules:
- Use `normalizeUuid(string)` or the `.asUuid` extension (from
  `lib/util/uuid_utils.dart`, globally exported via `imports.dart`)
  whenever comparing a UUID string from one source against another.
- Normalise UUID string parameters at the **entry point** of every query
  or service function before using them in API calls or map lookups.
- For new UUID fields in Freezed models, use `@UuidConverter()` + `UuidValue`
  instead of `String` so normalisation is automatic at JSON parse time.
  Plain `String` UUID fields are **not** automatically normalised.
- Never compare two UUID strings with raw `==` unless both are guaranteed
  to already be lowercase (e.g. both came through `UuidValue`).

**BIT columns in Flutter/Dart `fromJson` (API serialisation gotcha):**

The .NET Azure Functions API shim serialises SQL Server `BIT` columns as JSON
booleans (`true`/`false`), not as integers (`1`/`0`). All other integer column
types (`INT`, `SMALLINT`, etc.) come back as `num`/`int` as expected.

Rules:
- Never cast a `BIT`-sourced field with `(json['field'] as int?) == 1` — this
  throws a `TypeError` at runtime when the value is `false` or `true`.
- Always parse `BIT` fields with:
  `json['field'] == true || json['field'] == 1`
  The `== 1` guard defends against any future API behaviour change.
- This applies to every `fromJson` factory that reads a column declared as
  `BIT` in the base table, including hand-written and Freezed models.

**Always flag as code smells:**
- Sentinel magic values (`-1`, `-2`, `'<null>'`, `-99.0`, `-999.0`)
- Inconsistent sentinel values across parameters in the same SP
- Parameters accepted but never used in the SP body (dead inputs)
- Logic called outside a transaction that could leave data inconsistent
- Stub logic (e.g. deletion path that does nothing)
- Wrong SP name in log/error messages
- `FLOAT` for money
- `DATALENGTH` for string checks
- Type or length mismatches between SP parameters and base table columns

---

## Contract Format

Every SP must have a contract JSON file. Use this schema:

```json
{
  "schema": "HC5",
  "name": "sp_name_here",
  "version": "1.0.0",
  "description": "What this SP does",
  "parameters": [
    {
      "name": "paramName",
      "type": "SQL_TYPE",
      "nullable": true,
      "mapsToColumn": "TableName.ColumnName",
      "description": "What this parameter is for",
      "typeMismatch": "Optional: describe mismatch vs table column"
    }
  ],
  "rowsets": [
    {
      "index": 0,
      "ref": "StandardErrorResult",
      "description": "Optional SP-specific notes about the error rowset"
    },
    {
      "index": 0,
      "name": "CustomRowsetName",
      "description": "What these rows represent",
      "columns": [
        {
          "name": "ColumnName",
          "type": "SQL_TYPE",
          "nullable": false,
          "description": "What this column means"
        }
      ]
    }
  ],
  "sideEffects": [],
  "codeSmells": [
    {
      "severity": "high | medium | low",
      "issue": "Short label for the smell",
      "detail": "Full explanation with line numbers and context"
    }
  ],
  "breakingChangeRules": [
    "Never remove a column from any rowset",
    "Never rename a parameter",
    "Never change a parameter type",
    "Never change a sentinel value meaning",
    "Never change errorType integer codes without updating all callers"
  ]
}
```

**mapsToColumn format:** `"TableName.ColumnName"` — no schema prefix, no
brackets. Use `null` for auth/routing parameters that don't map to a column.

### Standard Rowsets

Use `"ref": "StandardErrorResult"` in a rowset entry instead of defining
columns inline. The standard error rowset is shared across all portal SPs.

**StandardErrorResult** — returned on any validation, auth, or runtime error:

| Column | Type | Description |
|--------|------|-------------|
| `errorId` | `UNIQUEIDENTIFIER` | Unique ID of the HC.ErrorLog entry |
| `errorType` | `INT` | Error classification code (see below) |
| `errorTitle` | `NVARCHAR(500)` | Short error title for display |
| `errorUserMessage` | `NVARCHAR(MAX)` | User-facing error message |
| `debugMessage` | `NVARCHAR(MAX)` | Developer-only debug message |
| `errorProc` | `NVARCHAR(128)` | SP name via `OBJECT_NAME(@@PROCID)` |

**errorType codes:**

| Code | Meaning |
|------|---------|
| 2 | Validation error (bad input) |
| 3 | Auth failure or entity not found |
| 4 | Concurrent modification detected |
| 5 | Unhandled database error (from CATCH block) |

When referencing in a contract, add SP-specific notes in the `description`
field (e.g. "Multiple error rowsets possible if validation doesn't
short-circuit").

---

## Known Issues to Fix in HC6

Found by comparing `hcportal_addEditEvent2` against the base tables:

| Parameter | HC5 Type | Table Type | Fix in HC6 |
|-----------|----------|------------|------------|
| `@eventName` | `NVARCHAR(120)` | `NVARCHAR(250)` | Widen to 250 |
| `@locationPostCode` | `NVARCHAR(50)` | `NVARCHAR(250)` | Widen to 250 |
| `@eventPriceFor*` | `FLOAT` | `DECIMAL(10,4)` | Change to DECIMAL |
| `@deleted` | `SMALLINT` | `BIT` | Change to BIT |
| `@integrationEnabled` | `SMALLINT` | `INT` | Change to INT |
| `evtDisseminateAllowWebLinks` | sentinel `2` | should be `-2` | Fix sentinel |

Other known issues:
- `HC.nonApi_updateRunNumbers` called outside transaction — move inside
- Deletion path is a stub — implement or remove
- `@ipAddress` and `@ipGeoDetails` accepted but never used — remove in HC6
- `@isAdmin` set but never used — remove in HC6
- LOG.GeneralLog references wrong SP name — fix in HC6

---

## Guiding Principles

1. **Agents propose. James decides.** Never treat AI output as ready to
   commit without review.
2. **One SP at a time.** Each SP is its own commit. No batch refactors.
3. **Contracts before code.** Extract the HC5 contract before writing HC6.
4. **Break nothing silently.** Every breaking change must be deliberate
   and documented in the contract.
5. **Defer complexity.** Don't build tooling until the pain is real.
6. **Tired-James needs guardrails.** When in doubt, flag it — don't fix it.
7. **Fix mismatches in HC6.** Document in HC5 contract, correct in HC6.

---

## Automation Scripts

```bash
# Extract contract for a single SP
node tools/extract_contracts.js hcportal_addEditEvent2

# Extract contracts for all portal SPs
node tools/extract_contracts.js

# Output: /db/contracts/hc5/<sp_name>.json
# Report: /db/contracts/hc5/_extraction_report.md
```

Requires: `ANTHROPIC_API_KEY` in `.env` at repo root.

### Production Deployment Rule

**Never trigger a production deployment autonomously.** All deployments to
production — whether the Next.js public web, the Azure Functions API shim, or
the SQL Server stored procedures — must be explicitly requested by James in the
conversation. Do not deploy as a side effect of making code changes, even if
asked to "make the change and push it."

---

### Deploying SPs

All SPs (portal and public-web) are deployed via `sqlcmd` using the credentials
in `.env`. The deploy script `tools/deploy_hc6.sh` handles the full HC6 deploy:

```bash
./tools/deploy_hc6.sh
```

It runs four steps in order: HC6 schema → ValidatePortalAuth helper →
all `hcportal_*.sql` portal SPs → all `publicWeb_*.sql` public-web SPs.

### Archiving run-once database scripts

Migrations, data patches, and other run-once scripts must **not** sit alongside
deployable SPs — the deploy script would re-run them on every deploy.

Once a run-once script has been executed:
1. Move it to an `archive/` subdirectory within its current folder
   (e.g. `db/hc6/public-web/archive/`).
2. The deploy script globs are non-recursive, so archived scripts are never
   picked up again.
3. The file remains in git history for reference.

**Rule:** if a SQL file is not a `CREATE OR ALTER PROCEDURE`, it is a run-once
script and must be archived after it has been run.

---

## Table Schemas

Base table definitions are in `/db/schema/tables/`.
Always reference these when working on SPs — never assume column types
from memory.

The most important tables for portal SPs:
- `HC.Event` — core event data
- `HC.Kennel` — club/kennel data
- `HC.Hasher` — user/member data
- `HC.HasherKennelMap` — membership relationships
- `HC.HasherEventMap` — attendance data
- `HC.ErrorLog` — error logging
- `LOG.GeneralLog` — general audit logging

---

*Last updated: March 2026 — added deploy script docs and run-once archive convention*