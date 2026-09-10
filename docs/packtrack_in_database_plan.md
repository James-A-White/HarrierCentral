# PackTrack in the database — plan

**Status: first half building (E3.F3.S7, 2026-09-10); second half's WRITER built 2026-09-10
(not yet deployed), no reader yet.**

Writer, as built (E5.F6.S4) — **the phone is not involved** (James, 2026-09-10: nothing reads
the archive yet, so there is no reason for it to exist sooner than the next night, and a
server job covers hashers who never open the app):
- **`ArchiveTracksNightly`** Azure Function, 03:30 UTC, after MemberStandingSweep. Shared
  `TrackArchiver` builds the worklist and archives each pair: reads the runner's rows from
  `EventPositions` (partition = event, filter UserId), sorts by caller timestamp, encodes
  (`TrackArchiveCodec`: version byte, varint count, per point zigzag-varint deltas of
  ts / lat×1e5 / lng×1e5 / alt×10 / acc×10, then length-prefixed UTF-8 type), gzips, and
  UPDATEs `TrackGzip`, reconciles `TrackPointCount` to the true row count and fills
  first/last where the per-batch writes never set them. Measured on a synthetic 3,000-point
  Best-tier track: 16.6 KB, 5.5 B/point, 5.8% of the GetPositions JSON (gzipped JSON would
  be 42 KB). At that rate 10,000 tracked runs ≈ 170 MB.
- **Worklist:** (1) `HasherEventMap` rows with `TrackPointCount > 0 AND TrackGzip IS NULL`;
  (2) for `HC.EventTrack` runs with a last point in the past 7 days, every UserId in the
  run's partition whose attendance row has no archive — the batch-before-check-in case
  that leaves the count NULL. Both need 30 minutes' quiet. **Work goes run by run**: one
  partition read per run, split by runner in memory, every runner on it archived from that
  read (a per-runner filtered query would scan the same partition once per runner). Newest
  first, under an **8-minute budget** — the API is on the Consumption plan (Y1), so
  `host.json` now sets `functionTimeout` 00:10:00 (the plan maximum) and the pass stops
  starting runs at 8 min and reports what it left; the next night takes the rest.
- **Staleness:** `StorePositions` sets `TrackGzip = NULL` on every accepted batch;
  `DeletePositions` nulls it on any delete (and clears the summary when the last point
  goes). So the archive is never older than the newest point; a resumed run is re-archived
  the next night.
- **On demand:** `ArchiveTrack` HTTP function (X-Api-Key, empty body) runs the same sweep and
  returns the tally; `tools/archive_all_tracks.sh` wraps it and prints the SQL totals. Use it
  for the first pass over the history after deploy.
- **No row, no problem:** a runner found in a partition with no attendance row gets one via
  `HC6.nonApi_ensureTrackAttendance` (At Hash, RSVP Yes, `nonApi_updateRunCountsByUser` —
  the same row `hcapp_setEventAttendence` writes), then is archived. James, 2026-09-10: every
  runner who has a track has an attendance row. The nightly only looks at the last 7 days of
  runs for this; the script passes `allRuns: true` so the history is walked once.
  **Deploy the SP before the API** or the ensure call fails (warning + skip, retried nightly).
- **Not covered:** points still in a phone's outbox only go out when the same run is tracked again
  (`restorePending` is per-buffer); when they do, StorePositions drops the archive and the
  next night rebuilds it with the tail.

---

Today the ONLY record that a run was tracked is Azure Table Storage. Answering
"which runs used PackTrack" (asked 2026-09-03) needs a partition-key walk of
`EventPositions` plus a join back to `HC.Event` by hand — there is no query
that answers it, and no reporting, no adoption metric and no admin view can
ask it either.

- [x] **Mark the HEM record when a hasher tracks a run.** (E3.F3.S7 — building) A flag (or a first/
      last-point timestamp pair) on `HC.HasherEventMap` set when
      StorePositions accepts that hasher's first point for the event. Cheap:
      one UPDATE per hasher per run, not per point. Makes "who tracked what"
      a normal SQL question and gives run/kennel/hasher adoption reporting for
      free.
      - Column is on a **synced** table, so the ALTER needs the `UpdatedAt`
        trigger disabled first (see CLAUDE.md) or every client re-syncs every
        HEM row.
      - Write it from `StorePositions`, not the app: the app can be killed
        mid-run, and a phone that never regains signal would never report.
      - Backfill from the 141 tracked events already in Table Storage.

- [x] **Store a compressed copy of each hasher's track on the HEM record.** (nightly writer built 2026-09-10 — see status above; reader still to do)
      So the track survives independently of Table Storage, and a run's
      history can be read without a second data store.
      - Write it ONCE, when tracking ends (the On Inn mark, the auto-stop, or
        a sweep over finished runs) — never per batch. The live path stays
        Table Storage; this is the archive.
      - Encode compactly rather than storing the JSON: delta-encoded
        lat/lng/time (the app already thins points) then gzip, into a
        `VARBINARY(MAX)`. A 3,000-point run is ~100 KB of JSON and roughly a
        tenth of that encoded — but **measure before choosing the column**,
        because the DB has a 10 GB cap and this grows per hasher per run,
        which is exactly the shape that filled the log tables.
      - Decide what wins if the two disagree. Suggest: Table Storage is
        authoritative while the run is live and for the trim window; the HEM
        copy is authoritative once written, and is what an export or a
        long-past replay reads.
      - Keep marks (`CHK`, `PHO::`, `OIN`, …) in the encoded form — a track
        without its marks cannot redraw the run.

---

## Why it has not been built

Both halves touch a synced table, so the `ALTER` needs the `UpdatedAt` trigger
disabled first or every client re-syncs every HEM row. That makes it a deliberate,
scheduled change rather than something to slip into an evening — and it has been
queued behind the 3.0 stabilisation and the payments track ever since.

## What it unblocks

- "Which runs used PackTrack" becomes a normal SQL question — no partition-key walk.
- Adoption reporting per run, kennel and hasher.
- The PackTrack indicator on the past run card (see the run-card mockup): it cannot
  be drawn until `E5.F6.S3` lands, because nothing in SQL knows a run was tracked.
- A track that survives independently of Table Storage.
