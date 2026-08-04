# App TODO

Items flagged during development that need follow-up.

---

## Help system

- [ ] **Find a better way to provide in-app help** (if anyone ever uses it).
  Removed 2026-07-31 (2.15.23+1237): the app-bar (i) button, the FlippableBox
  flip-to-screenshots tutorial (Swiper over `images/tutorial/*.jpg`), the 22
  screenshot assets, and the `card_swiper` dependency — the screenshots drifted
  out of date as the UI evolved. If help returns, prefer something that can't
  rot: link out to per-topic pages on hashruns.org (maintained once, on the
  web), or short contextual text tooltips instead of full-screen screenshots.
  Note: the QR check-in page kept its own (i) — that one is a maintained text
  dialog, not a screenshot.

---

## Device test — 2.15.54+1268 run editor single save (shipped blind 2026-08-02)

Released with `flutter analyze` only. The Details, Address and Other tabs no
longer have their own save buttons — one anchored bar saves all three at once,
so **every save now writes every field on those three tabs**, not just the
tab you were on. That is the thing to watch. Screen: run admin → Edit run
details (`lib/pages/run_admin/edit_run_details.dart`).

Rollback: `git revert <this commit>` — one self-contained commit, no SP or
schema changes.

- [ ] **Open a run, change nothing, press nothing** — the bar is grey and
  unpressable. Type one character anywhere → it turns red immediately.
- [ ] **Edit the name on Details, the postcode on Address, the hares on Other,
  then save once.** All three must stick. This is the whole point of the change.
- [ ] **Other-tab switches survive a save from another tab.** Set "Promote this
  run" on, go to Details, save from there, reopen the run: it is still on.
  (Before this build those four switches were only read while the Other tab was
  on screen, so a save from elsewhere wrote the defaults over them.)
- [ ] **A toggle survives a tab round-trip** — flip a switch on Other, go to
  Details, come back to Other: still flipped, bar still red.
- [ ] **"Users can edit run history"** on a run that never had it set: save and
  check the run still behaves as inheriting, not as an explicit "no".
- [ ] **Back out with unsaved changes** → prompt offering Save / Discard.
  Discard leaves without writing; Save writes then leaves; the phone's back
  gesture behaves the same as the app-bar arrow.
- [ ] **Address auto-locate** now only offers after a save in which the address
  actually changed — confirm it fires when you edit the address, and does *not*
  fire when you only edit the run name.
- [ ] **New run wizard** — the bar reads Next on Details/Address, Finish on
  Other, and is always pressable (it is the wizard, not a dirty-save).
- [ ] **Map and Image tabs** keep their own buttons and show no bottom bar.

Also in this build (2.15.55+1269), the editor moved to GetX — `StatefulWidget`
→ `StatelessWidget` + `EditRunDetailsController`. Intended to be behaviour-
identical, so the checklist above covers it, plus:

- [ ] **Type in a field and watch the save button** — it must go red on the
  first character. Typing now only repaints the bar (`Obx`), so if the bar were
  wired wrong it would stay grey while you type.
- [ ] **Every tab still renders and its own buttons still work** — Map save,
  Map "no location", Image pick/crop/delete, Details "Copy data from external
  source". These were moved wholesale; a missed reference shows up as a blank
  tab or a dead button.
- [ ] **Open and close the editor ten times** — it should not get slower or
  heavier. `global: false` meant GetX never called `onClose()`; teardown is now
  wired explicitly through `dispose:`.
- [ ] **Back out mid-save** (press Save, then immediately back) — should not
  crash. Mutations after teardown are ignored.

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

---

## Device test — 2.15.64+1278 radar arrow + eased rotation (shipped 2026-08-04)

Released with `flutter analyze` only. Screens: live run → map → Radar.

- [ ] **North-locked radar**: turn on the spot — the centre blue wedge rotates
  with you. Unlock → wedge returns to the top and the whole rose turns instead.
- [ ] **Replay radar, north-locked**: wedge follows the focus runner's
  direction of travel at the scrub position.
- [ ] **Map rotation feel**: turns should start and settle softly (ease-in/out)
  rather than at constant speed; a heading reversal should wind down through
  zero, not snap. Tuning dial: `_rotationAccelDegPerSec2` (480).
- [ ] **Lock to North mid-turn**: map stops dead on north, no residual creep.
- [ ] **Wedge steppiness**: the wedge follows the raw compass in 2° ticks — if
  it looks steppy on device, route it through the same easing.

## PackTrack

- [x] **PackTrack: Label mark must be a permanent core mark** (James, 2026-07-11).
  Done — `_ensureLabelSlot` in `lib/data/models/trail_slot/trail_slot.dart`
  appends the canonical Label slot (addText) whenever a kennel's
  `trailSymbolsConfigJson` omits a text-capable Label, so hares always have a
  way to drop a labelled mark. Verified in code 2026-08-03.
- [ ] **PackTrack: should Caution also be guaranteed?** Follow-up to the item
  above — Caution (addText) is still omittable by a kennel's symbol config.
  Less critical than Label (a labelled Label mark can say "CAUTION"), so this
  is a taste call for James, not a bug.

---

## Background boot sync

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
