# Permissions V2 — Data-Driven Permission System (Build Plan)

_Design agreed 2026-07-27. Replaces the hardcoded permission model (SQL
`CheckKennelPermission` mask literals across 26 SP call sites + the Flutter
`KennelFeature` enum masks) with a single data-driven source of truth._

## Goals
- **One source of truth** for role/flag → function permissions (today it's
  duplicated across 26 SP call sites, the 24-entry Dart enum, an SP header
  comment, and `docs/permissions_matrix.xlsx`, kept in manual sync).
- **Super-admin portal UI** to edit the matrix (role/grantor dropdown →
  function checkboxes, grouped by feature area), plus per-kennel overrides.
- **No behaviour change at cutover** — seed from the current masks so it's a
  faithful lift-and-shift, like the AllowCredit rollout.

## Data model

### Source of truth (3 tables — server reads these directly; not synced to app)
- **`HC.PermissionFunction`** — catalog of gate-able functions.
  `id`, `FunctionKey` (unique, e.g. `viewPaymentReport`), `DisplayName`,
  `FeatureArea`, `HareScoped SMALLINT`, `SortOrder`. Global.
- **`HC.PermissionRole`** — catalog of *grantors* (unifies mismanagement roles
  **and** app-access flags). `id`, `GrantorKey`, `DisplayName`,
  `GrantorType` (`mmRole` | `appFlag` | `bypass`), `Bit INT`, `SortOrder`. Global.
- **`HC.RolePermission`** — the grants. `id`, `GrantorId`, `FunctionId`,
  `KennelId UNIQUEIDENTIFIER NULL`, `Allowed SMALLINT` (domain `{-1,0,1}`).
  - `KennelId NULL` = **global default** (uses `1` = granted; absent = not granted).
  - `KennelId` set = **kennel override**, tri-state:
    `1` = grant, `-1` = revoke, `0`/absent = inherit global.
  - Effective per cell: `CASE kennelRow WHEN 1→granted WHEN -1→revoked ELSE global END`.
  - Index `(FunctionId, KennelId, GrantorId) INCLUDE (Allowed)`; unique
    `(FunctionId, GrantorId, KennelId)` (one global + one row per kennel per cell).

### Projections (compiled read-only caches — the client reads these)
- **`HC.ServerStatus.PermissionMatrixJson NVARCHAR(MAX)`** +
  **`PermissionMatrixUpdatedAt DATETIMEOFFSET(7)`** — the **global** matrix only,
  compiled to resolved `{mmMask, flagMask, hareScoped}` per function. Plain
  `ALTER` (ServerStatus is a singleton, not mobile-synced).
- **`HC.Kennel.PermissionOverrideJson NVARCHAR(MAX) NULL`** — per-kennel resolved
  effective masks, for only the functions that differ from global. Rides the
  existing kennel sync (all users sync all kennels). Trigger-disable `ALTER`
  (synced table, like `AllowCredit`).

**Key trick:** the compile step resolves the tri-state into effective
`{mmMask, flagMask}` per function, so the **client never sees the tri-state** —
it does the exact bitwise test it does today, sourcing masks from JSON instead
of the enum. Tri-state / override complexity stays entirely server-side.

## Server (DB)
- **`CheckKennelPermission` → new signature** `(@userId, @kennelId, @functionKey,
  @allowed OUT)`. Loads user's `mm`/`flags` from `HasherKennelMap`; `SuperAdmin`
  bypass; then `EXISTS(grantor the user holds where EffectiveAllowed(grantor,
  function, kennel) = 1)`. Hare-scope stays inline in the callers (unchanged).
- **Refactor the 26 call sites** from mask literals → their function key.
- **`nonApi_compilePermissionMatrix`** — the ONLY writer of the matrix. In one
  transaction: writes rows, recompiles the global JSON → `ServerStatus`
  (+bump watermark) and each affected kennel's override JSON → `HC.Kennel`.
  Protects the invariant "JSON == tables".
- **`hcapp_approveLogin`** — add `@clientPermissionsWatermark`; return
  `PermissionMatrixJson` + watermark only when the server's is newer.

## Client (app)
- `KennelFeature` enum keeps the **function keys**, drops hardcoded masks (kept
  once as a **bundled default JSON asset** = offline / first-run floor).
- `canAccessFeature(key, mm, flags, isHare)` reads the **merged** JSON
  (`kennelOverride[key] ?? global[key]`) → same
  `SuperAdmin || (mm&mmMask) || (flags&flagMask) || (hare&&hareScoped)` test.
- Store global JSON + watermark from `approveLogin`; per-kennel override rides
  the existing kennel sync.

## Portal (super-admin)
- New screen: grantor dropdown → function checkboxes grouped by area; optional
  kennel picker for overrides (tri-state control: grant / inherit / revoke).
  Saves via `nonApi_compilePermissionMatrix`. Gated by the `assignPermissions`
  function itself.

## Seed & cutover (no-op)
Seed `HC.RolePermission` by **decomposing the current 26 call-site masks** into
grantor rows (bitwise) → reproduces today's behaviour exactly. Compile once to
populate the projections. Nothing changes until the grid is edited.

## Cleanup (last)
Delete orphaned `mmAuthIsGm` / `mmAuthCanGrantPermissions`; remove the now-dead
enum masks.

## Rollout order (Claude builds → James deploys)
1. **DB**: 3 tables + seed + indexes (inert — nothing reads them yet).
2. **DB**: projection columns + `nonApi_compilePermissionMatrix` + initial compile.
3. **DB**: new `CheckKennelPermission` + 26 call sites + `approveLogin` param
   (server data-driven; behaviour identical because seed == current masks).
4. **App**: JSON read + bundled default (client data-driven; identical).
5. **Portal**: the super-admin grid (edits now take effect).
6. **Cleanup**.

Each phase is independently shippable and behaviour-preserving until Phase 5.
