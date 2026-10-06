# Mobile App — Claude Code Context

This file covers the `/mobile-app` Flutter project only.
Read the root `CLAUDE.md` first for the overall Harrier Central architecture.

The Flutter and Dart rules are in `.claude/rules/flutter.md` and load when
you open a Dart file.

---

### Mobile app — required skills

**When working in `mobile-app/`, you MUST invoke these skills before writing
or reviewing any code.** These are non-negotiable — do not skip them even for
"small" fixes.

#### Always load at session start

| Skill | Why it's mandatory |
|---|---|
| `/hc-sync-domains` | Defines which tables exist in which local DB domain (common/kennel/event). Domain mistakes are completely silent — no compile error, no exception, just missing or wrongly-scoped data. Skipping this caused a bug where kennel data was silently dropped because `KennelsTableHelper.getTableName` was called with the wrong domain type. |
| `/hc-access-tokens` | Defines how access tokens are generated and validated for every SP call. Token mistakes (wrong format, wrong compound suffix) produce auth failures with no indication of the root cause. |

#### Load when the work requires it

| Skill | Load when… |
|---|---|
| `/hc6-adhoc-data` | Working with SP responses that return non-sync data (e.g. a generated ID after an insert, status flags). Required any time you design or consume the `adHocDataId` pattern. |
| `/packtrack` | Working on any part of the live run tracking feature (GPS sending, map display, position retrieval). |
| `/hc-api-endpoints` | Adding a new SP, adding a new service method, or any work that touches the API shim. Prevents unnecessary API changes — new HC6 SPs are callable immediately after deploy with no API modification. |
| `/hc-monitoring` | James asks how a rollout is looking, "any errors?", or before a release is called healthy. Runs `tools/log_sweep.sh` and reads `HC.ErrorLog` / `HC.ClientErrorLog` / `HC.Device` with the interpretation rules (599 = local stall, empty 500 = shim, `HC.Device.Version` is *current* not at-time-of-log). |
| `/hc-event-datetimes` | Any work that filters, sorts, groups, or displays a run/event start time — SPs, public-web feeds, portal views, or mobile queries. Choosing the wrong datetime column is silently wrong (instant ⇒ `EventStartDateTimeGmt`; local clock ⇒ `EventStartLocal`/`EventStartLocalDate`; raw `EventStartDatetime` has a spurious `+00:00` on ~67% of rows). |

---

## Mobile App — Flutter iOS/Android

The `/mobile-app` Flutter project is the original Harrier Central client app,
targeting iOS and Android. It is the **last major component** to be migrated to
agentic AI development practices and HC6.

### History

- Started ~5 years ago when Flutter was at version 0.8 — predates null-safety,
  GetX, and Freezed
- Underwent a major rewrite when Flutter 3.x introduced null-safety
- GetX was adopted during the rewrite for state management and clean separation
  of business logic from UI
- Freezed was adopted for immutable data models (reduces boilerplate, safer
  model handling)
- The codebase carries significant technical debt from the pre-null-safety era
  and the rewrite — expect inconsistency in patterns across older and newer code

### Key Stack Choices

| Concern | Approach |
|---------|----------|
| State management / routing | GetX |
| Immutable models | Freezed |
| Auth | Device-bound shared secret → short-lived cryptographic token |
| API | Same Azure Function shim as portal and public web |

### Migration Approach

The app SPs (`/db/hc5/app/`) are in scope for HC6 migration as part of this
work. Follow the same SP migration sequence used for the portal SPs. App SPs
use the `hcapp_` prefix in HC6.

**App SP work sequence:**
1. Read the HC5 SP from `/db/hc5/app/`
2. Read relevant table definitions from `/db/schema/tables/`
3. Extract contract JSON → save to `/db/contracts/hc5/<sp_name>.json`
4. Refactor into HC6 → save to `/db/hc6/app/<sp_name>.sql`
5. Save HC6 contract → `/db/contracts/hc6/<sp_name>.json`
6. Commit — one SP per commit
