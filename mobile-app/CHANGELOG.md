# Harrier Central Mobile App — Changelog

## 2.6.2+1134 (2026-05-24)

### Features

- **Chat — unread tracking**: Opening event chat now marks all messages as read
  server-side and fans out a silent `read_sync` FCM push to the user's other
  devices, zeroing badge counts immediately.

### Improvements

- **Chat — 2.x UI framework**: Migrated from `flutter_chat_ui` 1.x to 2.x
  (`flutter_chat_ui ^2.11.1` + `flutter_chat_core ^2.9.0`). Chat messages are
  now managed via `InMemoryChatController`; group avatars and sender names are
  rendered using the 2.x custom builder API matching the portal's chat UI.

- **Chat — FCM subscription moved to controller**: Incoming FCM chat messages
  are now handled directly by `ChatPageController` via its own subscription
  rather than being routed through `NotificationService`.

- **Chat — UUID normalisation**: Author and message IDs are now normalised to
  lowercase via `.asUuid` (was `.toUpperCase()`), consistent with project
  conventions.

- **Chat — named constant for releasability flags**: `messageReleasabilityFlags`
  value replaced with `kChatReleasabilityAll` constant.

- **Chat strip — decoupled from chat package**: `ChatStripWidget` no longer
  depends on `flutter_chat_types`; uses a lightweight internal model for the
  summary display.

- **Dead code removed**: `LiveRunChatController` stub class removed (was an
  empty wrapper around `LiveRunChatPage`). `visibility_detector` dependency
  removed.

## 2.6.1+1133 (2026-05-24)

### Bug fixes

- **Chat — message load crash**: `ChatPageController.onInit` no longer
  force-unwraps `publicHasherId` and `profilePhotoUrl`. If `publicHasherId`
  is absent the chat screen exits cleanly instead of crashing.

- **Chat — permanent loading spinner on server error**: An `HC_ERROR_` response
  no longer reaches `jsonDecode`, which would throw and leave `messagesLoading`
  stuck at true permanently.

- **Chat strip — permanent loading spinner on exception**: `ChatStripController`
  now wraps the load path in try/catch/finally, ensuring `isLoading` clears
  on any error path.

- **Chat — message status stuck at sending**: Sent messages now correctly
  update to `sent` (or `error` on failure) after the API call completes.

- **Chat — soft-deleted messages excluded**: Messages and authors marked as
  removed are now filtered from event chat results (HC6 SP).

- **Chat — send atomicity**: The message INSERT and badge-count MERGE are now
  wrapped in an explicit transaction; a partial-write state on badge failure is
  no longer possible (HC6 SP).

- **Chat — data-only push notifications now silent on iOS**: In-app chat
  messages no longer play a notification sound. APNS priority was incorrectly
  set to 10 for all FCM messages; data-only messages now use priority 5 with
  content-available (HC6 API).

- **Chat — releasability flags value in push**: `MessageReleasabilityFlags` was
  silently deserialising to 0 in the HC6 send path due to an HC5/HC6 column
  name mismatch; push notifications now carry the correct value (HC6 API).

- **Chat — SP errors now surfaced to caller**: HC6 error envelopes are detected
  before notification side-effects run; previously swallowed silently (HC6 API).

- **Chat — stale FCM token cleanup**: Removing a stale token no longer calls an
  HC5 internal SP; replaced with a direct UPDATE HC.Device (HC6 API).

## 2.6.0+1132 (2026-05-24)

### New features

- **QR codes — kennel website tab**: The QR code sheet now includes a dedicated
  "Website" tab when the kennel has a website URL configured. Scan to open the
  kennel's hashruns.org page directly. Available from both the run admin QR
  sheet and the kennel admin QR sheet.

### Improvements

- **Live run page — "Share Runs" button promoted**: The QR code button is now
  permanently visible in the right-hand column alongside "Take Photo", replacing
  the previous smaller outlined button below the marker grid. Makes the action
  easier to reach mid-run.

- **Live run page — consistent corner radii**: All interactive elements on the
  live run general tab (buttons, stat cards, photo button, chat strip) now share
  a uniform 12px corner radius.

- **Live run page — chat strip alignment**: The chat strip card now aligns its
  left and right edges with the rest of the page content, matching the Auto Pause
  and End Run buttons above it.

- **My Profile — "Camera Behavior" section**: The camera roll setting is now
  presented under a clear "Camera Behavior" heading with a descriptive subtitle,
  and the Switch has been restyled to match the page's existing layout pattern
  rather than using a highlighted SwitchListTile.

- **Error logging — BootLogger rollout**: `BootLogger.logError` now covers 25+
  previously silent catch blocks across services, database queries, admin pages,
  and the live run flow. Errors from these paths will appear in the diagnostic
  harvest log. Includes Apple sign-in exceptions, kennel photo upload failures,
  common query errors, and notification dispatch failures.

- **Boot logger — session start marker**: Each new session writes a `[STARTUP]`
  timestamp into the error log at the moment persistence begins, making it easy
  to identify session boundaries in harvested logs.

- **Boot logger — await previous session flush**: The previous session's error
  log is now awaited before starting the new session, ensuring clean hand-off
  between session logs.

- **Boot logger — global export**: `boot_logger.dart` is now re-exported from
  `imports.dart`, removing the need for individual imports across files.

## 2.5.4+1131 (2026-05-24)

### Bug fixes

- **Hash Flash — review flow rework**: Tapping an action button now records
  the decision and highlights the button without navigating away from the
  current photo. Swipe left/right (or the auto-advance after a tap) is now
  the only mechanism that moves between photos. This fixes two bugs: an
  instant photo-jump followed by a slide animation on the pending tab, and
  no-advance on the reviewed tab. Both were caused by the optimistic status
  update mutating the `allPhotos` list mid-flight, which rebuilt the
  `PageView` before `nextPage()` fired.

- **Hash Flash — save on exit only**: Removed the 5-second debounce
  auto-save. All decisions are now written as a single batch when the user
  leaves the page. Eliminates mid-session saves that were disrupting the
  `PageView` with a full reload at unpredictable moments.

- **Hash Flash — reviewed tab re-tag highlighting**: Tapping a different
  action on an already-reviewed photo now immediately highlights the new
  button. Previously the panel derived `selected` from the committed status
  only; it now checks the queued decision first.

- **UUID case fix — boot log flag**: The developer-only boot log flag in
  the drawer menu now compares against a lowercase UUID, consistent with the
  project-wide UUID normalisation convention. Fixes the flag never activating
  after `UuidValue` normalisation was rolled out.

### Improvements

- **Geocoding — "Pin location needed" dialog**: When auto-locate cannot
  find a specific enough location for an address, a dialog now appears
  explaining why and offering a direct "Go to Map" button to jump to the
  Map tab for manual pinning. Previously the flow failed silently.

- **Run admin button spacing**: Added horizontal spacing between action
  buttons in the run admin Wrap layout to prevent them from touching on
  narrow screens.

- **Migration archived**: `add_AssetId_to_KennelPhotos.sql` moved to
  `db/hc6/app/archive/` after having been run against the database.

## 2.5.2+1129 (2026-05-24)

### Bug fixes

- **Run admin button layout**: Restored the run admin menu to its correct
  appearance — buttons are fixed 110×110 tiles spaced evenly across the row,
  rather than expanding to fill the full column width.

- **Boot hang — isAtRunStart deferred**: `isAtRunStart` (which performs a GPS
  poll on run day) is now initialised after the app content is rendered,
  preventing it from blocking the boot sequence. GPS wait is also capped at
  30 seconds to avoid an indefinite hang on devices where location is slow
  to resolve.

### Improvements

- **Geocoding country fallback**: When the country field is blank in the run
  address form, the geocoder now looks up the kennel's registered country from
  the local database and uses it automatically. Prevents geocoding failures for
  kennels where no country has been typed in.

- **Auto-locate dialog after address save**: After saving an address in the run
  editor, a dialog now prompts "Would you like me to try to automatically find
  the map pin for the new address?" with "Not now" and "Auto-locate" options,
  replacing the previous snackbar action. Only shown when there is enough
  address data to attempt geocoding (postcode, or street + city).

- **Styled confirm dialogs**: The "Delete image" and address-save confirmation
  dialogs now use ElevatedButton widgets (teal for cancel/not-now, red for
  destructive actions) for clearer visual affordance.

- **[BOOT] instrumentation extended**: Boot timing markers now extend through
  to the point where app content is visible, giving a complete picture of the
  full startup sequence in the diagnostic log.

## 2.5.1+1128 (2026-05-24)

### New features

- **Copy boot log from My Profile**: A "Diagnostic Logs" section is now shown at
  the bottom of the My Profile page (accessible via the drawer menu). It contains
  a "Copy log to clipboard" button that captures the same `BootLogger` startup
  output as the boot-screen overlay, allowing the log to be retrieved after the
  app has fully loaded without needing to reproduce the boot sequence. The button
  is disabled if no log lines have been captured yet, and shows "Copied!" for two
  seconds after a successful copy.

## 2.5.0+1127 (2026-05-24)

### New features

- **Address-to-pin geocoding in run editor**: Addresses and map pins can now be
  kept in sync with one tap. In edit-run mode the address-saved confirmation
  snackbar includes a "Locate pin" action — tapping it calls the Nominatim
  (OpenStreetMap) geocoding API with the saved address fields and, if a match is
  found, jumps to the Map tab with the pin pre-positioned at the geocoded
  location. In new-run mode an "Auto-locate" button has been added to the Map
  tab's button row, so the user can position the pin from the address they just
  entered before confirming with "Set Location". A loading spinner shows during
  the geocoding call; a fallback snackbar is shown if the address cannot be
  located. No API key required.

- **Live run tracking — timing gate**: The "Start Run Tracking" button is now
  disabled until five minutes before the run's scheduled start time. When
  outside this window the button displays "Tracking opens at [time]" and is
  greyed out. A background timer polls every 30 seconds and enables the button
  automatically when the window opens, without requiring the user to leave and
  re-enter the screen.

- **Boot hang diagnostic — BootLogger overlay**: Added a temporary `BootLogger`
  utility that intercepts all `debugPrint` output from the moment `main()`
  starts. A scrolling overlay panel is shown on the splash screen and on the
  "Filling Your Mug" loading screen during boot, with a "Copy log to clipboard"
  button for capturing the sequence of startup events. This tool will be removed
  once the reported boot hang is diagnosed.

### Bug fixes

- **Delete event image — SP + service layer**: The "Delete image" button in the
  run image editor previously sent no instruction to the server, leaving the
  existing image URL in place. `hcapp_addEditEvent` now accepts a
  `@deleteEventImage BIT` parameter; when set, `EventImage` is explicitly
  cleared to `NULL` rather than left unchanged by the `COALESCE` fallback. The
  Flutter service layer passes `deleteEventImage: '1'` in the request body when
  the user confirms deletion.

## 2.5.0+1126 (2026-05-24)

### Bug fixes

- **Edit mismanagement roles / HC App permissions — silent failure**: Saving
  either of these fields called `hcapp_joinKennel`, which (when editing another
  user) delegates to `hcapp_syncKennelAdminData`. That SP updates `HC.Kennel`
  when roles change, which bumps the kennel's `updatedAt`. The subsequent sync
  returned a kennel row, and the ingestion engine matched it to
  `KennelsTableHelper` — but `KennelsTableHelper.getTableName(AppDomainType.kennel)`
  threw an exception because it only handled `AppDomainType.user`. The exception
  was caught in `_setUserProperties`, so the app didn't crash, but the save
  appeared to fail ("Could not save — check your connection") and kennel data
  was not written to the local DB. Fixed by making `KennelsTableHelper.getTableName`
  return `commonTableName` for all domain types — kennels are stored in a single
  shared table regardless of which sync domain is writing to them.

- **Success envelope printed as unrecognised data**: Write SPs (including
  `hcapp_joinKennel`) return a `[{"success":1,...}]` envelope at rowset 0
  before the sync data. The base ingestion engine (`updateSqlTablesFromJsonWithAdHocData`)
  did not recognise this as a known pattern, so it printed debug warnings for
  every write operation and the `adHocData` return value was lost (causing the
  wrong snackbar message even when the save succeeded). Fixed by adding
  `ServiceCommon.stripSuccessEnvelope()`, which removes rowset 0 when it is a
  success envelope before handing the response to the ingestion engine. Applied
  in all three sync service adapters: `SyncKennelAdminService`,
  `SyncUserDataService`, and `SyncEventAdminService`.

## 2.5.0+1125 (2026-05-23)

### Bug fixes

- **Future runs list — pull-to-refresh clears all runs**: Pulling to refresh
  called `refreshFromBackend(clearLocalTables: true)`, which wiped the local
  SQLite events/HEM/payments tables before fetching fresh data. The subsequent
  `syncUserDataService.updateFromBackend` call had a debounce guard that
  silently returned early when a sync had run recently — leaving the DB empty.
  `refreshFromTable` then queried that empty DB and rendered a "no runs" state.
  Fixed by making the debounce respect the `forceRefresh` flag. Additionally,
  the debounce has been removed entirely for now while the right threshold is
  determined.

- **Sync debounce — `forceRefresh` parameter ignored**: `forceRefresh: true`
  was accepted by `SyncUserDataService.updateFromBackend` but never consulted
  in the debounce check. All callers passing `true` (kennel admin, kennel list,
  hasher profile, future run list) were silently hitting the debounce anyway.
  The debounce now gates on `!forceRefresh`.

- **Sync debounce — reduced from 120 s to 30 s**: The 120-second guard was
  too aggressive; a normal user interaction can easily trigger a sync within
  that window. Reduced to 30 seconds to match actual quick-restart scenarios.

- **Manual check-in — stale hasher data on exit**: Navigating away from the
  manual check-in page now fires a background `syncUserData` against the
  hashers table, picking up any member profile changes (hash names, photos,
  membership state) that occurred during the check-in session.

---

## 2.5.0+1124 (2026-05-23)

### Bug fixes

- **Check-in popup — silent failure**: `setEventAttendence` returning an empty
  list (connectivity guard triggered, or SP error) was silently swallowed. The
  caller now shows a "Check-in failed" snackbar when the response is empty and
  a "Checked in!" confirmation when it succeeds, so the user always gets
  actionable feedback.

- **Mismanagement roles — no confirmation and silent save**: `updateHasherKennelStatus`
  was a mutation without `noRetries: true`, risking duplicate writes on retry.
  Added `noRetries: true`. After saving a mismanagement role or app-access
  change, a snackbar now confirms success or reports failure so the user knows
  the outcome without guessing.

- **Photo review — batch save error**: `updates` was sent as a JSON array in
  the HTTP body (`"updates":[...]`). The API shim passes this directly to the
  SP's `@updates NVARCHAR(MAX)` parameter, which expects a JSON *string*. Fixed
  by serialising to `jsonEncode(updates)` before including in the body so the
  SP receives a parseable JSON string.

- **Photo review — immediate save on last pending photo**: Previously the 5-second
  debounce always fired after every action. When the last pending photo is
  actioned and no pending photos remain, the queue now flushes immediately
  without waiting for the debounce. Actions are also blocked while a save is
  in progress.

- **KennelPhotos map — empty camera icon shown for private/unapproved photos**:
  Returning an empty camera-frame marker for photos that have no resolved URL
  (not yet approved for this viewer, or private) was confusing. The marker is
  now completely hidden (`SizedBox.shrink()`) when the URL cannot be resolved,
  so only photos the user is permitted to see appear on the map.

- **KennelPhotos map — zoomable photo page has black background**: Tapping a
  photo marker opened `ZoomableImagePage2` without a background, so
  `photo_view` defaulted to black. Now passes `Backgrounds.defaultHcBackground()`
  so the jungle theme is shown consistently.

---

## 2.5.0+1123 (2026-05-23)

### Stability

- **Boot hang — infinite sync paging loop**: `SyncUserDataService` uses a
  `while (tablesToSync != 0)` paging loop. If the base-service bitmask logic
  fails to clear a table bit when the SP returns 0 updated rows, the loop
  retries the same request forever, leaving the app stuck on the "Filling Your
  Mug" loading screen. Added a 100-iteration guard with a diagnostic log; the
  break covers both this scenario and any future edge case where the paging
  token is not correctly zeroed.

### Memory leaks — StatefulWidget disposal

Added `dispose()` to 12 State classes that were creating `TextEditingController`
and `FocusNode` instances without ever calling `.dispose()`. Each popup or page
shown and dismissed leaks one or more native text engine objects. Fixed:

- `widgets/multiple_choice_popup.dart` — FocusNode + TextEditingController
- `widgets/add_virgin_visitor_popup.dart` — FocusNode + 3× TextEditingController
- `widgets/email_popup.dart` — FocusNode + TextEditingController
- `widgets/confirm_auto_checkin_popup.dart` — FocusNode + TextEditingController
- `pages/init/third_party_login.dart` — 2× FocusNode + 2× TextEditingController
- `pages/init/create_new_account.dart` — FocusNode
- `pages/run_admin/create_new_event_popup.dart` — FocusNode + TextEditingController
- `pages/kennel_admin/run_number_popup.dart` — FocusNode + TextEditingController
- `pages/kennel_admin/kennel_members.dart` — AnimationController + FocusNode + TextEditingController
- `pages/run_admin/find_hasher_page.dart` — FocusNode + TextEditingController
- `pages/menu_pages/hasher_profile_page.dart` — 6× TextEditingController
- `pages/menu_pages/get_reset_code_popup.dart` — FocusNode + TextEditingController

All 25 GetX controllers were audited and confirmed clean.

---

## 2.5.0+1122 (2026-05-23)

### Security

- **KennelPhotos — photo URLs no longer stored in GPS track**: Previously the
  full Azure Blob Storage URL was embedded in every PHO GPS marker label,
  meaning anyone who could read the GPS track data could access photos directly
  and bypass status-based access control (private, deleted). The label now
  stores only the photoId UUID. The map controller fetches authorised URLs via
  `hcapp_getRunPhotos` on load and every 15-second auto-update tick, so only
  photos the caller is permitted to see resolve to a URL — private and
  soft-deleted photos show as empty camera frames.

### Bug fixes

- **KennelPhotos — map photos not loading after security fix**: The photo URL
  cache was reading rowsets at the wrong indices (`[1, 2]` instead of `[0, 1]`)
  because `hcapp_getRunPhotos` returns data as rowset 0 on success with no
  envelope. All six photos now load correctly.

- **KennelPhotos — map photo cache never populated**: `KennelPhotoService` is
  instantiated directly throughout the app and is not registered with GetX.
  `Get.find<KennelPhotoService>()` was throwing silently, leaving the cache
  empty. Fixed to use `KennelPhotoService()` directly, consistent with all
  other call sites.

- **KennelPhotos — soft-deleted photos visible on others' maps**: Photos with
  `Status ≥ 2` but a non-null `DeletedAt` were still returned to other users
  by `hcapp_getRunPhotos`. Added `DeletedAt IS NULL` filter to the others'
  public photos rowset.

---

## 2.5.0+1121 (2026-05-23)

### Improvements

- **KennelPhotos — instant review with queued batch upload**: Actions in the
  photo review screen now apply immediately to the UI with no network wait.
  Changes are queued locally and flushed to the server in a single batch call
  after a 5-second pause in activity. Navigating away triggers an immediate
  flush with a "Saving…" progress indicator in the app bar.

- **KennelPhotos — batch failure handling**: If the batch upload fails, all
  optimistically-applied changes are reverted to their previous statuses and a
  dismissable error dialog is shown. If a partial failure occurs (some photos
  not found or from a different kennel), the successful updates are kept and a
  warning is shown with the failure count.

- **KennelPhotos — delete confirmation pauses debounce timer**: The 5-second
  debounce timer is paused while the delete confirmation dialog is visible so
  the batch does not flush mid-dialog.

---

## 2.5.0+1120 (2026-05-23)

### New features

- **KennelPhotos — full photo review redesign**: Review Photos is now
  event-scoped (run admin only; removed from kennel admin). The screen
  shows a persistent header with the kennel logo, event name, and a
  colour-coded count chip for every status (Pending, Private, Shared,
  Run Gallery, Home Gallery, Event Cover, Deleted). Pending and Reviewed
  tabs let the Hash Flash switch between unactioned and already-actioned
  photos. The same action buttons work on both tabs — any action
  overwrites the existing status.

- **KennelPhotos — soft delete**: Deleting a photo now sets a `DeletedAt`
  timestamp instead of removing the row. Deleted photos appear in the
  Reviewed tab with a dimmed overlay. Any other action (Keep Private,
  Share, etc.) restores the photo and applies the new status.

- **KennelPhotos — re-review**: Previously approved photos can be
  re-actioned at any time from the Reviewed tab, overwriting the
  existing status in the database.

---

## 2.5.0+1119 (2026-05-22)

### Bug fixes

- **Run History — empty list when viewing another member's history**: Tapping
  "View Run History" on a kennel member's profile showed no runs. The sync
  wrote the selected user's HEM data to the kennel-domain table, but the page
  was querying the user-domain table. Fixed by deriving `AppDomainType` from
  `dataContext` so the query always hits the same table the sync wrote to.

---

## 2.5.0+1118 (2026-05-22)

### Improvements

- **KennelPhotos — photo fills camera frame**: The thumbnail now bleeds
  slightly beyond the transparent cutout so no background pixel is visible
  between the photo and the camera frame edge.

- **KennelPhotos — marker size scaling**: Minimum photo marker size raised
  from 25 px to 50 px. Markers now shrink on a quadratic curve as you zoom
  out, so they reduce in size faster while still reaching full screen width
  at maximum zoom.

- **KennelPhotos — tap to view full image**: Tapping a photo marker on the
  map opens the photo full-screen in the zoomable image viewer, with the
  event name shown in the app bar.

---

## 2.5.0+1117 (2026-05-22)

### New features

- **KennelPhotos — photo markers on the live run map**: PHO track points
  now render as camera-shaped map pin markers with the actual photo
  thumbnail displayed inside the camera LCD frame. Landscape photos use
  a wide camera frame; portrait photos use a tall frame — orientation is
  detected automatically from the image dimensions.

- **KennelPhotos — count-up loading indicator**: While a photo marker is
  loading its thumbnail (0–9 seconds), a counter is shown inside the
  camera frame so it is clear the image is in progress rather than
  broken.

- **KennelPhotos — zoom-responsive marker size**: Photo markers scale from
  a minimal 25 px at full-run view to approximately screen width at
  maximum zoom, making them easy to spot at a distance and large enough
  to inspect up close.

### Bug fixes

- **KennelPhotos — photo markers silently dropped by GPS filter**: Typed
  track points (PHO and all other marker types) were being removed by the
  GPS accuracy and velocity filter if their GPS fix was poor or their
  timestamp was within 1 second of the preceding point. Typed points now
  bypass all quality checks — they are intentional user actions and must
  always survive the filter.

- **KennelPhotos — PHO GPS label truncated at 54 characters**: The
  `StorePositions` API endpoint was silently dropping any `Type` field
  longer than 54 characters. PHO labels (which embed the full blob URL)
  are up to ~165 characters. Limit raised to 200.

- **KennelPhotos — photo URL correctly sourced from API response**: The
  full blob URL returned by `GetPhotoUploadToken` is now stored verbatim
  in the GPS track label, eliminating a storage-account-name assumption
  that could have broken thumbnail loading after an infrastructure change.

### Stability (pre-3.0 hardening — Session 1)

- **`isAtRunStart` throttle re-enabled**: The 2-minute rate-limit was
  accidentally left disabled by a `TODO: Re-enable before next release`
  comment. Without it, every screen unlock, boot, and 5 other call sites
  fired an unthrottled network + DB call.

- **GetX resource leaks — 8 controllers**: Added or completed `onClose()`
  in `OtherPaymentPopupController`, `CheckInPackController`,
  `KennelsListPageController`, `FutureRunListPageController`,
  `LiveRunGeneralController`, `LocationService`, `KennelAdminController`,
  and `MainNavigationPageController`. Resources leaked: `Worker` objects
  from `debounce()`/`ever()`, `TextEditingController`, `FocusNode`,
  `ScrollController`, `AnimationController`, `MapController`.

- **Sync service crash on first install**: All three sync services called
  `table.first['maxDate']` without an `isEmpty` guard. On a fresh install
  the table is empty, causing a `RangeError` that could hang the boot.

- **Email report HTTP calls had no timeout**: Four fire-and-forget email
  endpoints (`SendKennelRunStatsReport`, `SendRunCountsReport`,
  `SendPaymentReport`, `EmailInviteCode`) could hang indefinitely. Each
  now has a 30-second timeout.

### Stability (pre-3.0 hardening — Session 2)

- **59× `userId` force-unwraps replaced**: All `getStringPref(userId)!`
  force-unwraps across services, pages, and widgets have been replaced
  with a new `currentUserId` getter that returns `''` instead of throwing.
  This eliminates a class of crashes on first boot and after a credential
  wipe.

- **Mutations now use `noRetries: true`**: Payment, RSVP, attendance,
  event, receipt, and user-edit calls were retrying up to 6 times on
  network failure. This risked creating duplicate records in the database.
  All 10 mutation call sites now pass `noRetries: true`.

- **3× empty catch blocks**: Silent `catch (_) {}` blocks in
  `KennelsListPageController`, `HashFlashApprovalPage`, and
  `MainNavigationPageController` now log the error with `debugPrint`.

- **4× `DateTime.parse()` crash risk**: Unguarded parses on DB-sourced
  strings in `HashRunArtGalleryPage`, `RunLocationsController`,
  `RunTabs`, and `RunListItem` replaced with `DateTime.tryParse()` +
  safe fallbacks.

- **Unguarded array access hardened**: COUNT query results in
  `common_queries.dart`, double-nested JSON decode in
  `utilities_null_safe.dart`, `result[1][0]` in
  `authorize_device_service.dart`, and barcode scan `.barcodes.first`
  in three scanner pages now all have proper guards.

- **Photo upload token fields null-checked**: `sasUrl` and `blobUrl` are
  now validated before use in `kennel_photo_service.dart`; a clear
  snackbar is shown if either field is missing.

- **`recordError()` timeout added**: The error-logging HTTP call had no
  timeout and could block the app if the reporting endpoint was slow.
  Now capped at 30 seconds.

## 2.4.10+1116 (2026-05-21)

### Enhancements

- **KennelPhotos — post-crop sharing sheet**: After cropping a photo,
  a bottom sheet now asks what to do with it:
  - **Discard** — removes the photo, nothing is uploaded
  - **Save privately** — uploads and stores for the taker only
  - **Save and share** — uploads and forwards to the Hash Flash for review

  Previously the sharing preference was inherited from the user's saved
  setting. It is now always an explicit per-photo decision.

## 2.4.9+1115 (2026-05-21)

### Enhancements

- **KennelPhotos — run-scoped storage path**: Photos are now stored under
  `trail-photos/{kennelSlug}/{kennelSlug}-{runNumber}/{filename}` for
  numbered runs (e.g. `shhh/shhh-456/…`), or `trail-photos/{kennelSlug}/other/{filename}`
  when the run has no number. All photos from the same run land in the same
  Azure Blob Storage subfolder, making manual browsing and future bulk
  operations straightforward.

- **KennelPhotos — enriched PHO GPS marker**: The PHO track-point label now
  encodes the run folder and full blob filename
  (`<runFolder>/<userId>-<photoGuid>.jpg`) so the map renderer can locate
  the photo directly without a separate cache lookup.

## 2.4.8+1114 (2026-05-21)

### Developer experience

- **KennelPhotos — simulator support**: Running on the iOS or Android
  simulator no longer blocks at the camera step. When `isPhysicalDevice`
  is false the app loads the bundled splash-screen JPEG as a placeholder,
  then runs the full token → blob upload → database record flow as normal.
  No user-visible change on physical devices.

## 2.4.7+1113 (2026-05-21)

### Code quality

- **Sync services — dead code removal**: Removed a long-standing `if (true)`
  dead-code wrapper from all three sync services (`SyncUserDataService`,
  `SyncKennelAdminService`, `SyncEventAdminService`). The original cache-expiry
  condition was commented out years ago and replaced with an unconditional
  `if (true)` placeholder, leaving the entire method body unnecessarily
  nested. No behaviour change.

## 2.4.6+1112 (2026-05-21)

### Bug fixes

- **Boot hang — permanent loading screen**: Added try/catch to `onInitAsync()`
  and `setupDatabase()`. Previously, any unhandled exception inside the boot
  sync chain (malformed server data, SQLite error, network failure) was silently
  swallowed by `unawaited()`, leaving the loading screen displayed permanently
  until the app was force-killed. The app now falls through to offline mode
  with cached data instead.

- **Boot hang — `Ipify.ipv4()` timeout**: The IP-lookup call at login had no
  timeout. A slow or unreachable `api.ipify.org` response could block the
  entire login request indefinitely. Now capped at 4 seconds with a `0.0.0.0`
  fallback.

- **Photo upload — follower-only restriction removed**: Any authenticated
  Harrier Central user on a live run can now take and upload photos. The
  previous `Following = 1` check in `hcapp_getPhotoUploadToken` and
  `hcapp_addKennelPhoto` has been removed.

### Performance

- **Boot sync — O(N) SQLite reads eliminated**: The sync engine previously
  issued one `SELECT` per incoming record to check local existence (up to 2 500
  reads for the Hashers table). This has been replaced with a single batched
  `SELECT … IN (…)` query, chunked at 900 PKs per call. On a physical device
  with NAND flash storage, Hashers sync time drops from ~30–60 s to ~1–2 s.
  (Change is in the `ive_flutter_core_mobile` helper package v1.2.16.)

### Other

- **Sync debounce**: Raised from 5 s to 120 s. A 5-second window was
  effectively zero — every app relaunch re-synced all tables. Quick restarts
  (e.g. from Settings → Reload Data) now skip the expensive full sync while
  normal relaunches (minutes apart) still fetch fresh data.

## 2.4.5+1111 (2026-05-21)

### Enhancements

- **Photo review — 6-level approval scale**: The Hash Flash approval screen is
  replaced by a full **Photo Review** screen with two rejection options (Keep
  Private, Delete) and four escalating approval levels, each implying all
  levels below it:
  - **Share with Hash** — visible to all Harrier Central users on run maps
  - **Run Gallery** — also appears in the run's photo gallery
  - **Home Gallery** — also featured on the kennel home page
  - **Event Cover** — also set as the run's cover photo (`HC.Event.EventCoverPhotoUrl`)

- **Photo review — expanded reviewer roles**: The Review Photos button in the
  kennel admin page is now visible to Hash Flash, Grand Master, Vice-GM, and RA
  (previously Hash Flash only).

- **Photo upload — kennel slug folder**: Photos now upload into
  `trail-photos/{kennelSlug}/` in Azure Blob Storage rather than a UUID-named
  folder. The slug is resolved server-side so no app rebuild was required for
  the initial fix.

### Bug fixes

- **Photo upload — upload token error**: Fixed a 403 auth failure caused by the
  SP checking `IsMember = 1` (defaults to 0); relaxed to `Following = 1` so any
  kennel follower can take photos during a run.

## 2.4.4+1110 (2026-05-20)

### New features

- **KennelPhotos — photo capture during a live run**: Hashers can now take photos
  mid-run using the new **Take Photo** button on the Live Run Tools tab. Photos are
  uploaded directly to Azure Blob Storage via a short-lived SAS token, then recorded
  against the run. A `PHO` marker is enqueued into the GPS track feed so the photo
  location appears on the map.

- **KennelPhotos — sharing preference**: Sharing is controlled by a three-level
  preference (per-run → per-kennel → global). Photos default to private; members
  can opt in to share with the Hash Flash for review.

- **Hash Flash approval screen**: Committee members with the Hash Flash role can
  now review shared photos from the kennel admin page. Each photo can be approved
  (made public), kept private, or deleted. Accessible via the **Review Photos**
  button in the kennel admin functions section (visible only to Hash Flash role
  holders).

- **Live Run Tools — chat strip**: The embedded full chat UI on the Tools tab is
  replaced with a compact read-only strip showing the last 3 messages, a total
  message count badge, and an **Open Chat** button that jumps to the Chat tab.

- **Live Run Tools — QR codes button**: The QR code carousel is removed from the
  Tools tab. A slim **QR Codes** outline button now navigates directly to the
  existing QR tab.

### Bug fixes

- **Live Run nav bar — selected icon invisible**: The active tab icon was
  `Colors.black54` regardless of state, making it invisible against the red
  button background. Selected icons are now white.

- **Live Run Tools — page crash on load**: Two layout assertion failures fixed:
  `Expanded` was incorrectly nested inside an `Obx` wrapper (must be a direct
  `Row` child), and `CrossAxisAlignment.stretch` was applied to a `Row` inside
  an unbounded-height `Column` (resolved with `IntrinsicHeight`).

## 2.4.3+1109 (2026-05-19)

### Code quality

- **`setStateIfMounted` utility**: Added `safe_set_state.dart` — a `State<T>`
  extension that wraps `setState` with a mounted guard. Exported globally via
  `imports.dart`.
- **Codebase-wide `setState` → `setStateIfMounted` migration**: Replaced all
  bare `setState` calls across ~80 files (pages, widgets, controllers) with
  the guarded variant, eliminating a class of "setState called after dispose"
  crashes that can surface when async callbacks complete after a widget unmounts.
- **`buildMapLocation()` utility**: Added to `Utilities` in
  `utilities_null_safe.dart` — resolves an `EventModel` to a map-resolvable
  location string (structured address → coordinates → one-line description).
- **`dart format`**: Applied formatter across the codebase to normalise line
  lengths and indentation.

## 2.4.2+1108 (2026-05-16)

### Enhancements

- **Profile — distance preference auto-saves on selection**: Selecting a distance
  unit (Auto / Kilometers / Miles) in the profile settings now immediately saves the
  preference to the server without requiring the "Save Changes" button. A spinner
  appears next to the "Distance Preference" heading while the call is in-flight, and
  the radio group is non-interactive until the save completes.

### Bug fixes

- **Hash History — wrong table domain in hasher profile view**: Run history launched
  from a hasher's profile was reading from the kennel-domain tables instead of the
  common-domain tables, causing empty or incorrect history. Fixed to always use the
  common domain for all history views.
- **Hash History — missing table prefix in country history query**: The UNION branch
  of the country history query referenced `kennels` instead of `common_kennels`,
  causing a SQLite "no such table" error. Fixed.
- **Hash History — missing table alias in run history UNION query**: JOIN conditions
  in the UNION branch were missing the `hem.` alias, causing ambiguous column errors.
  Fixed.
- **Hash History — UUID not normalised in country stats**: `CountryStats.fromMap` was
  not normalising the `countryId` UUID, causing country drill-down navigation to fail
  silently when the server returned uppercase UUIDs. Fixed.
- **Kennel admin — past runs not loading**: Kennel admins who were not following a
  kennel saw an empty past runs calendar because `common_events` only holds 10 days
  of history for unfollowed kennels. The app now automatically follows the kennel and
  force-replicates all event history before entering admin screens.
- **Kennel admin — filter events GetX crash**: The `publishedRunCount` field was a
  plain `List`, causing the `Obx` widget that reads it to throw a GetX "improper use"
  error on load. Made it reactive (`RxList`).
- **Kennel admin — manual refresh skipped kennel domain sync**: Pull-to-refresh on
  the filter events page only re-synced events, leaving kennel-domain membership data
  stale. Now also refreshes `hasherKennelMap` via `syncKennelAdminService`.
- **Chat — access token always rejected**: `hcapp_getEventMessages` and
  `hcapp_sendEventMessage` were generating compound tokens (`deviceSecret + eventId`)
  but the SPs validated against `eventId` only. Token generation and SPs now both use
  the standard device-secret token.

## 2.4.1+1107 (2026-05-13)

7 bug fixes — see git log for details.

## 2.4.0+1106 (2026-05-10)

State management overhaul, 4 new GetX migrations, boot fix.
