# Harrier Central Mobile App — Changelog

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
