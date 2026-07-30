# App TODO

Items flagged during development that need follow-up.

---

## Device test — 2.15.21+1235 photo review (shipped blind 2026-07-30)

Released to TestFlight with `flutter analyze` only — no simulator or device run.
Covers a rewritten action bar on **both** review surfaces, a new filter path
through `visiblePhotos`, and the selection-reset logic. Screen: kennel admin →
run → Review Photos (`lib/pages/kennel_admin/hash_flash_approval_page.dart`).

Rollback if needed: `git revert 8214cec7` — one self-contained commit, no SP or
schema changes, so there is no database state to unwind.

- [ ] **Cover Photo on the grid** — greyed at 0 selected, enabled at exactly 1,
  greyed again at 2+. (`singleTargetOnly`: action 6 demotes any previous cover,
  so a multi-selection would leave an arbitrary winner.)
- [ ] **Featured badge in the carousel** — a Featured photo must read "Featured",
  not "Public". This is the stale status→action mapping the release fixes; it is
  the one item here that is a *regression check on a claimed fix*.
- [ ] **Count chips filter** — tap a chip (Members, Public, Featured, Cover,
  Deleted): photos below narrow to that tag, chip gets a white outline, the rest
  fade to 40%. Tap again to clear.
- [ ] **Zero-count chips are inert** — "0 Members" should not respond to a tap.
- [ ] **Pending chip switches tab** rather than setting a rung filter.
- [ ] **Filter + Select all compose** — filter to one tag, Select all, apply an
  action: it must only touch the visible photos.
- [ ] **Filter change clears selection** — select some photos, change the filter,
  confirm "0 selected". (`bulkAction` reads `selectedIds` directly, so a stale
  selection would silently action photos that are no longer on screen.)
- [ ] **Empty-because-filtered state** — filter to a tag then action the last
  photo out of it: expect "No <tag> photos left" + a working **Show all photos**
  button, not "No reviewed photos yet".
- [ ] **Both tab pills clear an active filter**, including the tab already selected.
- [ ] **Select all / Clear** render as two visibly separate red pills.
- [ ] **Single-photo bar parity** — same labels, colours, icons and order as the
  grid; current status highlighted, others dimmed.

- [ ] **PackTrack: Label mark must be a permanent core mark** (James, 2026-07-11).
  The Label mark (`I-400.png`, addText action) is currently part of the kennel's
  configurable symbol set — a kennel that omits it leaves its hares with NO way
  to drop a labelled mark on trail (hit live on a run). Make Label (and likely
  Caution/warning too, per the "only symbols that should have labels" rule)
  always available regardless of the kennel's chosen trail-symbol config.

- [ ] **Background boot sync — wire the other tabs** (deferred 2026-06-20). Cold
  boot now renders the runs page immediately for returning users and runs the
  full sync in the background (`_runBackgroundFullSyncAndRefresh`). Only the runs
  list refreshes when the sync lands; History / Kennels / Songs / Map still show
  last-session data until next visited. Follow-up: have them refresh via
  `DataChangeService` on background-sync completion (the "whole app" option).
- [ ] **Background boot sync — concurrency** (deferred 2026-06-20). If the user
  switches tabs during the boot background sync, the runs controller's
  `triggerBackgroundSync` can run a second sync concurrently with the boot full
  sync. Watermark-based so wasteful, not corrupting — coordinate the two if it
  proves noticeable.
