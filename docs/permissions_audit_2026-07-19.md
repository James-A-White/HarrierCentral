# Harrier Central — Permissions System Audit

**Date:** 2026-07-19
**Scope:** Mobile app UI gates (`mobile-app/lib`) + all app stored procedures (`db/hc6/app/HC6.hcapp_*`).
**Trigger:** Tester feedback — "Fix Hash Permissions so Hash Cash button on app includes all related hash cash admin functions." The hash-cash issue turned out to be one symptom of a systemic gap, so this became a full permissions audit.

---

## 0. TL;DR / severity overview

The app uses **two independent permission bitfields** that are not reconciled, and enforcement is copy-pasted per-SP with drifting masks. Findings:

| Sev | Finding | Where |
|---|---|---|
| 🔴 **P0 CRITICAL** | `hcapp_joinKennel` writes caller-supplied `MismanagementRoles` + `AppAccessFlags` to any target user with **no role gate** → anyone can grant themselves SuperAdmin | SP |
| 🔴 **P0** | `hcapp_processPayment` main money path (record/cancel a single payment) is **ungated** — only bank-confirm sub-path checks a role | SP |
| 🔴 **P0** | `hcapp_addEditEvent` — create/edit **any** kennel's events, no role gate | SP |
| 🟠 **P1** | `hcapp_sendEventMessage` — post to any event chat, no membership/role gate (sibling `sendKennelMessage` requires membership) | SP |
| 🟠 **P1** | Both purpose-built Hash Cash permissions are **dead**: `AppAccessFlags authCanManageHashCash (0x08)` and `MismanagementRoles HashCash (0x400)` are checked by **zero** SPs | SP |
| 🟠 **P1** | `0x40000081` admin mask includes `0x80` (**ManagePublicWebContent**) — a web-content editor passes every money/attendance/admin gate. Mis-documented as "superAdmin \| admin" | SP (×9) |
| 🟡 **P2** | UI shows Hash Cash buttons on `canManageHashCash` (flag 0x08) but SPs require RA role → button visible, function returns "Not authorised" | UI↔SP |
| 🟡 **P2** | Mask drift for the same concept (photos `0x2E` vs `0x102E`; hash trash `0x1022` save vs `0x102E` view; payments RA-only vs receipts `0x2E`) | SP |
| 🟡 **P2** | Ungated UI admin surfaces: Manual/Scan check-in, live-run Charges (money), coarse Run Admin entry (`appAccessFlags != 0`) | UI |
| 🟢 **P3** | Orphaned bits: `canManageSongs`, `canManagePublicWebContent`, `canManageKennel` settable but enforced nowhere; photo gate uses `isAdmin` in one place, mm-roles elsewhere | UI |

**Root cause:** there is no single source of truth for "can user X do feature Y in kennel Z." Each SP hand-rolls a mask, the UI hand-rolls a different one, and the two hash-cash permission bits that *should* be the source of truth were never wired up.

---

## 1. The two permission systems

Both live on `HC.HasherKennelMap` (per user, per kennel). Defined in `mobile-app/lib/util/constants.dart`.

**AppAccessFlags** — functional "can do X" grants (the override layer):
`0x01` IsAdmin · `0x02` ManageKennel · `0x04` ManageRuns · `0x08` ManageHashCash · `0x10` ManageMembers · `0x20` ManageAwards · `0x40` ManageSongs · `0x80` ManagePublicWebContent · `0x40000000` SuperAdmin

**MismanagementRoles** — the person's club role/title (the default layer):
`0x01` OnMm · `0x02` GM · `0x04` VGM · `0x08` RA · `0x10` BeerMeister · `0x20` HashFlash · `0x40` OnSec · `0x80` SongMeister · `0x100` TrailMaster · `0x200` HareRaiser · `0x400` HashCash · `0x800` Scribe · `0x1000` WebMeister · `0x20000` HashTrash · `0x40000` HashBank · …

⚠️ **The `0x08` collision:** `0x08` = **ManageHashCash** in AppAccessFlags but **RA** in MismanagementRoles. The payment SPs test `0x08` against the *MismanagementRoles* column (so they gate on RA), which is easy to misread as "they check hash cash." They do not.

---

## 2. P0 / P1 security gaps (server-side)

### 2.1 🔴 `hcapp_joinKennel` — privilege escalation (CRITICAL)
Takes `@targetUserId`, `@mismanagementRoles`, `@appAccessFlags` and writes them straight into `HC.HasherKennelMap` (L195-197, L204-215). The only post-`ValidateAppAuth` check is `@kennelId IS NOT NULL` (L118). **Any authenticated device can grant itself or anyone SuperAdmin / GM / RA / any role.** This is the master key — it undermines every other gate. Must be restricted to SuperAdmin (role-grants) / admin.

### 2.2 🔴 `hcapp_processPayment` — ungated money write
Only `@paymentType = 100` (confirm bank transfer) is gated (L187, RA + admin). The **main path** — `paymentType 2–8` inserts into `HC.Payment` and sets `DoTrackHashCash` (L326), and `paymentType 1` cancels a payment (L308) — runs with **no authorization** beyond device identity. Bulk payment and the report *are* gated; single payment slipped through.

### 2.3 🔴 `hcapp_addEditEvent` — ungated event write
Creates/updates any kennel's `HC.Event` (L252/L347) with only a cross-kennel PK guard (L227). Any authed user can edit any club's runs. Should require ManageRuns (role/flag) for the kennel.

### 2.4 🟠 `hcapp_sendEventMessage` — ungated chat write
Inserts `HC.EventMessage` to any event (L160) with no sender membership/role check, and can flag releasability "everyone." Contrast `sendKennelMessage` (L67) which requires an HKM row. Should at least require kennel membership.

### 2.5 Soft (low severity)
`setEventRsvp`, `setMultiRunRsvpAndCheckin`, `setEmailAndNotificationPrefs` accept a `@hasherId` defaulting to the caller but overridable with no role check when target ≠ caller (RSVP/pref writes on an arbitrary user). `joinEventAsVisitor` adds a visitor attendee to any visible event. `addKennelPhoto` has no attendance/member check.

---

## 3. P1 — dead permissions & the `0x80` mask bug

- **Dead hash-cash bits:** neither `AppAccessFlags 0x08` (ManageHashCash) nor `MismanagementRoles 0x400` (HashCash) is tested by any SP. Money auth piggybacks on **RA** (`MismanagementRoles 0x08`). So the two permissions specifically designed for hash cash grant nothing server-side.
- **`0x40000081` over-broad (×9 SPs):** intended "SuperAdmin | IsAdmin" (`0x40000001`) but literally `0x40000000 | 0x80 | 0x01` — includes **ManagePublicWebContent (0x80)**. Every gate using it (copyEventRsvps, setEventAttendence, setBulkEventAttendence, syncEventAdminData, syncKennelAdminData + the 4 money SPs) admits a web-content editor. Comments in the SPs mislabel it, so it reads as correct. Almost certainly a copy-paste typo that propagated.

---

## 4. P2 — mask drift (same concept, different masks)

| Concept | SP A | SP B | Divergence |
|---|---|---|---|
| Read payments | `getPaymentReport` = RA (0x08) | `syncEventAdminData` = 0x2E (HashFlash\|GM\|VGM\|RA) | Report needs RA; sync needs any of 4 |
| Manage payments | payments = RA (0x08) | receipts `addEditReceipt` = 0x2E | Receipts broader than payments |
| Photo write | single = 0x2E | batch/all = 0x102E (+WebMeister) | WebMeister can batch but not single |
| Hash Trash | save = 0x1022 (HashFlash\|GM\|WebMeister) | view draft = 0x102E (+VGM\|RA) | VGM/RA view but can't save |

---

## 5. UI ↔ SP mismatch & ungated UI (the tester's actual bug)

- **Hash cash buttons** (`run_admin_main.dart:246,334`) show on `appAccess.canManageHashCash` (flag 0x08), but `getPaymentReport`/`addEditReceipt` require RA / 0x2E. Grant someone ManageHashCash but not RA/admin → **buttons visible, functions rejected.** This is exactly "the Hash Cash button doesn't include all related functions."
- **Ungated UI admin surfaces:**
  - Manual check-in / Scan check-in (`run_admin_main.dart:205-244`) — no per-button gate; collect payments via `processPayment`/`processBulkPayment`.
  - Live-run **Charges** add/edit (`live_run_charges_page.dart`) — money, no client gate; only weak server check ("Are you a run attendee?"). Contrast `DownDownsPage` gated `isGm||isRa`.
  - Run Admin entry (`run_details_page.dart:61`) opens for **any** non-zero flag (even ManageSongs), exposing the ungated check-in buttons.
- **Orphaned/mismatched UI:** `canManageSongs`, `canManagePublicWebContent`, `canManageKennel` enforced nowhere in-app. Photo gate uses `isAdmin` for the badge (`run_list_item.dart:379`) but mm-roles (`isPhotoAdmin`) for prefetch/review — different criteria for one feature.

---

## 6. Proposed model (per James: gate on BOTH)

**Rule for every feature:** allow if
`SuperAdmin OR IsAdmin(for kennel-scoped admin things) OR (user has ANY of the feature's default roles) OR (user has the feature's AppAccessFlag)`.
Roles = the default (a GM just works); the flag = the override so any single feature can be handed to any hasher.

**Proposed feature → {default roles, override flag} matrix** (for your review — roles are suggestions):

| Feature | Default MismanagementRoles | Override AppAccessFlag |
|---|---|---|
| Hash Cash (payments, receipts, report, live charges) | HashCash(0x400), RA(0x08) | ManageHashCash(0x08) |
| Run management (edit run, QR, attendance/RSVP-admin, event create/edit) | GM, VGM, RA | ManageRuns(0x04) |
| Members (roster admin) | GM, VGM | ManageMembers(0x10) |
| Awards / Drinks list | GM, RA, BeerMeister | ManageAwards(0x20) |
| Down Downs | GM, RA, BeerMeister | ManageAwards or ManageHashCash — **decide** |
| Photos / Hash Flash | HashFlash, GM, VGM, RA | (add a Photos flag, or reuse ManageRuns) — **decide** |
| Web content / Hash Trash | WebMeister, HashFlash, GM, Scribe | ManagePublicWebContent(0x80) |
| Kennel management | GM | ManageKennel(0x02) + IsAdmin |
| Songs (if edit added) | SongMeister | ManageSongs(0x40) |
| **Grant roles/flags** (`joinKennel` role writes, role editors) | — | **SuperAdmin only** |

Open decisions flagged **decide** above (Down Downs flag, Photos flag). Also decide whether RA should retain hash-cash by default (it does today).

---

## 7. Systemic fix (recommended)

The drift/typos come from hand-rolling masks per SP. Replace with **one shared authorizer**, used everywhere:

- **SP side:** `HC6.CheckKennelPermission(@userId, @kennelId, @requiredMmRolesMask, @requiredAppFlagsMask, @allow OUTPUT)` — one place that also folds in SuperAdmin/IsAdmin. Every hcapp_ SP calls it with the feature's masks (from a documented constants block) instead of an inline `IF (… & 0x…)`. Kills the `0x80` bug and the drift in one move.
- **Dart side:** a `KennelPermission.can(feature)` helper driving the UI off the **same** feature→mask table, so UI and SP can never disagree again. Fixes the "button shows but SP rejects" class.
- Fix `0x40000081` → `0x40000001` everywhere (drop the stray `0x80`).
- Wire the two dead hash-cash bits into the hash-cash feature masks.

---

## 8. Prioritized fix plan

1. **P0 now (security, SP + deploy):** gate `joinKennel` (SuperAdmin for role/flag grants), `processPayment` main path, `addEditEvent`; membership-gate `sendEventMessage`. Fix `0x40000081`→`0x40000001`.
2. **P1:** introduce `CheckKennelPermission` + feature→mask table; migrate the hash-cash + event-admin SPs onto it; wire in `ManageHashCash`/`HashCash` bits. Mirror in a Dart helper.
3. **P2:** align UI gates to the same table (hash-cash buttons, check-in, live charges, photo gate); add per-button/route gates and defense-in-depth on downstream pages.
4. **P3:** decide/retire orphaned bits; document the final model.

Each SP change is a production deploy on the single live DB — sequence carefully and test per feature.

---

*Generated from a UI gate sweep + a full `hcapp_*` SP auth-gate sweep, 2026-07-19. Full per-SP and per-UI-site inventories available in the audit session.*
