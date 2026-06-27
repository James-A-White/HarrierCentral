# Harrier Central Portal — Changelog

---

## 2.0.21+654 — 2026-06-27

- **Phone runs view no longer blank for kennels with no upcoming runs**: the "fall back to past runs" behaviour now applies to the phone/narrow layout too (it was previously wide-screen only), so you see the most recent runs instead of an empty screen.
- **Future / Past toggle on phones**: added the Future runs / Past runs switch to the narrow layout (it only existed on the wide desktop layout before), so you can browse past runs on mobile.

---

## 2.0.20+653 — 2026-06-27

- **Editor bottom bar fits on phones**: the Back / Undo / Save / Next bar in the run (and other) editors was overflowing on narrow screens, pushing the **Next** button off the right edge. The buttons now use compact padding on phones and the empty placeholder no longer reserves wasted space, so the whole bar fits.

---

## 2.0.19+652 — 2026-06-27

- **Edit Run on phones**: the phone/narrow run view (a separate widget from the desktop layout) had no edit button at all — now it shows a prominent **Edit Run** button right under the run title. This is the layout that was actually being used on mobile; the earlier edit affordances (2.0.17/2.0.18) only appeared on the wide desktop layout.

---

## 2.0.18+651 — 2026-06-27

- The run detail view now has a prominent **Edit Run** button right at the top (previously the only way in was a button buried at the far end of the bottom action bar, which on a phone was pushed off-screen). The remaining actions in the bottom bar now wrap onto a second line on narrow screens instead of overflowing.

---

## 2.0.17+650 — 2026-06-27

- Editing a run is now obvious: every run card has a visible **Edit** button (shown to users who can manage runs) that opens the editor directly — no need to tap into the detail panel and hunt for the button. Run cards also now show a pointer cursor so they clearly read as clickable.

---

## 2.0.16+649 — 2026-06-27

- Restored the app version number (dropped when the promo banner was removed): now a small, always-visible label in the top-right of the runs page app bar, on both wide and narrow layouts.

---

## 2.0.15+648 — 2026-06-27

- Removed the purple "Powered by Harrier Central" banner from the runs page (reclaims vertical space; the search bar stays).
- The narrow-screen actions menu is now a clear blue "Menu" button instead of a bare three-dot icon.

---

## 2.0.14+647 — 2026-06-27

- Runs page now uses a persistent left navigation rail on wide screens (kennel context + admin actions as nav items), freeing the top bar. Narrow screens keep the overflow menu.

---

## 2.0.13+646 — 2026-06-27

- Runs list top bar no longer clips on small screens: the action buttons collapse into a single overflow (⋮) menu on narrow widths, the "Runs & Events" label is dropped, and the kennel badge truncates.

---

## 2.0.12+645 — 2026-06-27

- Same-device login: the portal now accepts an `?authCode=` in the URL (used by the mobile app's "Admin Portal" button) and logs in without a QR scan.

---

## 2.0.11+644 — 2026-06-27

- Rolled the vertical tab rail out to the remaining editors (Run Edit, Kennel Website, Application Form, Email) via a shared `TabRailScaffold`. Each editor's rail has its own distinct colour — same saturation/luminance as the kennel blue, hue-rotated (green / teal / violet / crimson). Narrow screens keep each editor's existing tab bar.

---

## 2.0.10+643 — 2026-06-27

- Kennel Editor navigation now follows the new grouped tab order: reordered the underlying tabs to match the rail, so Back/Next walk the visible sequence, the slide animation goes the right way, and the rail highlight no longer jumps. Back is hidden on the first tab and Next on the last.

---

## 2.0.9+642 — 2026-06-27

- Kennel Editor tab rail: grouped tabs with hairline dividers (general / run content / developer / super admin), active tab now matches the off-white content background, and "Platform Admin" renamed to "Super Admin" (shown only to platform admins).

---

## 2.0.8+641 — 2026-06-27

- Change: the Kennel Editor now uses a vertical tab rail down the left on wide screens (the horizontal tab bar was clipping as tabs grew). Selection, validation icons, and the per-tab info sidebar are unchanged; narrow/mobile keep the hamburger menu.

---

## 2.0.7+640 — 2026-06-27

- New: **Trail Types** kennel editor — rename or hide the five built-in lanes (Walkers / Short / Normal / Long / Ballbreaker) or add your own custom ones with an emoji. Drives PackTrack trail selection and run-map filtering. "Normal" can be renamed but never hidden.

---

## 2.0.6+639 — 2026-06-18

### Fixes

- **Set address from lat/lon**: Fixed — was silently failing due to a stale upstream URL in the reverse geocode proxy. Now calls Azure Maps directly.

---

## 2.0.5+638 — 2026-06-03

### Fixes

- **HC Admin Tools button race condition**: Fixed a bug where the HC Admin
  Tools button would not appear on first login (or after clearing browser
  storage). The platform admin privilege fetch (`hcportal_getHcAdminPrivileges`)
  is a network call that raced with navigation to the run list page — on slow
  connections the page built before the Hive flags were written, so
  `hasAnyPlatformAdminPrivilege` always read `false`. Navigation now waits for
  both the kennel list and the privilege fetch to complete before proceeding.

---

## 2.0.4+637 — 2026-06-01

### Fixes

- **Trail symbol slots — Name and Action always editable**: Name and Action
  fields are now editable for all 12 slots regardless of whether a symbol
  image is selected, allowing kennels to name slots before choosing an image.

- **Trail symbol icon library expanded**: New symbols I-050 through I-054
  added to the picker; existing symbols I-001 through I-004 re-optimised for
  smaller file size. I-000 (new blank/custom marker) added.

- **Run location lookup dialog updated**: Minor improvements to the location
  lookup dialog layout.

---

## 2.0.3+636 — 2026-06-01

### Features

- **Trail Symbols tab in Edit Kennel**: Admins can now configure the 12 trail
  marking symbol slots shown in the mobile app during live run tracking. Each
  slot has a visual image picker (tap to open a 4×3 grid of available symbol
  PNGs), a free-text name field (the kennel's own terminology), and an action
  selector (None / Add Text / End Run). Empty slots are excluded from the mobile
  app grid. Changes are saved automatically as part of the standard kennel save
  flow and take effect on the next user sync.

### Internal

- `hcportal_editKennel`: new `@trailSymbolsConfigJson NVARCHAR(4000)` parameter
- `hcportal_getKennel`: `TrailSymbolsConfigJson` added to kennel rowset so saved
  config is visible on page reload

---

## 2.0.0+633 — 2026-05-31

### Milestone: Agentic AI Development

Version 2.0 marks the completion of the Harrier Central Admin Portal's migration
to agentic AI-assisted development. Every feature, security fix, and refactor in
this release was designed, reviewed, and implemented through a structured
human-AI collaboration — with James proposing direction and Claude (Anthropic)
executing and explaining. The portal is now fully on this development model
alongside the public web and API, with the mobile app to follow.

### Security Hardening (Phases 1–5)

A comprehensive security audit and remediation across the full stack:

- **Phase 1 — Credentials out of source:** Deleted `data.dart` (contained live
  API keys, kennel UUIDs, and bank details compiled into the JS bundle). Removed
  FCM tokens and auth tokens from all log output. Replaced unguarded `debugPrint`
  calls with `kDebugMode`-gated logging across 14 portal files.

- **Phase 2 — Server-side SAS tokens:** Replaced three hardcoded year-2100 Azure
  Blob SAS tokens (container-level write, compiled into JS) with a new server-side
  endpoint (`GetPortalUploadSas`) that issues per-blob, 15-minute write-only SAS
  tokens on demand, validated against portal auth.

- **Phase 3 — Error detail sanitisation:** Stopped propagating raw database error
  messages to HTTP clients. Internal detail now stays in Azure logs only.

- **Phase 4 — Session and URL hardening:** `HC_ADMIN_SESSION_SECRET` now throws at
  startup if missing (removes silent fallback). HMAC comparison uses
  `timingSafeEqual` (prevents timing side-channel). `_launchUrl` restricted to
  `http`/`https` schemes (blocks `javascript:`, `data:`, `file:` injection).
  Photo upload validates SAS URL host before sending bytes.

- **Phase 5 — SQL injection fixes and permission guards:** Converted string-
  interpolated `EXEC` calls in `GenericJsonQuery.cs` to parameterised commands.
  Added `AppAccessFlags` permission check to `hcportal_updateKennelHasher`.
  Transaction guard added to `hcportal_deleteEvent`. Atomic OTP redemption in
  `publicWeb_redeemAdminToken`. IDOR fixes in `hcportal_addEditEvent` and
  `hcportal_deleteEvent`.

- **Proxy geocode endpoints:** Geocode lookups now route through the HC API shim
  (`ProxyGeocode`, `ProxyReverseGeocode`) so the TomTom API key is never exposed
  in client-side JavaScript.

- **DB auth bypass removed:** `HC6.CHECK_PORTAL_ACCESS_TOKEN` development bypass
  (which had allowed unauthenticated access during HC6 migration) was removed and
  full token validation enforced.

### Auth Fix — Compound Token Paramstring

The removal of the auth bypass exposed a pre-existing mismatch: 19 portal SP
callers were generating tokens with only `deviceSecret` as the paramstring, while
the SPs pass a context value (kennel ID, event ID, etc.) to `ValidatePortalAuth`,
which builds `UPPER(deviceSecret) + callerParamString` for validation. Every
kennel-scoped and event-scoped operation was broken.

Fixed across three layers:

- **`HC6.ValidatePortalAuth`:** Compound paramstring now uses an explicit colon
  delimiter — `UPPER(deviceSecret):UPPER(callerParamString)` — making the boundary
  unambiguous and consistent across all callers.
- **All 19 Dart callers** updated to `paramString: '$deviceSecret:$callerParam'`.
- **`hcportal_sendEventMessage`** extended to bind the token to both the event ID
  *and* the message UUID (`publicEventId:messageId`), preventing a captured token
  from being replayed to send a different message.

The device secret is never transmitted — it is used only as a signing ingredient
in the SHA-256 hash and remains on the client at all times.

### Code Quality — `ApiResult` Sealed Class

Replaced the `ERROR_xxx` string-prefix pattern throughout the portal with a
typed `ApiResult` sealed class (`ApiSuccess` / `ApiError`). This eliminates the
class of bug where `json.decode` could be called on an error string — under the
old pattern it required a manual `startsWith(ERROR_PREFIX)` guard that was easy
to forget; under the new pattern the compiler rejects it outright. All 35 call
sites across 16 files updated.

### Other Fixes

- **Photo review auth:** `getRunAllPhotos` and `batchUpdatePhotoStatus` now receive
  `publicKennelId` for correct kennel-scoped auth validation.
- **`authCanManagePublicWebContent` (0x0080):** New permission flag wired through
  portal UI and SP layer, controlling access to the public web content editor.
- **Error dialog message:** Portal now reads `errorUserMessage ?? errorMessage`
  from API error responses, restoring meaningful error messages that had been
  silenced by the security hardening field-name change.

---

## 1.5.x (2026-03 to 2026-05)

Incremental releases covering: HC6 SP migration completion, Flutter portal on
HC6 API throughout, public web Puck page builder (6 top-level pages), admin auth
OTP token flow (Flutter portal → URL token → HMAC session cookie), photo review
page, FCM chat infrastructure, newsflash feature, HC Admin Tools hub, button
colour system, and ongoing SP/contract work.

---

*Harrier Central is maintained by James White. Agentic AI development powered
by Claude (Anthropic).*
