# HC — Authorizations & Permission Gating

> **Load this skill whenever you add or change a permission gate — in a stored
> procedure OR in the app UI — or add any SP that reads/writes kennel-scoped or
> money data.** Authorization here is silent when wrong: a missing gate is an
> open door (a real privilege-escalation hole shipped this way — see below), and
> a mismatched gate makes a button appear that the server then rejects. The
> server SP is the ONLY real gate; the UI gate is just UX. Never rely on the UI.

Full audit: `docs/permissions_audit_2026-07-19.md`.
Living role×function matrix (source of truth for who-gets-what): `docs/permissions_matrix.xlsx`
(regenerate the blank template with `tools/make_permissions_matrix.py`).

---

## Two permission bitfields (both on `HC.HasherKennelMap`, per user × kennel)

Defined in `mobile-app/lib/util/constants.dart`.

**AppAccessFlags** — functional "can do X" grants. This is the **override layer**:
it lets you hand any single feature to any hasher regardless of their club role.

| bit | name |
|---|---|
| `0x01` | IsAdmin |
| `0x02` | ManageKennel |
| `0x04` | ManageRuns |
| `0x08` | **ManageHashCash** |
| `0x10` | ManageMembers |
| `0x20` | ManageAwards |
| `0x40` | ManageSongs |
| `0x80` | ManagePublicWebContent |
| `0x100` | ManagePhotos *(added 2026-07-19)* |
| `0x40000000` | SuperAdmin |

`authAllFlags` (the "all assignable functional flags" mask, everything except
SuperAdmin) must be widened when a bit is added — it is now `0x000001ff`. The admin
editor masks saved flags with it, so a new bit outside it would be silently dropped.

**MismanagementRoles** — the person's club role/title. This is the **default layer**:
holding a role grants that role's features automatically.

`0x01` OnMm · `0x02` GM · `0x04` VGM · `0x08` **RA** · `0x10` BeerMeister · `0x20` HashFlash ·
`0x40` OnSec · `0x80` SongMeister · `0x100` TrailMaster · `0x200` HareRaiser · `0x400` **HashCash** ·
`0x800` Scribe · `0x1000` WebMeister · `0x2000` HashHugs · `0x4000` HashHo · `0x8000` Haberdasher ·
`0x10000` HashSweep · `0x20000` HashTrash · `0x40000` HashBank · `0x80000` EventMeister ·
`0x100000` Communications · `0x200000` Other.

### ⚠️ The `0x08` collision — read this every time
`0x08` = **ManageHashCash** in AppAccessFlags but **RA** in MismanagementRoles. When you
see `& 0x08` in an SP, check WHICH column it's applied to (`hkm.AppAccessFlags` vs
`hkm.MismanagementRoles`). The money SPs test `0x08` against **MismanagementRoles**, so
they gate on **RA**, not hash cash. Misreading this is how the dedicated hash-cash bit
ended up dead.

---

## The model: gate on BOTH (James, 2026-07-19)

A feature is allowed when **ANY** of:

```
SuperAdmin (0x40000000)                                            -- the ONLY all-features bypass
  OR (MismanagementRoles & <feature's default-role mask>) != 0     -- role default
  OR (AppAccessFlags     & <feature's override flag>)     != 0     -- per-hasher override
```

Roles = defaults (a GM just works); flags = the override so any single feature can be
granted to any hasher. The role→feature defaults are decided in the matrix
(`docs/permissions_matrix.xlsx`) — keep it current as decisions land.

⚠️ **`IsAdmin` (0x01) is NOT folded into the gate.** It is an *auto-derived umbrella* — the
editor sets it on anyone holding any one functional flag — used only to show admin UI. If
you fold it in ("admin passes everything"), a single narrow grant (e.g. Manage Songs)
silently unlocks every feature. Only **SuperAdmin** is the everything-bypass; every other
feature needs its own role or flag. The helper fold-in is `0x40000000`, never `0x40000001`.
Assigning flags/roles (`joinKennel`) is therefore **SuperAdmin-only** (flags) / **GM|VGM +
SuperAdmin** (roles).

---

## Where gates live

- **Server (authoritative):** every `HC6.hcapp_*` SP. `EXEC HC6.ValidateAppAuth` proves
  device/token **identity only — it is NOT authorization.** Any SP that reads or writes
  kennel-scoped, money, membership, or role data MUST have an explicit role/flag check
  after ValidateAppAuth, or it is wide open.
- **App UI (UX only):** `AppAccess` getters (`appAccess.canManageHashCash`,
  `.canManageRuns`, `.isAdmin`, `.getAppAccess(flag)`) and mismanagement checks
  (`getMismanagementState(mmRoleFlag*)`, `isGm`/`isRa`/…). These decide whether a button
  shows. They must mirror the SP gate for the same feature, or the button appears and the
  SP rejects it (the tester's "Hash Cash button doesn't work" bug).

---

## Known traps & live bugs (as of the 2026-07-19 audit — verify before trusting)

1. **`ValidateAppAuth` is not a gate.** Several write SPs shipped with identity-only
   checks. Confirmed ungated writes: `joinKennel` (writes caller-supplied roles/flags to
   any user → **privilege escalation**), `processPayment` main path (record/cancel a
   single payment), `addEditEvent` (edit any kennel's runs), `sendEventMessage` (post to
   any event chat). Do not copy these as templates.
2. **`0x40000081` is wrong.** Used as the "admin" AppAccessFlags mask in ~9 SPs; it is
   `SuperAdmin | IsAdmin | ManagePublicWebContent(0x80)` — the `0x80` is a stray bit, so a
   web-content editor passes money/admin gates. Intended value is `0x40000001`. Fix on
   sight; don't propagate.
3. **The two hash-cash permissions are dead:** `AppAccessFlags ManageHashCash (0x08)` and
   `MismanagementRoles HashCash (0x400)` are checked by zero SPs today. Money auth
   piggybacks on RA. Wire these into the hash-cash feature mask.
4. **Mask drift:** the same concept uses different masks across SPs (payments RA-only vs
   receipts/sync `0x2E`; single-photo `0x2E` vs batch `0x102E`; hashtrash save `0x1022`
   vs view `0x102E`). Don't invent a new mask per SP.

---

## The fix pattern (target state — prefer this for new/edited SPs)

Stop hand-rolling masks. The intended systemic fix is ONE authorizer used everywhere:

- **SP:** `HC6.CheckKennelPermission(@userId, @kennelId, @requiredMmMask, @requiredFlagMask, @allowed OUTPUT)`
  — one place that also folds in SuperAdmin/IsAdmin. Every SP passes the feature's masks
  from a single documented constants block instead of an inline `IF (… & 0x…)`.
- **App:** a mirrored `KennelPermission.can(feature)` helper driven by the **same**
  feature→mask table, so UI and server cannot diverge.

Until that helper exists, when you touch a gate: apply the model above, use the correct
column for each mask, avoid `0x40000081` (use `0x40000001`), and match the feature's
existing mask rather than inventing one.

---

## Rules

1. **Never add an SP that writes/reads sensitive kennel data without an authorization
   check** beyond `ValidateAppAuth`. If unsure whether a feature needs gating, it does —
   flag it.
2. **UI and SP gates for the same feature must use equivalent logic.** Changing one
   without the other is a bug.
3. **Server changes are production deploys on the single live DB.** Sequence and test per
   feature; never deploy permission changes autonomously (see deploy rules).
4. **Keep `docs/permissions_matrix.xlsx` current** — it is the source of truth for the
   role→feature defaults. Update it whenever an assignment decision is made, and reflect
   the same change in the SP masks + the app gate.

Related: [[hc-access-tokens]] (identity/token layer, distinct from authorization),
`docs/permissions_audit_2026-07-19.md`, memory `project_permissions_audit`.
