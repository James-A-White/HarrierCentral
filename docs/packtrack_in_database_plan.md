# PackTrack in the database — plan

**Status: first half building (E3.F3.S7, 2026-09-10); second half has its column
(`TrackGzip VARBINARY(MAX) NULL`, added in the same ALTER, trigger-exempt) but no writer or reader yet.**
`TrackFirstPointAt` / `TrackLastPointAt` / `TrackPointCount` on `HC.HasherEventMap`,
written by StorePositions per batch (the updatedAt trigger ignores a write that changes only
these three columns — they are in no sync rowset yet), cleared by DeletePositions, backfilled by
`tools/backfill_hem_track_columns.sh`. James's rule: tracking starts by checking the
hasher in (RSVP Yes, At Hash) from the phone, so the row always exists.

Backlog: `E5.F6.S3` (the flag) and `E5.F6.S4` (the compressed copy).

Decided 2026-09-03/06 and moved here from `todos/app.md` on 2026-09-08 so the design
lives with the other plans rather than in a history archive.

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

- [ ] **Store a compressed copy of each hasher's track on the HEM record.** (column `TrackGzip` exists from 2026-09-10; encoder/writer/reader not built)
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
