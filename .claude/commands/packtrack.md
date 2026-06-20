# HC Mobile App — PackTrack Feature Reference

> **Load this skill when working on any part of the live run tracking feature.**
> PackTrack spans GPS sending (mobile → API), map display (controller + pages),
> and position retrieval (API → controller). Changes in one area often affect the others.

PackTrack records and displays GPS tracks for multiple hashers during a live run.
Tracks are stored in **Azure Table Storage** (not SQL Server) and served via two
Azure Function endpoints. **GetPositions requires an `X-Api-Key` header
(`GET_POSITIONS_API_KEY` in `constants.dart`); StorePositions is unauthenticated.**
Tracks are keyed by the event's **internal id** (`HC.Event.id`, i.e. the mobile's
`run.event.eventId`), **lowercased** — NOT `PublicEventId` (querying by the public
id returns nothing). Azure Table partition keys are case-sensitive.

---

## File Map

| Purpose | File |
|---------|------|
| GPS stream + tracking toggle | `lib/services/location_service/location_service.dart` |
| Outgoing batch buffer | `lib/services/location_service/run_point_buffer.dart` |
| Read API client | `lib/util/get_positions.dart` |
| GPS noise filter | `lib/util/track_point_filter.dart` |
| Outgoing point model | `lib/data/models/user_event_location/user_event_location.dart` |
| Incoming track models | `lib/data/models/user_positions/user_positions.dart` |
| Map display controller | `lib/controllers/run_tracker_map_controller.dart` |
| Live run shell + pages | `lib/pages/live_run_pages/` |
| Point type enum | `lib/util/enums.dart:600` (`HashRunPointTypes`) |
| API URL constants | `lib/util/constants.dart:95-96` |

---

## API Endpoints

Both are on `harriercentralpublicapi.azurewebsites.net`. **GetPositions requires the
`X-Api-Key` header; StorePositions is unauthenticated.**

### POST /api/GetPositions (`GET_POSITIONS_URL`)

Fetches all tracks for an event, optionally incremental.

**Header:** `X-Api-Key: <GET_POSITIONS_API_KEY>` — required (the call fails without it).

**Request body:**
```json
{
  "eventId": "string",
  "AfterTimestamp": "0000000000000000000",
  "users": []
}
```
- `eventId` — the event's **internal id** (`HC.Event.id` / mobile `run.event.eventId`), **lowercased**. Not `PublicEventId`.
- `AfterTimestamp` — 19-digit zero-padded epoch-ms string. Pass `"0000000000000000000"` for full fetch.
- `users` — reserved, always pass `[]`

**Response** (gzip, browser/http client decompresses automatically):
```json
{
  "eventId": "string",
  "latestServerTimestampMs": "string",
  "users": [
    {
      "id": "string",
      "positions": [
        { "lat": 0.0, "lng": 0.0, "acc": 0.0, "alt": 0.0, "timestampMs": 0, "type": "string|null" }
      ]
    }
  ]
}
```
- `latestServerTimestampMs` — pass back as `AfterTimestamp` on next poll for incremental updates
- `acc` — GPS accuracy radius in metres; used by `TrackPointFilter` to drop unreliable points
- `type` — `null` for normal GPS points; trail marker code for deliberate marks (see Point Types below)

### POST /api/StorePositions (`STORE_POSITIONS_URL`)

Write endpoint used by the mobile app only. Called by `RunPointBuffer._sendBatch`.

**Request body:**
```json
{
  "eventId": "string",
  "userId": "string",
  "positions": [
    { "ts": "0000000000000000000", "lat": 0.0, "lng": 0.0, "acc": 0.0, "alt": 0.0, "type": "string|null" }
  ]
}
```
- `ts` — 19-digit zero-padded epoch-ms (`pad19()` helper in `location_service.dart`)
- Coordinates rounded to 5 decimal places (~1.1m precision)

---

## Data Models

### Outgoing: `UserEventLocation` (Freezed)
What gets sent to StorePositions. Lives in `user_event_location.dart`.

| Field | Type | Notes |
|-------|------|-------|
| `ts` | `String` | 19-digit padded epoch-ms |
| `lat` | `double` | 5 d.p. |
| `lng` | `double` | 5 d.p. |
| `acc` | `double` | 2 d.p. |
| `alt` | `double` | 2 d.p. |
| `type` | `String?` | null for GPS points; point-type string for marks |

### Incoming: `UserPositionsPayload` / `UserTrack` / `TrackPoint` (Freezed)
What comes back from GetPositions. Lives in `user_positions.dart`.

```
UserPositionsPayload
  ├── eventId: String
  ├── latestServerTimestampMs: String?
  └── users: List<UserTrack>
        ├── id: String   (userId)
        └── positions: List<TrackPoint>
              ├── lat / lng / acc: double
              ├── alt: double?
              ├── timestampMs: int
              └── type: String?
```

---

## Point Types — `HashRunPointTypes` enum (`enums.dart:600`)

Continuous GPS positions have `type == null`. Deliberately placed trail marks carry a type string.

**Format:** `KEY` for simple marks, `KEY::label` for marks with custom text (LAB, CAU).

| Key | Enum value | Label | PNG icon |
|-----|-----------|-------|----------|
| `CHK` | `check` | Check | `check.png` |
| `DRK` | `drinkStop` | Drink Stop | `drinkstop.png` |
| `FHK` | `fishhook` | Fish Hook | `fishhook.png` |
| `SC` | `shortCut` | Shortcut | `shortcut.png` |
| `CB` | `checkback` | Checkback | `checkback.png` |
| `HV` | `hashView` | Hash View | `hashview.png` |
| `RG` | `regroup` | Regroup | `regroup.png` |
| `WW` | `whichyWay` | Whichy Way | *(see enum)* |
| `FT` | `falseTail` | False Trail | *(see enum)* |
| `LAB` | `customLabel` | Custom Label | *(see enum)* |
| `OIN` | `onInn` | On Inn | *(see enum)* |
| `CAU` | `caution` | Caution | *(see enum)* |

Parse: `value.split('::')` — first part is the key, optional second part is label text.
PNG icons live in `images/live_run_map_markers/<pngIcon>`.
`HashRunPointTypes.fromKey(key)` resolves a key string to an enum value.

### Two mark schemes coexist in the `type` field

Production tracks contain **both** of the following (confirmed in live data — the
2026-06-20 LH3 run had `I-NNN.png`, `I-400.png::historic icehouse`, and `PHO::<uuid>`):

1. **`HashRunPointTypes` keys** (table above) — e.g. `CHK`, `DRK`, `CAU::watch the road`,
   and **`PHO::<photoBlobId>`** for a run-photo marker (`PHO` is a value in the enum;
   the suffix is the photo's blob id, rendered by `_buildPhotoMarker`).
2. **New-style `TrailSlot` icon filenames** — defined in
   `lib/data/models/trail_slot/trail_slot.dart`. Here the `type` is the **icon filename
   itself**, e.g. `I-001.png` (Check), `I-100.png` (Short Cut), `I-400.png` (Label,
   `action: addText`) → `I-400.png::historic icehouse`. `run_tracker_map_controller`
   detects these ("new-style slot icon — use asset filename directly") and loads
   `images/live_run_map_markers/<filename>` directly.

So a `type` parser must handle: `null` (a normal GPS point), a `HashRunPointTypes`
key (optionally `::label`), `PHO::<blobId>`, **or** an `I-NNN.png` slot icon
(optionally `::label`).

**`OIN` (On Inn) is a track terminator** — the controller stops drawing the polyline at
the first `OIN` point. Do not continue the track past it.

---

## GPS Sending — `LocationService`

A GetX service (`Get.find<LocationService>()`). Manages two modes:

**Idle mode** (always active):
- Distance filter: 250m, accuracy: `lowest`, background: off
- Updates `deviceInfo.deviceLat/Lon` and persisted prefs

**Run tracking mode** (when `joinRunTracking.value == true`):
Distance filter and accuracy depend on the user's **`trackingQuality`** pref
(`IntPrefsEnum.trackingQuality`, default Best), resolved by `_trackingDistanceFilter()`
and `_trackingAccuracy()` at the top of `location_service.dart`:

| `trackingQuality` | Mode | Distance | Accuracy | Android interval |
|---|---|---|---|---|
| 2 (default) | Best | 5m | `bestForNavigation` | 15s |
| 1 | Balanced | 10m | `high` | 1min |
| 0 | Power Saver | 20m | `medium` | 15min |

- Background: on. Points enqueued to `RunPointBuffer`, flushed every 60 seconds
- Android: foreground notification ("Tracking run in progress")
- iOS: `ActivityType.fitness`, `allowBackgroundLocationUpdates: true`

**To start tracking:**
```dart
locationService.eventId = run.event.eventId;
locationService.userId = getStringPref(StringPrefsEnum.userId);
locationService.joinRunTracking.value = true;
```

**`markPoint(HashRunPointTypes, {label})`** — one-shot high-accuracy position fetch,
enqueued with type string and immediately force-flushed.

**`isLocationFresh`** — `true` if last update was within 60 seconds. Note: this does
not auto-update reactively; the consuming widget needs a periodic trigger.

---

## GPS Sending — `RunPointBuffer`

Holds a `ListQueue<UserEventLocation>` and flushes in batches to StorePositions.

- `enqueue(point)` — adds to queue
- `flush()` — snapshots queue, POSTs batch, removes sent items on success
- Re-entrant safe: `_uploading` flag prevents concurrent flushes
- Retry: up to 5 attempts with exponential backoff (200ms base)
- Only retries on 429 or 5xx; other errors abandon the batch

`LocationService` calls `flush()` when:
1. 60 seconds have elapsed since last flush (`_lastFlushTime`)
2. `forceFlush: true` is passed to `updateDeviceLocation` (used by `markPoint`)
3. Tracking is stopped (final flush before teardown)

---

## GPS Receiving — `GetPositionsApi`

Thin HTTP wrapper in `lib/util/get_positions.dart`. POSTs to GetPositions endpoint.

```dart
final api = GetPositionsApi();
final payload = await api.fetchPositions(
  eventId: event.eventId,
  latestClientTimestampMs: _afterTimestampMs ?? '0000000000000000000',
);
_afterTimestampMs = payload.latestServerTimestampMs;
api.dispose(); // closes the underlying http.Client
```

The controller owns one persistent `GetPositionsApi` instance across the controller
lifecycle to avoid creating a new `http.Client` per poll.

---

## GPS Filtering — `TrackPointFilter`

Applied to incoming positions before rendering. Three-pass:
1. Drop points with `acc > 15m` or `timestampMs` within 1000ms of previous
2. Drop points implying velocity `> 5 m/s` (~18 km/h)
3. Interpolate between kept points to preserve track continuity

Default thresholds: `maxAccuracyMeters: 15`, `maxVelocityMetersPerSecond: 5`, `minTimeDeltaMs: 1000`.

---

## Map Display — `RunTrackerMapController`

GetX controller. Located at `lib/controllers/run_tracker_map_controller.dart`.

**Key state:**
| Field | Type | Purpose |
|-------|------|---------|
| `userPositions` | `RxList<UserTrack>` | All loaded/filtered tracks |
| `selectedRunnerId` | `RxnString` | Currently focused runner |
| `currentTimestampMs` | `RxnDouble` | Timeline scrub position |
| `minTimestampMs` / `maxTimestampMs` | `RxnDouble` | Timeline bounds |
| `isPlaying` | `RxBool` | Playback active |
| `userLogos` / `userNames` | `RxMap<String, String>` | Hydrated from local SQLite |
| `_trueNorthLock` | `RxBool` | Map rotation mode |

**Auto-update:** `Timer.periodic(_autoUpdateInterval)` every 15 seconds, incremental
via `_afterTimestampMs`. Stops when: playback active, widget not visible, event is stale.

**Stale event:** `event.eventStartDatetimeGmt + 24h`. No auto-update once stale.

**Lifecycle:** `WidgetsBindingObserver` pauses auto-update on app background; resumes
and immediately refreshes on foreground.

**Playback:** `AnimationController` drives `currentTimestampMs` across the timeline span.
Duration scales with map zoom: zoom ≤ 15 → 10s playback; zoom ≥ 22 → 480s.

**Camera:** follows `selectedRunnerId`'s interpolated position. Rotates map to runner
heading unless `trueNorthLock` is on.

**Runner markers:** profile photo in a grey square pin (`grey_square_pin.png`).
Highlight = glow; dim = 75% opacity when another runner is selected.

**Checkpoint markers:** PNG from `images/live_run_map_markers/`. LAB and CAU types
render a labelled badge above the icon. Scale varies with map zoom.

**`userLogos` / `userNames`** are hydrated lazily from `QueryUsers.querySingleUser(userId)`
(local SQLite, common domain). Lookup by `tableModel.hashersTableHelper` columns.

**Distance calculation:** uses `latlong2` `Distance` class between consecutive
interpolated track points. OIN terminates the measured track.

---

## Live Run Pages

| File | Purpose |
|------|---------|
| `live_run_shell.dart` | Tabbed shell wrapping the sub-pages |
| `live_run_general_page.dart` | Tracking toggle, elapsed time, distance, QR codes |
| `live_run_map_page.dart` | Map view backed by `RunTrackerMapController` |
| `live_run_chat_page.dart` | Run chat |
| `live_run_qr_page.dart` | QR code sharing |
| `live_run_service.dart` | `LiveRunService.ensure()` — ensures service is registered |

`LiveRunGeneralController` mirrors `LocationService.joinRunTracking` reactively.
It drives elapsed time via a 1-second `Timer` and accumulates distance from
successive `lastKnownPosition` updates using the `latlong2` `Distance` class.

---

## Things to Watch Out For

- **`pad19(epochMs)`** — all `ts` values sent to StorePositions must be 19-digit
  zero-padded. Use this helper, not raw `.toString()`.
- **`eventId` / `userId` must be set before enabling `joinRunTracking`** — the
  buffer initialises lazily on first location update and will throw if they're null.
- **Buffer eventId guard** — if `locationService.eventId` changes while tracking,
  the buffer detects the mismatch, flushes, disposes, and re-initialises on the
  next location update. Don't change eventId mid-track without expecting a gap.
- **`GetPositionsApi` uses POST, not GET** — despite the name. The endpoint accepts
  a JSON body.
- **`_afterTimestampMs` is a String, not an int** — the API returns it as a string
  and expects it back as a string. Don't convert to int.
- **`TrackPoint.timestampMs` is `int`; controller casts to `double`** — for timeline
  arithmetic. Keep this in mind if comparing timestamps across models.
- **OIN terminates track rendering** — `_isOnInn` check in `_interpolatedTrackPoints`
  caps the polyline at the first On Inn marker. The remaining positions are still
  in the model but won't be drawn.
- **Android interval is explicit per mode, not derived from distance** — `getLocSettings`
  takes an `androidInterval` named param (default 15min). Tracking tiers pass
  `_trackingAndroidInterval()` (Best 15s / Balanced 1min / Power Saver 15min); the pause
  monitor passes 15s for responsive auto-resume; the idle/stopped streams (250m / 100m)
  use the 15-minute default. Distance filter and interval are independent — set both
  deliberately when adding or retuning a tier. iOS has no interval (distance-filter only),
  so it's unaffected.
