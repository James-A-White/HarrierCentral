# Mobile App — TODO (pre-3.0 release)

Generated 2026-05-21 after deep 4-agent audit of 249 Dart files.
Status key: `[ ]` open · `[x]` done · `[-]` won't fix

---

## SESSION 1 — Critical crashes and resource leaks

These must be fixed before 3.0 ships.

### 1. Re-enable `isAtRunStart` throttle — EXPLICITLY MARKED FOR THIS RELEASE
- [x] **`lib/util/utilities_null_safe.dart` line ~1174** — 2-minute rate-limit on `isAtRunStart()` was commented out with `////// TODO: Re-enable this before next release`. Without it, every screen unlock, boot, and 5 other call sites fire an unthrottled network+DB call. Re-enable the `_lastIsAtRunStartCheck` time-guard.

### 2. GetX controller resource leaks — onClose() missing or incomplete

- [x] **`OtherPaymentPopupController`** (`pages/payments/other_payment_popup.dart`) — Has NO `onClose()` at all. Leaks: 3× `TextEditingController` + 3× `FocusNode`. Add `onClose()` that disposes all 6.
- [x] **`CheckInPackController`** (`pages/run_admin/check_in_pack_page/check_in_pack_page_controller.dart`) — Has NO `onClose()`. Leaks: `ScrollController` + `TextEditingController` + `FocusNode`. Add `onClose()`.
- [x] **`KennelsListPageController`** (`pages/top_level/kennel_list_controller.dart`) — `debounce()` return value not stored, never disposed. Store in `Worker? _searchWorker` field; call `_searchWorker?.dispose()` in `onClose()`.
- [x] **`FutureRunListPageController`** (`pages/top_level/future_run_list_page/future_run_list_controller.dart`) — 3× `debounce()` Worker return values not stored. Same fix as above for all three workers.
- [x] **`LiveRunGeneralController`** (`pages/live_run_pages/live_run_general_page.dart` lines 29–30) — 2× `ever()` Worker return values not stored. Store and dispose in `onClose()`.
- [x] **`LocationService`** (`services/location_service/location_service.dart`) — `ever(joinRunTracking, ...)` Worker not stored/disposed. Store and dispose in `onClose()`.
- [x] **`KennelAdminController`** (`pages/detail_pages/kennel_admin_main.dart`) — `MapController mapController` created but never disposed in `onClose()`. Add `mapController.dispose()`.
- [x] **`MainNavigationPageController`** (`pages/top_level/main_navigation_page/main_navigation_page_controller.dart`) — `WidgetsBindingObserver` added via `addObserver(this)` in `onInit()`, never removed. The method is called `dispose()` — GetX won't call this. Rename to `onClose()` and verify `removeObserver(this)` is inside it.

### 3. `LocationService` multiple Get.put() registrations
- [x] **5 registration sites** — `Get.put(LocationService())` is called from: `main.dart:27`, `app_boot_service.dart:386`, `permissions_slider.dart:202`, `permissions_slider.dart:277`, `hasher_profile_page.dart:2220`. Each silently replaces the previous instance. Register once in `initServices()` with `fenix: true`; change all other sites to `Get.find<LocationService>()`.

### 4. `.first` crash on sync service SQL queries
Three sync services access `table.first['maxDate']` with no isEmpty guard. If the table is empty on first install, this throws a `RangeError` and can hang the boot.
- [x] **`lib/data/hc3_services/sync_user_data_service.dart` line 47**
- [x] **`lib/data/hc3_services/sync_kennel_admin_service.dart` line 26**
- [x] **`lib/data/hc3_services/sync_event_admin_service.dart` line 30**

Fix: `table.isNotEmpty ? table.first['maxDate'] : null`

### 5. Email report HTTP timeouts missing
Four `http.post()` calls have `.catchError()` but no `.timeout()` and can hang indefinitely:
- [x] **`lib/data/services/email_reports_service.dart` line 41**
- [x] **`lib/data/hc3_services/hasher_event_map/hasher_event_map_service.dart` line 188**
- [x] **`lib/data/hc3_services/payments/payments_service.dart` line 371**
- [x] **`lib/data/hc3_services/hashers/hashers_service.dart` line 296**

Fix: Add `.timeout(const Duration(seconds: 30), onTimeout: () => http.Response('', 408))` before `.catchError(...)`.

---

## SESSION 2 — Hardening and data integrity

### 6. `getStringPref(StringPrefsEnum.userId)!` — 59 force-unwraps
Crashes on first boot or after credential wipe. High-frequency, scattered across all layers. Approach: add a `currentUserId` getter in a central place that returns `''` instead of throwing, and replace the 59 force-unwraps.

High-risk locations to address first:
- [x] **`lib/widgets/run_tabs.dart` line 236** — used in widget build path
- [x] **`lib/pages/top_level/drawer_menu.dart` line 30** — used in widget build path
- [x] **`lib/database/query_kennels.dart` line 191**
- [x] **`lib/database/query_runs.dart` line 580**
- [x] **`lib/pages/detail_pages/chat/chat_page_controller.dart` lines 109, 307**
- [x] **`lib/data/services/kennel_photo_service.dart` lines 146, 216, 270, 292, 318**
- [x] Remaining ~50 instances across service and page files (batch by file)

### 7. Empty catch blocks hiding exceptions
- [x] **`lib/pages/top_level/kennel_list_controller.dart` lines 444, 449** — empty `catch (_) {}` around DELETE queries. Add `debugPrint` at minimum.
- [x] **`lib/pages/kennel_admin/hash_flash_approval_page.dart` line 76** — empty `catch (_) {}` swallows all errors loading pending photos. Assign error state + show user message.
- [x] **`lib/pages/top_level/main_navigation_page/main_navigation_page_controller.dart` line 439** — empty catch in screen state watcher. Add `debugPrint`.

### 8. `DateTime.parse()` without try/catch on non-hardcoded strings
- [x] **`lib/pages/misc_pages/hash_run_art_gallery_page.dart` line 112** — direct parse from DB value
- [x] **`lib/pages/top_level/run_locations_controller.dart` line 450** — substring + parse from dict value
- [x] **`lib/widgets/run_tabs.dart` line 876** — parse after substring manipulation
- [x] **`lib/widgets/run_list_item.dart` lines 164–167** — ISO string substring + parse (arguable if this can fail, but defensive is cheap)

Fix: wrap each in `try/catch` with `debugPrint` and a safe DateTime fallback.

### 9. Mutation operations using default retry (can create duplicate records)
`sendHttpPost` retries up to 6 times on network failure. For idempotent reads this is fine; for mutations it risks duplicate records in the DB.

- [x] **`payments_service.dart:197` `processBulkPayment`** — add `noRetries: true`
- [x] **`payments_service.dart:317` `processPayment`** — add `noRetries: true`
- [x] **`hasher_event_map_service.dart:346` `setEventRsvp`** — add `noRetries: true`
- [x] **`hasher_event_map_service.dart:493` `setEventAttendence`** — add `noRetries: true`
- [x] **`hasher_event_map_service.dart:423` `setBulkEventAttendence`** — add `noRetries: true`
- [x] **`events_service.dart:438` `addEditEvent`** — add `noRetries: true`
- [x] **`receipts_service.dart:143` `addEditReceipt`** — add `noRetries: true`
- [x] **`hashers_service.dart:230` `addEditUser`** — add `noRetries: true`

Note: First verify that `noRetries: true` is a real param on `sendHttpPost` — check service_common.dart. If not, the fix is to check for ERROR_PREFIX after first attempt and not retry on non-network errors.

### 10. Unguarded array access patterns
- [x] **`lib/database/common_queries.dart` lines 16, 28** — `results[0]` on COUNT query result. Add `results.isNotEmpty ?` guard; COUNT should never be empty but defensive is cheap.
- [x] **`lib/database/query_kennels.dart` lines 206–212** — `results[0]` access without isEmpty guard. Add guard.
- [x] **`lib/util/utilities_null_safe.dart` line 791** — `jsonDecode(responseBody)[0][0]['result']` double-nested with no guard. Add length checks.
- [x] **`lib/data/services/authorize_device_service.dart` line 94** — `result[1][0]` accessed after only guarding `result[0]`. Add `result.length > 1 && result[1].isNotEmpty` check.
- [x] **Barcode scan handlers** — `.barcodes.first.rawValue` with no isEmpty guard in:
  - `pages/init/use_invite_code_page.dart:305`
  - `pages/run_admin/check_in_scanner_page.dart:155`
  - `pages/top_level/user_qr_code_page.dart:761`

### 11. Photo upload API response force-unwraps
- [x] **`lib/data/services/kennel_photo_service.dart` lines 63, 77** — `tokenResult['sasUrl']!` and `tokenResult['blobUrl']!`. If API returns a 200 but the JSON is missing these keys, the app crashes mid-upload. Add null-coalescing + early return with error message.

### 12. AppBootService HC6 envelope parsing
- [x] **`lib/data/services/app_boot_service.dart` lines 415–423** — `responseJson[1][0]` accessed after `responseJson.length < 2` guard but no check that `responseJson[1]` is a non-empty list. Add `responseJson[1] is List && (responseJson[1] as List).isNotEmpty` before accessing `[0]`.

### 13. `recordError()` has no timeout
- [x] **`lib/data/services/service_common.dart` lines 35–41** — Error logging POST has no timeout. If the error reporting endpoint hangs, the app hangs. Add same 30s timeout as other email endpoints.

---

## Down Downs Enhancements — Deployment Checklist (coded 2026-06-09)

Features built: photo marker suppression (pre/post-run), Make a Charge button (DDN/gavel), charge photos, completed charges history view on run detail page.

### DB (run against prod harriercentral.database.windows.net)
- [x] Run `db/hc6/app/add_ChargePhotoUrl_to_DownDowns.sql` (safe — DownDowns is NOT a synced table, no trigger concern)
- [x] Move that file to `db/hc6/app/archive/` after running

### SPs to deploy (via `./tools/deploy_hc6.sh`)
- [x] `hcapp_addDownDown` — new `@chargePhotoUrl` parameter + `ChargePhotoUrl` column in INSERT
- [x] `hcapp_getDownDowns` — new `chargePhotoUrl` column in SELECT (admin view)
- [x] `hcapp_getCompletedDownDowns` — new SP, SP number 58, kennel-member auth

### Assets
- [x] Add `gavel.png` to `mobile-app/images/live_run_map_markers/` (red circle background, white gavel icon, styled to match other markers).

---

## Hash Flash Photo Editing

Design agreed 2026-06-08. Non-destructive: `BlobUrl` is never modified; `EditedBlobUrl`
holds the cropped version. Display everywhere uses `editedBlobUrl ?? blobUrl`. Re-edits
always start from the original `BlobUrl`.

### DB (run once, already scripted)
- [x] Run `db/hc6/add_EditedBlobUrl_to_KennelPhotos.sql` against production, then move to `db/hc6/archive/`

### SPs to update
- [x] `hcapp_getKennelPendingPhotos` — add `EditedBlobUrl` to SELECT
- [x] `hcapp_getRunAllPhotos` — add `EditedBlobUrl` to SELECT
- [x] `hcapp_getRunPhotos` — add `EditedBlobUrl` to SELECT
- [x] `hcapp_batchUpdatePhotoStatus` — `COALESCE(EditedBlobUrl, BlobUrl)` already used for event cover; edit saved via dedicated `hcapp_updateRunPhotoEditedBlob` SP instead

### App changes
- [x] `KennelPendingPhoto` model — add `editedBlobUrl` nullable field
- [x] `RunPhotoModel` — add `editedBlobUrl` nullable field
- [x] Display everywhere — `effectiveUrl` getter (`editedBlobUrl ?? blobUrl`) used throughout
- [x] `PhotoReviewController.editPhoto` — full download → crop → upload → persist flow (uses `hcapp_updateRunPhotoEditedBlob`, not batch)
- [x] `KennelPhotoService.downloadToTempFile` — http.get → temp File
- [x] `KennelPhotoService.uploadEditedPhoto` — SAS token + upload, returns blob URL
- [x] `HashFlashApprovalPage` — crop icon button (top-left of each photo) calls `controller.editPhoto`
- [x] After crop confirmed: optimistic `allPhotos[idx] = copyWithEditedBlobUrl(editedUrl)` update

---

## DEFERRED (post-3.0, tracked for reference)

- [x] **D1** `run_admin/edit_run_details.dart` — convert StatefulWidget to GetX (see fix list D1)
- [x] **D2** `notification_service.dart` lines 111, 292, 312, 318, 539 — `Get.find<Controller>()` calls in notification handlers; controllers may be destroyed when notification arrives. Guard with `GetInstance.isRegistered<T>()` check.
- [x] **D3** `run_tabs.dart:2525` and `kennel_admin_main.dart:640` — `.where().first` without fallback. Low crash risk but worth fixing.
- [x] **D4** `main.dart:30` — `Get.find<ChatPageController>()` in app resume handler; can throw if chat screen was never opened. Guard with `GetInstance.isRegistered<ChatPageController>()`.
- [x] **D5** Mutation retry audit — verify whether `sendHttpPost` actually has a `noRetries` param before implementing Session 2 item 9 above.
- [x] **D6** `MainNavigationController permanent: true` — holds significant memory; evaluate whether `permanent: false` + `fenix: true` is viable.
- [x] **D7** 4x bare `print()` calls not wrapped in `kDebugMode`: `hasher_event_map_service.dart:357,373`, `run_list_item.dart:1198`, `run_tabs.dart:1460`.

---

## 3.0 STABILIZATION — review of this session's changes (2026-07-02)

The runs-list / chat / photo work this session (v2.11.2 → 2.11.11, ~16 commits)
shipped to TestFlight verified only by `flutter analyze`, not on device. The
Session 1/2 audit above is complete; this section tracks the hardening pass.

### Code-review findings
- [x] **Grid multi-select persisted across tabs** — `PhotoReviewController.switchTab`
  didn't clear the selection, so a bulk action after switching Pending↔Reviewed
  could target now-hidden photos. Fixed: `switchTab` → `exitSelectMode()`.
- [ ] **Unseen Chats uses cached counts on entry** — the chat-badge tap renders
  `NotificationService.unreadChatRuns` from the last fetch; it's not refreshed on
  entry. Usually fresh (boot + push + after opening a chat), but a stale/empty
  cache would show an empty list under a non-zero badge. Fire
  `getEventChatMessageCounts()` when entering chats mode (it re-runs the list on
  completion). Low risk.
- [ ] **Unseen Chats SP includes deleted/invisible events** —
  `HC6.hcapp_getEventBadgeCount` Mode 3 joins HC.Event/HC.Kennel with no
  `e.deleted = 0` / `e.IsVisible <> 0` guard, so a deleted run with unread chats
  could surface. Add the guard (+ redeploy SP). Low.

### Device-verify checklist (on current TestFlight 1191)
- [ ] Runs list opens anchored on the "My past runs" divider; scroll up = past runs.
- [ ] Chips My / Events / Map — every combo filters correctly; heading matches
  (e.g. "My Events on Map"); Map's floating View-Map button appears over the list.
- [ ] "My" excludes past No/Maybe (non-attended) and future non-Yes (fixed in 1191).
- [ ] Date-filter button highlights while a range is active; second tap clears it.
- [ ] Unseen Chats: badge count == list length; rows tap into chat; back button +
  keyboard-safe input both work.
- [ ] New member added via Manage Members appears without a full resync.
- [ ] Reload Data no longer shows a false "No Connection".
- [ ] Hash Flash grid: tap opens the right photo; long-press → multi-select → bulk
  action saves and actioned photos leave the Pending grid; 5-button bulk bar lays
  out on a narrow phone.

### Still to do for production
- [ ] Decide App Store submission for the 3.0 build once TestFlight verification
  passes (all builds so far are TestFlight only).
- [ ] Consider reviving the commented-out test infra (sqflite_ffi) for regression
  safety — see project_mobile_test_plan.
