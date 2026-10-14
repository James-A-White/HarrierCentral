# CLAUDE.md restructure — October 2026

The root instruction file had grown to 1,214 lines, about twice its size in
June. Everything in it loaded into every session, whatever the session was
working on, and Claude Code's own guidance is that a file that long is followed
less reliably. It was also named `claude.md`, which Claude Code does not load on
a case-sensitive filesystem, so cloud sessions and CI never saw it.

This change renames the file and splits it by when each part is needed:

- **Always on** — `CLAUDE.md`: what the project is, the architecture, the
  non-negotiables, the deployment rule, and the backlog and issue habits.
- **When you open a matching file** — `.claude/rules/*.md`, each with a `paths`
  list.
- **When you work in a sub-project** — `mobile-app/CLAUDE.md`, alongside the
  existing `public-web/CLAUDE.md` and `tsa-eats/CLAUDE.md`.
- **When James asks for a release** — `.claude/skills/dance-baby/SKILL.md`.

Text was moved, not rewritten. Every non-blank line of the old file is present
verbatim in one of the new files or in the retired sections below, apart from
the handful of reworded lines listed at the end.

## Where each section went

Line numbers are from the last 1,214-line version (commit `b84aa71`).

| Original section | Lines | Now in |
|---|---|---|
| Title and intro | 1–6 | `CLAUDE.md`, reworded to explain the split |
| Session Start: backlog read, `todos/` retirement | 8–24 | `CLAUDE.md` |
| Product backlog: rendering | 26–36 | `.claude/rules/backlog.md` |
| When to update the backlog | 38–46 | `CLAUDE.md` |
| Backlog rules: IDs, status, personas | 48–58 | `.claude/rules/backlog.md` |
| Bugs and work items: GitHub Issues | 60–73 | `CLAUDE.md` |
| Mobile app: required skills | 75–96 | `mobile-app/CLAUDE.md` |
| Non-Negotiable Design Decisions | 100–143 | `CLAUDE.md` |
| Serena MCP | 147–161 | `CLAUDE.md` |
| What This Project Is | 165–175 | `CLAUDE.md` |
| Architecture and key rules | 179–195 | `CLAUDE.md` |
| Which SP does the web call? | 197–233 | `.claude/rules/web-sp-wrap-or-query.md` |
| Auth | 235–242 | `CLAUDE.md`; last sentence retired |
| Repository Structure | 246–276 | Retired; `CLAUDE.md` has a new listing checked against the tree |
| Mobile App | 280–319 | `mobile-app/CLAUDE.md` |
| Public Web | 323–400 | Retired; `public-web/CLAUDE.md` covers it |
| Current Focus | 404–431 | Retired |
| HC6 SP Standards | 435–532 | `.claude/rules/sql-stored-procedures.md` |
| Code quality: SQL types, `BIT` | 538–542, 552–557 | `.claude/rules/sql-stored-procedures.md` |
| Code quality: delimited lists | 544–550 | `CLAUDE.md` |
| Code quality: Flutter and Dart | 559–623, 697–759, 773–858 | `.claude/rules/flutter.md` |
| Trail photos, kennel logos | 625–695 | `.claude/rules/photos-and-logos.md` |
| ALTER TABLE on synced tables | 761–771 | `.claude/rules/sql-stored-procedures.md` |
| Code smells | 860–889 | `.claude/rules/sql-stored-procedures.md` |
| Contract Format, Standard Rowsets | 893–981 | `.claude/rules/sp-contracts.md` |
| Known Issues to Fix in HC6 | 985–1003 | Retired |
| Guiding Principles | 1007–1017 | `CLAUDE.md` |
| Automation Scripts | 1021–1034 | Retired |
| Production Deployment Rule | 1036–1045 | `CLAUDE.md`; last sentence reworded |
| "Dance baby!" | 1049–1143 | `.claude/skills/dance-baby/SKILL.md` |
| Deploying SPs | 1147–1179 | `.claude/skills/dance-baby/SKILL.md` |
| Archiving run-once scripts | 1181–1194 | `.claude/rules/sql-stored-procedures.md` |
| Table Schemas | 1198–1211 | `.claude/rules/sql-stored-procedures.md` |
| Footer | 1215 | Retired |

## What changed in behaviour

Three things are new rather than moved. Each is a proposal on this branch.

1. **The release runbook no longer loads unless asked for.** It is a skill
   marked `disable-model-invocation`, and `CLAUDE.md` tells Claude to read it
   when James says "Dance baby!" or "I want a private dance".
2. **Deploy commands prompt in every permission mode.** `.claude/settings.json`
   gains `ask` rules for `tools/deploy_hc6.sh`, `func azure functionapp publish`,
   `az webapp deploy` and pushes to `master`. A release will stop for approval at
   each of those steps. Remove a rule to remove its prompt.
3. **A commit that touches mobile Dart files runs the two scans first.**
   `.claude/hooks/dart-scans.sh` runs `tools/button_text_scan.py` and
   `tools/id_case_scan.py` before `git commit` and blocks the commit if either
   prints anything. Both pass on this branch. The hook matches any Bash command
   containing `git commit`, so a command that merely mentions it is also checked.

One thing to know about path-scoped rules: they load when Claude **reads** a
matching file. Writing a brand-new file without reading anything nearby does not
load them, which is why `CLAUDE.md` ends by telling Claude to read the rule file
itself in that case.

## How this was checked

All of this was run with Claude Code 2.1.291 on Linux.

- **Nothing lost.** A script compared every non-blank line of the old file
  against the new files. Three lines differ, and all three are headings or the
  retired Auth sentence.
- **File name.** A lowercase `claude.md` was not loaded; `CLAUDE.md` was.
- **Path-scoped rules.** A rule scoped to `src/**` was absent at session start,
  present after reading `src/a.txt`, and still absent after reading a file
  elsewhere.
- **Commit hook.** With a Dart file that broke both scans, `git add -A && git
  commit` was blocked and the findings were returned to Claude. With a harmless
  Dart change, and with no Dart change, the commit went through.
- **`ask` rules.** In a headless run with Bash otherwise allowed, a control
  script ran and `./tools/deploy_hc6.sh` was refused. So an unattended session
  cannot deploy at all; an interactive one stops and asks.

Not checked: an interactive release from start to finish with the new prompts,
and anything on macOS.

## Decisions this change did not make

These need James. Nothing below was edited.

1. **`hc-avatars` against the photo rules.** The skill says to render with
   `BoxFit.cover` or `CircleAvatar.backgroundImage`. The photo rule (2026-10-02)
   says profile photos are square, shown whole, never trimmed into a circle.
2. **`hc-debugging` against `hc-monitoring`.** The first says log harvest is off
   for everyone by default and enabled per tester. The second says it has been
   on for every user since 2026-08-30.
3. **`hc-chat` against itself.** One section says Rowset 2 gates on the full
   effective preference; "Things to Watch Out For" says it uses
   `KennelNotificationPreference` only.
4. **`packtrack` against itself.** Android interval is given as 15 s and, later,
   as 5 s on every tier since 2026-10-02. The flush trigger is given as 60 s and,
   elsewhere, as the 30 s / 1–3 min cadence table.
5. **`.serena/memories/`**, untouched since 2026-06-01. They say to use `BIT`
   for booleans, that public web auth is NextAuth email and password, and that
   app SPs are out of scope. Each contradicts a current rule.
6. **Session start still reads all of `docs/backlog.md`** (about 215 KB). A
   script that prints only the `Building` and `Next` stories for one component
   would cost a fraction of that.
7. **Notes that live outside the repository.** These are cited by name but are
   not in the repo, so a session on another machine cannot read them:
   `reference_testflight_deploy.md`, `reference_public_web_deploy.md`,
   `reference_device_log_harvest`, `project_permissions_audit`,
   `project_admin_entry_gating`, `project_sp_index_audit`,
   `project_retire_hc5_todos`, `feedback_trigger_disable_before_alter`,
   `http-one-shot-clients`, `signup-broken-five-ways`,
   `simulator-poisons-release`.
8. **`paths` on skills.** Only the rule files are path-scoped. The skills were
   left available everywhere, as before.
9. **`tsa-eats/CLAUDE.md`** uses absolute paths under `/Users/jawDev/`, so its
   deploy steps only work on one machine.
10. **`CONTRIBUTING.md`** points to "the API endpoints section of `CLAUDE.md`".
    That content is the `hc-api-endpoints` skill.

## Retired sections

Kept here verbatim so nothing is lost. None of this is loaded by Claude Code.

### Repository Structure (lines 246–276)

Retired because it listed `/agents/fixtures` and `/docs/contracts`, which do not
exist, and left out `db/hc6/app`, `tools/` and three top-level projects.

~~~~markdown
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
  /Endpoints/PublicWebApi.cs       ← Unauthenticated GET shim for HC6 public web SPs
  /Endpoints/PublicWebAdminApi.cs  ← Authenticated POST shim for admin operations (save layout, redeem token)
/portal            ← Flutter Web admin portal source
/public-web        ← Next.js multi-tenant kennel websites (active — see Public Web section)
  /lib/api.ts      ← Server-side API client (calls PublicWebApi shim)
/mobile-app        ← Flutter iOS/Android mobile app (active — see Mobile App section)
/docs
  /contracts       ← Auto-generated markdown from contracts
  /screens         ← Screen Behaviour Audits
/agents
  /prompts         ← Reusable agent prompt templates
  /fixtures        ← Sanitised sample SP payloads
/tools             ← Prompt assembly and automation scripts
```
~~~~

### Public Web (lines 323–400), and the last sentence of the Auth paragraph

Retired because `public-web/CLAUDE.md` covers every subsection in more detail,
and because this copy says member auth is not implemented when it is (E9.F7).
The retired Auth sentence was: "Member and public auth are not yet implemented."

~~~~markdown
## Public Web — Multi-Tenant Kennel Websites

The `/public-web` Next.js app hosts a separate website for every registered kennel
from a single deployment. It is entirely separate from the Flutter admin portal.

### URL / Tenancy Tiers

| Tier | URL Form | Who controls DNS? | Notes |
|------|----------|-------------------|-------|
| 2 (default) | `www.hashruns.org/a` | Harrier Central | Path-based — no wildcard cert needed for hashruns.org |
| 3 (upgrade) | `a.com` | The kennel | Custom domain; middleware rewrites to internal `/a` path |

Tier 1 (`hashruns.org/` root) is the global discovery page — upcoming runs across all kennels.

**Note:** `harriercentral.com` subdomain URLs (`a.harriercentral.com`) are defined in
`SYSTEM_HOSTS` in the middleware but are not the primary URL scheme. All kennel pages
are served under `www.hashruns.org/<slug>` to avoid the need for a wildcard SSL cert.

### Tenant Resolution

The Next.js middleware handles only custom domains (Tier 3). For Tier 2, Next.js
routes `www.hashruns.org/<slug>` natively via the `app/[slug]` dynamic route — no
middleware intervention needed.

- `www.hashruns.org/a` → `app/[slug]/page.tsx` with `slug = "a"`
- `a.com` → middleware looks up slug from `HC.KennelWebsite.CustomDomain` in DB,
  rewrites request to internal `/a` path

All page templates receive the resolved kennel context and fetch only that kennel's data.

### Legacy URL Shim

The old hashruns.org site (pre-HC6) used a hash-based SPA URL scheme:

```
www.hashruns.org/#/RD?publicKennelIds=<uuid>[,<uuid>...]
```

This scheme is **deprecated**. The `LegacyRedirectHandler` client component
(`app/(global)/LegacyRedirectHandler.tsx`) detects these URLs on load, calls
`/api/resolve-kennels` to resolve UUIDs to slugs, and redirects to the new
path-based URL. Remove the shim once no inbound legacy links remain in the wild.

### User Populations (three tiers)

The public web has three distinct user populations. **Admin auth uses OTP tokens
from the Flutter portal (see Auth section above). Member and public auth are not
yet implemented.**

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
~~~~

### Current Focus (lines 404–431)

Retired because it is dated 2026-05-10 and says app SPs are out of scope and
must not be touched. `db/hc6/app` now holds 107 `hcapp_` procedures, and the
Mobile App section says they are in scope. `docs/backlog.md` is the record of
what is being built.

~~~~markdown
## Current Focus

Active work is the **Flutter mobile app** — migrating the iOS/Android app to
agentic AI development practices and HC6. This is the last of the five major
components to be migrated. See the Mobile App section below for full context.

**What's been shipped (as of 2026-05-10):**
- All 23 `hcportal_` SPs migrated to HC6 with device-bound auth
- Flutter portal on HC6 API throughout
- Public web: kennel landing pages, runs, stats, songs, events, about, run detail
- Puck page builder: all 6 top-level pages editable per kennel, layouts stored in `HC.KennelWebsite.PageLayoutJson`
- Admin auth: OTP token flow (Flutter portal → URL token → HMAC session cookie)

**Public web next likely areas (lower priority while mobile is active):**
- Member login system (not yet designed)
- More Puck blocks (image, text, social links, etc.)
- Theme editor (colour pickers, background image, CSS variable wiring)
- Events page implementation (currently a placeholder block)

**SP work sequence (if returning to SPs):**
1. Read the HC5 SP from `/db/hc5/portal/`
2. Read relevant table definitions from `/db/schema/tables/`
3. Extract contract JSON → save to `/db/contracts/hc5/<sp_name>.json`
4. Refactor into HC6 → save to `/db/hc6/portal/<sp_name>.sql`
5. Save HC6 contract → `/db/contracts/hc6/<sp_name>.json`
6. Commit — one SP per commit

**App SPs and internal SPs are out of scope for now. Do not touch them.**
~~~~

### Known Issues to Fix in HC6 (lines 985–1003)

Retired because the header of `HC6.hcportal_addEditEvent` (created 2026-03-15)
records each of these as done.

~~~~markdown
## Known Issues to Fix in HC6

Found by comparing `hcportal_addEditEvent2` against the base tables:

| Parameter | HC5 Type | Table Type | Fix in HC6 |
|-----------|----------|------------|------------|
| `@eventName` | `NVARCHAR(120)` | `NVARCHAR(250)` | Widen to 250 |
| `@locationPostCode` | `NVARCHAR(50)` | `NVARCHAR(250)` | Widen to 250 |
| `@eventPriceFor*` | `FLOAT` | `DECIMAL(10,4)` | Change to DECIMAL |
| `@deleted` | `SMALLINT` | `BIT` | Keep as SMALLINT (BIT column but we never use BIT — implicit conversion) |
| `@integrationEnabled` | `SMALLINT` | `INT` | Change to INT |
| `evtDisseminateAllowWebLinks` | sentinel `2` | should be `-2` | Fix sentinel |

Other known issues:
- `HC.nonApi_updateRunNumbers` called outside transaction — move inside
- Deletion path is a stub — implement or remove
- `@ipAddress` and `@ipGeoDetails` accepted but never used — remove in HC6
- `@isAdmin` set but never used — remove in HC6
- LOG.GeneralLog references wrong SP name — fix in HC6
~~~~

### Automation Scripts (lines 1021–1034)

Retired because `tools/extract_contracts.js` is not in the repository.

~~~~markdown
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
~~~~

### Reworded lines

~~~~markdown
This file gives Claude Code the project context it needs to work effectively
on the Harrier Central codebase. Read this before making any changes.

The explicit request is either a specific deploy instruction ("deploy the API")
or the **"Dance baby!"** command below.

*Last updated: March 2026 — added deploy script docs and run-once archive convention*
~~~~

The intro now explains the split. The deployment sentence said the release
command was "below"; it now names both release commands. The footer said the
file was last updated in March 2026; the commit log is the record.
