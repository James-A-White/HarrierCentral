# Harrier Central Portal — Changelog

---

## 2.0.43+678 — 2026-07-06

### Improvements
- **Default run day/time cleanup**: the kennel's default run day-of-week now lives in its own database column (`DefaultRunDayOfWeek`) instead of being encoded in the fractional seconds of the default start time. The kennel Other tab and the new-run default date derivation use the real field.

---

## 2.0.42+677 — 2026-06-29

### Improvements
- **Unified button system**: new `HcButton` widget + token-based styles give
  every button consistent size, shape, typography and disabled/loading states
  across all roles (primary / secondary / navigation / destructive / outlined /
  text). Dialog, ad-hoc, wizard-navigation and tab-group buttons migrated onto it.
- Next/Back navigation buttons unified to a single blue.
- Tab-group Save/Undo adopt the system: Save = red primary, Undo = blueGrey
  secondary (matching the dialog OK/Cancel pairing).

### Fixes
- Dialog OK/Cancel buttons (`showAlert`, incl. the Notifications dialog) were
  invisible after the button-theme change — white text on a flat dialog. Now
  filled red/blueGrey and clearly visible.

---

## 2.0.41+676 — 2026-06-28

### Fixes
- Location lookup & Set Location dialogs now build a brand-new controller on
  every open (unique GetX tag), guaranteeing the search box / selection reflect
  current data instead of stale values from a previous open.

---

## 2.0.41+675 — 2026-06-28

### Fixes
- Set Location dialog: Cancel and Save buttons are now physically identical
  (shape, height, corner radius, typography), differing only by colour, via a
  shared `hcDialogButtonStyle`.
- Set Location dialog no longer shows stale data when reopened after changing
  the city (the controller is now recreated fresh each open, so the Lookup
  dialog seeds from current data).

---

## 2.0.41+674 — 2026-06-28

### New Features
- Run editor — full Country → Region → City location selector driving timezone
  & gazetteer: inline dropdowns on the Location tab ("Other" free-text + manual
  timezone picker), a "Set" dialog + summary line on Basic Info, and a read-only
  panel showing the IANA zone, abbreviation (e.g. EST/EDT) and standard/daylight
  UTC offsets.
- Address "Find Location" now biases to the run's overridden location (geocoded
  centre + the override country's neighbour codes), falling back to the kennel;
  reverse-geocode best-effort matches results into the dropdowns.

### Improvements
- Set Location dialog buttons match the standard portal style.

---

## 2.0.40+673 — 2026-06-28

### New Features
- **Run editor — cascading location selector**: the Country dropdown now works
  (it was permanently empty — the country list was never fetched) and is joined
  by dependent **Region** and **City** dropdowns. Selecting a country loads its
  regions; selecting a region loads its cities. Selections are stored per run
  (new nullable `RegionId`/`CityId` on `HC.Event`).

### Improvements
- **Kennel Members — notification options**: the Notifications column now offers
  the full set of kennel-level preferences — **On**, **Off**, **Silver Bell**
  (silent / in-app only) and **6 hrs before** (push only within the 6-hour
  window before a run) — instead of just Auto/On/Off.
- **Vertical tab rails**: darkened to a uniform luminance and the labels are now
  bolder/larger so the white text reads clearly on every editor colour.
- **Kennel Members**: removed the redundant inline description text (it remains
  available behind the (i) info button).

---

## 2.0.39+672 — 2026-06-28

- Editor bottom bar: the Back/Next buttons now reserve their space when hidden (first/last page), so the Undo/Save buttons no longer shift between steps.

---

## 2.0.38+671 — 2026-06-28

- **Two-flow login TTL.** The QR-scan login keeps its full **5-minute** window (so users have time to find their phone and scan), while the same-device app-login uses the tighter **90-second** window from the previous release. The portal tells the server which flow it's in; the TTL is decided server-side.

---

## 2.0.37+670 — 2026-06-28

- **Same-device login hardening.** The one-time login code now arrives in the URL **fragment** (`#authCode=`) instead of the query string, so it's never sent to or logged by any server; it's **stripped from the URL** immediately on read (no history/back-button residue). Added `Referrer-Policy: no-referrer` so the URL can't leak via the `Referer` header. (Backward-compatible: still accepts the legacy `?authCode=` from older app builds.) The DB-side login-code TTL was also tightened from 5 minutes to 90 seconds.

---

## 2.0.36+669 — 2026-06-28

- **Fixed the ~10-second Kennel Members load.** The loader waited up to 100×100ms (10s) for the desktop data grid's state manager to appear — but on the phone the grid isn't rendered (card list instead), so that wait always ran the full 10 seconds before giving up. Removed the poll; members now appear as soon as the data returns (~instant for small kennels).

---

## 2.0.35+668 — 2026-06-28

- Kennel Members loads faster: the full member list is fetched once and cached, so switching between views (Membership, Run counts, etc.) no longer re-queries the server each time (it re-filters locally and refetches only after edits). Paired with backend query + index optimizations to the underlying member lookup.

---

## 2.0.34+667 — 2026-06-28

- Kennel Members: an info (ⓘ) button on the view heading opens that view's description; on phones the long description moves into this dialog to free up space.
- Added member search (by real name or hash name) on all screens — filters both the desktop grid and the phone cards.
- Added loading spinners while member data loads (no longer briefly shows "no members" during a load).

---

## 2.0.33+666 — 2026-06-28

- **Kennel Members page now uses the standard tabbed-UI navigation** like the editors: a vertical tab rail on desktop and a hamburger menu on phones (the 7 views are now tabs). Desktop shows the data grid; phones show the member card list. Replaces the old custom button menu.

---

## 2.0.32+665 — 2026-06-27

- **Kennel Members on phones now shows a card list** instead of a sideways-scrolling grid: each member is a card with the current view's fields (Membership, Names & Email, Notifications, Run counts, Payment, Photos), edited inline and saved per field. Desktop keeps the data grid; the bulk "Add new Hashers" view keeps the grid on phones too.

---

## 2.0.31+664 — 2026-06-27

- **Kennel Members page usable on phones (first pass):** the tall stack of view buttons is replaced by a compact menu (a popup picker on phones matching the rest of the portal; pill tabs on wide screens), with reduced padding and heading size so the member grid has room.

---

## 2.0.30+663 — 2026-06-27

- **Trail Symbols editor fits phones.** Each slot's Name and Action fields were squished into unusable slivers on a narrow screen; on phones the slot now stacks (number + icon + purpose on top, full-width Name and Action below). Wide layout unchanged.

---

## 2.0.29+662 — 2026-06-27

- **Fixed: Menu button missing on first open (phone).** The app-bar actions weren't reacting to the narrow-screen flag flipping after load, so the Menu button didn't appear until something else refreshed the bar. It now shows immediately.

---

## 2.0.28+661 — 2026-06-27

- **Fixed: phone runs page blank when there are no upcoming runs.** It auto-switched to Past runs but rendered nothing until a pull-to-refresh — caused by the layout flag being set after the data load instead of before. Past runs now show immediately.
- **Location Lookup: street address per result.** Search Places rows now show the full street address (not just city/region), so near-identical results (e.g. several "Starbucks" in one city) are distinguishable.

---

## 2.0.27+660 — 2026-06-27

- **Location Lookup fits phones now**: on narrow screens the lookup shows a full-width results list (the side map and fixed-width panel that pushed the Search button off-screen are dropped), with smaller text and tighter rows.

---

## 2.0.26+659 — 2026-06-27

- **Fixed: location Lookup did nothing on phones.** The lookup needs the full run list to suggest previous locations, but the phone only loads a recent detail window, so the list was empty and the button silently bailed. It now loads that list on demand when you open the lookup.

---

## 2.0.25+658 — 2026-06-27

- **Much faster phone load**: the phone now loads all upcoming runs plus the last ~4 months of past runs, instead of a full year. Older past runs lazy-load (4 months at a time) as you scroll down the Past list. (Future and past are fetched separately so all upcoming runs always show, regardless of how far out they are.)

---

## 2.0.24+657 — 2026-06-27

- **Faster phone runs load + lazy-loaded history**: the phone was fetching ~19 years of past runs at once (slow). It now loads the most recent year and lazy-loads another year of older runs each time you scroll near the bottom of the Past list, with a small spinner while more load. Past runs are now ordered most-recent first.

---

## 2.0.23+656 — 2026-06-27

- **Fixed: Past runs empty on phones.** The phone layout only fetched upcoming runs, so switching to "Past runs" (and the no-future-runs fallback) had nothing to show. It now fetches the full past+future set like the desktop layout and filters locally, so past runs appear instantly when you toggle.

---

## 2.0.22+655 — 2026-06-27

- **Fixed: Future / Past toggle on phones wasn't tappable.** It lived inside a floating sliver header that swallowed taps; it's now a fixed header above the runs list (always visible, reliably clickable).

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
