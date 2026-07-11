# App TODO

Items flagged during development that need follow-up.

---

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
