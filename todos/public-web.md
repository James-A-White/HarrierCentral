# Public Web TODO

Items flagged during development that need follow-up.

---

- [ ] **PackTrack map may be querying with the wrong event id** (flagged 2026-06-20).
  PackTrack tracks in Azure Table Storage are keyed by the event's **internal
  `HC.Event.id`** (lowercased) — i.e. the mobile's `run.event.eventId` — **not**
  `PublicEventId`. Verified live: the 2026-06-20 LH3 run returned 3 trackers when
  queried by the internal id and **0 users** when queried by `PublicEventId`.
  If the public-web map passes `PublicEventId` to `GetPositions`, it shows an
  empty trail. **Action:** check what id `fetchPackTrack()` / `PackTrackMap`
  send (`public-web/lib/packtrack.ts`, `public-web/components/kennel/PackTrackMap.tsx`,
  `public-web/app/api/packtrack`); if it's the public id, pass the internal
  `HC.Event.id` lowercased instead. (Also confirm the `X-Api-Key` /
  `GET_POSITIONS_API_KEY` header is being sent — GetPositions now requires it.)
