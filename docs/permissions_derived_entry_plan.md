# Permissions — Derived Entry + Surface Scope (plan)

## Status / decisions log
- **Phase 1 DONE (2026-07-28).** `Surfaces` (SMALLINT, default 3) + `AreaKey`
  (NOT NULL) added to `HC.PermissionFunction`; 24 rows backfilled
  (runAdmin/kennelTools/photos/web/songs), `IX_PermissionFunction_Area` created.
  Migration: `db/hc6/app/archive/migration_permissions_v4_01_surfaces_areakey.sql`.
  Everything Surfaces=3. No recompile (compile SP doesn't read new cols until Ph4).
- **Phase 2 DONE (2026-07-28).** `HC6.CheckAreaEntry` deployed. Reconciliation diff:
  **11 deltas, all global, zero kennel overrides.** 8 GAINS (roles with a real
  capability but no explicit gate — dead capabilities now reachable), 3 LOSES
  (orphaned gates: Hash Flash runAdmin+kennelTools, RA kennelTools — roles with no
  capability in that area). **James: accept all 11 as-is** (no grants). **Photos
  has its OWN entry point** → Hash Flash/RA reach photos via the photos doorway;
  Phase 5 must wire `canEnterArea('photos', app)`.
- **Phase 3 DONE (2026-07-28).** `hcapp_syncEventAdminData` now gates on
  `CheckAreaEntry('runAdmin', app, @isHareOfEvent)`; `hcapp_syncKennelAdminData` on
  `CheckAreaEntry('kennelTools', app)`. Explicit `enter*` rows still present (no gap).
  Verified on real data: 14,737 user-kennel pairs, 84 mismatches vs the old gates,
  **0 unexplained** (all held by one of the 11 accepted delta grantors); hare leg
  confirmed (plain member: not-hare→0, as-hare→1).
- **NEXT: Phase 4** (awaiting go-ahead) — compile SP emits areas+surfaces, drops
  `enter*` from JSON, and the explicit `enter*` rows/grants are deleted. Ships as one
  coordinated release with Phase 5 (app) + Phase 6 (portal).

---

Evolution of the Permissions V2 system (`docs/permissions_v2_plan.md`). Two goals:

1. **Entry is purely derived** — a UI "doorway" (the app's Run/Kennel Admin gear,
   the portal's section) is *shown iff the user holds ≥1 capability in that area*.
   `enterRunAdmin` / `enterKennelAdmin` stop being editable permissions and become
   computed. Applies to hares too: a hare's doorway is derived from the
   hare-granted capabilities for the event they hare.
2. **Surface scope** — each capability carries a `Surfaces` bitmask
   (`app=1`, `portal=2`, both=`3`). A capability that only exists on one surface
   (e.g. `designWebsite` = portal) can never leak into the other surface's
   derivation.

## Core model change

| Concept | Before | After |
|---|---|---|
| Capability | `PermissionFunction` row, SP-enforced | unchanged |
| UI entry gate | `enterRunAdmin` / `enterKennelAdmin` = editable capability rows; also gate the app admin-sync SPs; portal `kSectionGate` dims sections | **derived**: OR of the area's capabilities (per surface, hare-aware). No editable row. |
| Area identity | `FeatureArea` display string (renamable — has broken `kSectionGate` before) | stable `AreaKey` slug + `FeatureArea` stays as the renamable display label |
| Surface | none | `Surfaces` bitmask on each function |

### Key semantic shift (must be reconciled, not silent)
Today entry is **explicitly granted**. Derived entry = OR of capabilities. For a
role that has `enterRunAdmin` granted but **no** individual run-admin capability
(or vice-versa) the two differ. Switching to derived **changes** that role's
access. Per "break nothing silently", Phase 2 produces a diff and we reconcile
each delta with James **before** anything is removed.

### No backward-compatibility needed
HC6 user base is a small set of testers (James, 2026-07-28) — a breaking app
change is fine as long as everyone updates promptly. So there are **no
synthetics**: the compiled JSON simply stops carrying `enterRunAdmin` /
`enterKennelAdmin`, and the app, portal, compile SP and row-removal all cut over
in **one coordinated release**. Portal is web (lockstep); the app ships via
TestFlight at the same time.

### Trigger note
`HC.PermissionFunction/PermissionRole/RolePermission` are **not** mobile-synced
tables (they compile to JSON); no `UpdatedAt` trigger, so ALTERs are free.

---

## Phase 1 — Schema: AreaKey + Surfaces (additive, HC5-safe)
- `ALTER HC.PermissionFunction ADD Surfaces SMALLINT NOT NULL DEFAULT 3,
  AreaKey NVARCHAR(40) NULL;`
- Backfill `AreaKey` from current `FeatureArea` with a fixed map:
  `runAdmin` (Runs, Events, and Hash Cash), `kennelTools` (Kennel Tools),
  `photos`, `web` (Web / Newsletter), `songs`. Keep `FeatureArea` as display label.
- Index `IX_PermissionFunction_Area (AreaKey) INCLUDE (Surfaces, FunctionKey)`.
- Everything defaults to `Surfaces = 3`; nothing changes behaviourally on deploy.
- Recompile matrix. Run-once script → archive.

## Phase 2 — Derived-entry oracle + reconciliation diff (server only, nothing removed)
- New `HC.CheckAreaEntry(@userId, @kennelId, @areaKey NVARCHAR(40),
  @surface SMALLINT, @isHareOfEvent SMALLINT, @allowed SMALLINT OUTPUT)` —
  SuperAdmin bypass; else `EXISTS` a `PermissionFunction` in the area with
  `Surfaces & @surface <> 0` whose grant (mmRole/appFlag/hare bit test +
  effective grant incl. kennel override) resolves to granted. Same grant logic as
  `CheckKennelPermission`, just "any function in area" instead of one key.
- **Diff report** (throwaway query, not deployed): for every grantor × kennel,
  compare old explicit `enterRunAdmin`/`enterKennelAdmin` effective value vs
  `CheckAreaEntry` derived value. Present deltas to James; reconcile (usually:
  grant the missing capability, or accept the intended change). No removal until
  this is clean.

## Phase 3 — Sync SPs gate on derived entry (server)
- `hcapp_syncEventAdminData`: gate on `CheckAreaEntry(...,'runAdmin', 1 /*app*/,
  @isHareOfEvent)` instead of `enterRunAdmin`.
- `hcapp_syncKennelAdminData`: gate on `CheckAreaEntry(...,'kennelTools', 1, 0)`
  instead of `enterKennelAdmin`.
- `enterRunAdmin`/`enterKennelAdmin` rows still present — no gap. Deploy + verify
  a hare and a role-holder still sync; verify a no-capability role no longer does
  (matches the reconciled diff).

## Phase 4 — Compile SP: emit areas + surfaces (coordinated-release cutover)
- `nonApi_compilePermissionMatrix`:
  - add per-function `areaKey` + `surfaces` to the JSON;
  - add an `areas` array (`areaKey`, `displayName`, `sortOrder`) for grouping;
  - **stop** carrying `enterRunAdmin`/`enterKennelAdmin` (no synthetics).
- Also delete `enterRunAdmin`/`enterKennelAdmin` from `PermissionFunction` + their
  `RolePermission` grants (nothing enforces them any more after Phase 3).
- Recompile (bumps `PermissionMatrixUpdatedAt` → clients refetch at next login).
- Phases 4–6 ship together so no app build ever sees a JSON without `enter*` while
  still calling `canAccessFeature('enterRunAdmin')`.

## Phase 5 — App: `canEnterArea`, stop using `enter*` keys
- Extend `PermissionMatrix` model: parse `areas`, `areaKey`, `surfaces`.
- Add `canEnterArea(areaKey, surface, {appAccessFlags, mismanagementRoles,
  isHareOfEvent, kennelOverrideJson})` = any function `f` with
  `f.areaKey == areaKey && f.surfaces & surface != 0 && canAccessFeature(f.key,…)`.
- Replace gear/section visibility (`canAccessFeature('enterRunAdmin')` →
  `canEnterArea('runAdmin', app, isHareOfEvent: …)`), same for kennel.
- Remove `enterRunAdmin`/`enterKennelAdmin` from the `KennelFeature` floor enum.
- Ship via TestFlight alongside the server cutover.

## Phase 6 — Portal editor: derived preview, drop manual gate
- `hcportal_getPermissionMatrix`: add `areas` rowset + `surfaces`/`areaKey`
  columns. `hcportal_savePermissionMatrix`: ignore/reject `enter*` keys.
- Portal models: add `surfaces`, `areaKey`, `Area`.
- Editor: remove `enterRunAdmin`/`enterKennelAdmin` rows; **delete `kSectionGate`
  + the Opacity/IgnorePointer section-dimming**. Replace with a computed
  **"Can enter"** indicator per role — chips like
  `Enters: Run Admin (app · portal), Kennel Tools (app)` derived client-side.
- Show a small surface tag (`app` / `portal`) on functions that aren't `both`.

## Phase 7 — First portal-only capabilities: Edit / Design Website
- Add `editWebsite`, `designWebsite` functions, `Surfaces = 2` (portal), area
  `web` (or a `portalAdmin` area). Validates the bitmask end-to-end (never derived
  on the app).
- Portal gates the Edit/Design Website buttons on the caller's effective kennel
  permission — likely a new `hcportal_getMyKennelPermissions(@kennelId)` returning
  the caller's granted capability keys (server-evaluated), cached to gate buttons.
  (This is the portal analogue of the app's JSON; scoped here so it's proven on a
  real consumer.)

## Deferred / open
- Normalize areas into a `HC.PermissionArea` table (id, AreaKey, DisplayName,
  SortOrder) instead of the denormalized `AreaKey` column — defer until the column
  approach shows strain.
- The "two kennel gates" naming collision dissolves under derived entry (one
  `kennelTools` area, derived per surface) — confirm no lingering references.
