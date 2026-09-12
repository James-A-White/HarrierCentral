# PackTrack on the device — study and recommendation

**Status: recommendation, 2026-09-12. Nothing built. James asked for a study of
keeping each hasher's own tracks on their phone (gzipped, on the attendance
row), a per-run count of tracks on the event row, and a map of every run they
have done in an area, coloured by kennel pin colour — all without a round trip.**

Two objectives (James): keep the app from being chatty, and make the app feel
the same with and without a network.

---

## What is true today

| Fact | Measured 2026-09-12 |
|---|---|
| Archived tracks in `HasherEventMap.TrackGzip` | 743 tracks, 52 runners, 494 runs |
| Size per track | average 4.1 KB, largest 47 KB, 1,357 points on average |
| Everything archived, in total | 2.9 MB |
| Heaviest runners | Kilty as Charged 234 tracks / 877 KB · Tuna Melt 204 / 625 KB · Opee 191 / 842 KB |
| Opee's whole attendance history | 748 HEM rows, of which 191 carry a track |
| What the phone holds now | No track columns at all. `TrackGzip` is server-only, read by GetPositions for replay |
| How a card knows a run has a track | `hcapp_getRunActivity`, batched per screenful (80 ids per call, 300 ms debounce), cached for the session |
| HEM sync page | 250 rows, ordered by `updatedAt`, one rowset per page |
| Track columns and the trigger | A write that touches only `TrackFirstPointAt` / `TrackLastPointAt` / `TrackPointCount` / `TrackGzip` does **not** stamp `updatedAt` (James, 2026-09-10) — so today an archive never causes a sync |
| Shim serialisation | `System.Text.Json` on a `byte[]` gives a base64 string; the app's sync writer stores whatever arrives, so the blob lands in SQLite as TEXT, 33 % larger than the bytes |
| The map stack | `flutter_map` 8 with `PolylineLayer`; the Run Locations map already draws every run as a pin in the kennel's pin colour (`RunAndKennelMapController`, `images/map_pins/<colour>/…`) |

The numbers settle the memory question. A heavy runner's whole history of
tracks is under 1 MB compressed, about 1.2 MB as base64 text in SQLite. The
local database on the beta phones is 7 to 23 MB today. Storing tracks adds
roughly a tenth to that, once, and grows by 4 KB per run tracked.

---

## Recommendation

Do it, in the shape James described, with four decisions made deliberately.

### 1. Carry the track on the user's own HEM rowset only

Add `trackGzip` (and `trackPointCount`, `trackFirstPointAt`, `trackLastPointAt`)
to the **user** sync's HEM rowset — the rowset that holds the hasher's own
attendance history. Not the kennel-admin or event-admin HEM rowsets: an admin
opening a run with 20 runners does not need 20 tracks pushed to their phone,
and those domains are wiped on every admin entry anyway.

Cost: a hasher with 200 tracked runs receives about 1.2 MB once, then 5 KB per
run they track. A hasher who never tracks receives nothing new. The 250-row
page holds at most 250 tracks, about 1.4 MB, on the first sync of a heavy
runner; every later page is a delta of a few rows.

### 2. Let the nightly archive announce itself

The trigger exemption exists so that live batches, which null and rewrite the
track columns once a minute, do not re-sync the row. That must stay. But the
phone can only receive the archive if `updatedAt` moves, so the **nightly
archive's UPDATE sets `updatedAt` explicitly** (the trigger already yields when
the writer stamps it: `AND NOT UPDATE(updatedAt)`). The row then re-syncs
exactly once per tracked run, the morning after, with its final track.

Nothing else changes: StorePositions and DeletePositions keep their exemption,
so tracking a run costs the sync nothing until the archive is final. A
re-tracked run (resume, or a later import replacing the track) is re-archived
the next night and re-syncs once more.

This also gives the app a clean rule: a HEM row with `trackPointCount > 0` and
no `trackGzip` is "tracked, archive not yet delivered"; the card can show the
icon from the count and the map draws the trail when the bytes arrive.

### 3. Put the runner count on the event row, updated only when it changes

Add `HC.Event.TrackRunnerCount SMALLINT NOT NULL DEFAULT 0`, carried by the
existing events rowsets (user sync narrow and force-replicate, event-admin
sync). `HC.Event` is a synced table: the ALTER is James's to run with
`trgUpdateModifiedOnDateForEvent` disabled.

Maintain it from the three places that change who has a track — PositionWriter
(first batch for a runner), the nightly archive (reconciles counts, creates
attendance rows), DeletePositions — with one statement:

```sql
UPDATE e SET TrackRunnerCount = x.n
FROM HC.Event e
CROSS APPLY (SELECT COUNT(*) AS n FROM HC.HasherEventMap h
             WHERE h.EventId = e.id AND h.removed = 0 AND h.TrackPointCount > 0) x
WHERE e.id = @eventId AND e.TrackRunnerCount <> x.n;
```

The `<>` guard matters. During a live run every runner's first batch changes
the count once; every later batch does not, so the event row re-syncs to the
kennel's followers at most once per runner per run, not once per minute. The
event trigger stamps `updatedAt` on any column change, which is what we want
here.

With the count on the event row, `hcapp_getRunActivity` no longer needs
`hasTrack` and `runnerCount`. It still answers photos, chat and down-downs;
see "Going further" for moving those too.

### 4. Decode on the phone, index the bounds, draw simplified

A Dart port of `TrackArchiveCodec` is about sixty lines: base64 decode, gunzip
(`dart:io` `GZipCodec`), then varint and zigzag deltas of timestamp, lat × 1e5,
lng × 1e5, altitude × 10, accuracy × 10, and a length-prefixed type string. It
must be a faithful port of the C# and tested against real blobs pulled from
production, the way the reader was verified point-for-point on 2026-09-10.

Two local-only columns on the phone's HEM table, filled when a row's
`trackGzip` first arrives and never synced: `trackBounds` (min/max lat/lng as
four REALs) and `trackSimplified` (a Douglas-Peucker reduction to about 150
points, stored as a small BLOB). The map then does no decoding at all:

- the "trails in view" query is a bounding-box `WHERE` on the four columns,
  joined to the event and kennel for the pin colour;
- each hit draws its simplified polyline in the kennel's colour;
- tapping a trail opens the run; the full track decodes only then.

The map is a layer on the existing Run Locations map — "Show my trails" —
rather than a new page, so the pins, filters and search stay where they are.
Fifty simplified trails on screen is nothing for `flutter_map`; two hundred
is fine; the bounds query keeps it there however long the history gets.

---

## What this gives each objective

**Less chatty.** Opening the history, scrolling past runs, or looking at the
map makes no calls: the icon comes from the event row, the trail from the HEM
row. The per-screenful `getRunActivity` call shrinks to photos, chat and
down-downs, and disappears entirely if those counts also move to the event row.

**Same with and without a network.** A hasher's own runs, their trail on each,
and the trails map work identically offline. Two things still need the server
and should say so plainly when offline: replaying *other* runners on a run
(GetPositions serves the pack, and their tracks are not on your phone), and
the live map during a run. That is the honest boundary of "almost identical".

---

## Costs and risks, stated

- **Two ALTERs on synced tables** (`HC.Event`, and the phone's HEM table gets
  new columns — the server HEM columns already exist). James runs the Event
  ALTER with the trigger disabled. The app needs a `DB_VERSION` migration that
  adds the columns; a full reload is not required because the next user sync
  fills them.
- **One-time re-sync for tracked rows.** Setting `updatedAt` on archive means
  every archived row re-syncs once after deploy — 743 rows across 52 users,
  2.9 MB in total. Trivial, but it happens on first boot after the update;
  it should not be the same release as anything else heavy.
- **The first sync of a new install** for a heavy runner is about 1.2 MB
  larger. On the boot-sync deferral path (returning users skip the mug) this
  is invisible; on a fresh install it is one extra page.
- **Codec drift.** The Dart decoder and the C# encoder must agree forever.
  Version byte is already in the format; the Dart side must refuse unknown
  versions and fall back to the server for that run, never draw garbage.
- **Removed attendees.** A removed HEM row's track is not archived and should
  not sync; the rowset already filters `removed` the way the app expects.
- **Kennel-admin domains** must not carry the blob (decision 1) or an admin's
  phone would receive every runner's track for every run they open.

## Going further (not in this recommendation)

- Move `PhotoCount`, `MessageCount`, `DownDownCount` to the event row the same
  way (guarded updates from the SPs that write those tables). Then
  `getRunActivity` goes away and the card is fully offline. Photo visibility is
  viewer-dependent today (approval flow), so the count would be "approved
  photos", which is the number the card shows anyway.
- Other runners' tracks on runs you attended, for offline replay of the pack:
  the event-admin HEM rowset could carry them for one run at a time, on demand.
  Not by default — that is the chatty path this plan removes.

## Order of work

1. Server: user-sync HEM rowset gains the four track columns; nightly archive
   stamps `updatedAt`; `TrackRunnerCount` column (ALTER, James), maintained by
   PositionWriter, the archive and DeletePositions; events rowsets carry it.
2. App: migration (HEM: `trackGzip`, `trackPointCount`, first/last,
   `trackBounds`, `trackSimplified`; events: `trackRunnerCount`); Dart codec
   with a test against production blobs; fill bounds and simplified on sync.
3. App: run card reads the event row instead of `getRunActivity` for the
   track icon and count; run detail draws your own trail from the row.
4. App: "Show my trails" layer on the Run Locations map.
5. Deploy order: ALTER → SPs → API → app. The server columns may arrive
   before the app has its migration: the sync writer's `normalizeMap` keeps
   only the fields the local table has and logs the rest, so old apps ignore
   them (verified in `core_mobile/database/base_service.dart`).
