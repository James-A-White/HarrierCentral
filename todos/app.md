# App TODO

Items flagged during development that need follow-up.

---

## Post-3.0 — do AFTER the App Store release ships

Deliberately parked during the 3.0 stabilization push (2026-08). Ordered
roughly by recommended sequence.

### Toolchain (do first, as one dedicated session)

- [ ] **Flutter SDK 3.41.9 → 3.44.x** (latest stable as of 2026-07-23:
  3.44.8, Dart 3.12). Held back pre-release because an engine jump at the
  end of a stabilization phase invalidates device testing. Expect new lints
  and plugin re-resolution; full regression pass after.
- [ ] **Tier-2 dependency majors** (need pubspec edits; see commit
  `050825df` for the Tier-1 baseline): permission_handler 12→13,
  device_info_plus 12→13, share_plus 12→13, package_info_plus 9→10,
  sensors_plus 6→7 (tilt-scrub uses this — retest), map_launcher 4→6,
  keyboard_actions 4→5, calendar_date_picker2 2→3.
- [ ] **flutter_secure_storage 9→10 — handle separately.** This is the
  keychain holding the reset code + device credentials. After upgrading,
  retest the full self-healing recovery path on a real device: wipe app →
  reinstall → auto-reauthorize from keychain.
- [ ] **Firebase CocoaPods → Swift Package Manager.** Google stops
  publishing new Firebase SDK versions to CocoaPods after **October 2026**
  — this has a real deadline. Flutter supports SPM; migrate the iOS build
  and drop the pod pins.
- [ ] **Tier-3 stragglers**: latlong2 0.9→0.10 (pinned by flutter_map —
  underpins all PackTrack distance/bearing maths, take it only when
  flutter_map does), torch_light 1→2, discontinued transitive `js` package
  (disappears with future plugin majors).

### Features and debt

- [ ] **Background boot sync — wire the other tabs** (see section below;
  deferred since 2026-06-20).
- [ ] **Radar wedge easing**: under north-lock the centre wedge follows the
  raw compass in 2° ticks. Sub-pixel at current size, but if it reads
  steppy on device, route it through the same eased slew as the map
  rotation (2.15.64).
- [ ] **Kennel-admin follow guard** (from the sync-domains skill, "not yet
  implemented"): entering kennel admin for a kennel you don't follow should
  silently follow + force-replicate its run history first, so admin screens
  never work from partial common-domain data.
- [ ] **Test infrastructure**: the widget/integration test plan exists but
  is commented out (sqflite_ffi setup unresolved — the 2 standing analyze
  errors in test/). Decide to fix or delete.
- [ ] **In-app help replacement** (see Help system section below).

### Investigations still open

- [ ] **PackTrack mark-multiplication root cause**: the ×7 moving-track
  bursts from the 2026-06-20 LH3 run were never reproduced (stationary and
  simulator are clean; the batch-retry duplication class was fixed by the
  idempotent StorePositions RowKey, api 1.0.31). Needs the moving-taps
  device test on "Test this Mess" before it can be closed or chased.
- [ ] **Tuna's device RSS peak 892MB** during 1h51m of tracking
  (2026-08-04 log). No crash, but that's high-water for a background
  tracking session — worth a profiling pass if any tracking-session OOM
  reports appear in MetricKit.

### Waiting on HC5 retirement (~Dec 2026 – Mar 2027)

- [ ] Drop `EventStartDatetimeIndexed` + its trigger and the other HC5
  compatibility remnants (see memory: retire-hc5 cleanup list).

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

## Device test — lost compass own-track merge (2026-08-15, not yet released)

The "Where is the trail?" dialog now merges the server's view of your own
track with the locally-recorded session track (`LocationService._sessionTrack`)
in the own-track fallback, so a solo runner whose uploads are lagging — or who
has no connection at all — is still pointed back along their own trail.
Background: on the 2026-08-11 CH3 HAFTAS run the dialog showed "No live tracks
yet" even though James had ~18 min of points recorded (server-side fetch
returned empty at that moment; full track present on the server now).
Files: `lost_compass_dialog.dart`, `location_service.dart`.

- [ ] **Solo tracking, airplane mode**: start tracking, walk a few hundred
  metres, enable airplane mode, open I'm Lost → orange "Your track" arrow
  pointing back along the walked line (no network needed).
- [ ] **Solo tracking, normal signal**: I'm Lost within ~2 min of starting →
  new "You're the only one tracking…" message (not "No live tracks yet");
  after ~3+ min of movement → own-track arrow.
- [ ] **Not tracking, nobody else tracking**: message reads "No live tracks
  yet…" and now says "…tell the pack with the button below" (NOT "the pack
  has been notified") before announcing; after pressing Tell the pack, a
  refetch failure shows "the pack has been notified".
- [ ] **Different run guard**: track run A, stop, open I'm Lost on run B →
  run A's local session points must NOT be offered as run B's trail
  (sessionTrackFor eventId gate).

### Investigation still open (related)

- [ ] **Why did GetPositions return zero users at 19:53 on the HAFTAS run?**
  Server now holds the full 966-point track (19:32–20:18, all acc ≤ 21.8 m),
  stored under the lowercase internal event id; store/fetch ids are
  consistent across all call sites. Leading theory: upload batches were
  queued behind failed flushes and landed later. Confirm via device log
  harvest ("PackTrack: upload batch" breadcrumbs) or Azure Table server-side
  Timestamps (needs prod storage connection string). The local-track merge
  makes the compass immune to this either way.

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

## Device test — membership payments (Phase 2 shipped blind 2026-08-08)

Requires the SP deploy first (next Dance). Plan: docs/membership_payments_plan.md.

- [ ] **Check-in charge**: run admin → check in → hasher → "Charge annual
  membership" → fee pre-filled from kennel default, charge cash → snackbar
  shows the NEW expiry; run payment status is UNCHANGED (the run does not
  show as paid).
- [ ] **Run payment still isolated**: pay for the run AND charge membership
  on the same hasher — both recorded; cancelling one leaves the other.
- [ ] **Members list charge**: kennel admin → members → member popup →
  "Charge membership (paid)" → expiry updates in the list after charge; the
  member is NOT marked as attending/RSVP'd to the anchor run.
- [ ] **Credit neutrality**: charge membership with cash → member's Hash
  Credit balance unchanged. Charge with Hash Credit → balance drops by fee.
- [ ] **Renewal modes** (set per kennel in SQL until portal UI exists):
  rolling extends from expiry/today; fixed-year sets to period end (+
  refusal when period lapsed); lifetime shows ∞ and refuses re-charge.
- [ ] **Fee override**: edit the fee before charging → recorded amount and
  expiry both correct.
- [ ] **Unpaid grant path unchanged**: swipe / add-months actions still work
  and record NO payment.

## Device test — check-in membership/haberdashery buttons (2026-08-15, not yet released)

The check-in popup's two bottom actions are now real (white pill) buttons, and
the membership one is gated on the same 10%-of-period rule as the expiry badge
(`membershipStatusOf` passed into `PaymentSnackBar`). Label depends on history:
NULL expiry on the pack row = never a member.

- [ ] **Comfortable member** (>10% of period left, green star): NO membership
  button at all; "Sell haberdashery" still shows.
- [ ] **Lifetime member**: no membership button.
- [ ] **Member inside last 10%** (amber badge): button reads "Renew membership".
- [ ] **Lapsed member** (red badge, or lapsed long ago): "Renew membership".
- [ ] **Virgin / visitor / follower who never joined**: "Purchase membership".
- [ ] **Both buttons look pressable** — white pills, red text/icon, full width.
- [ ] **Multi-select**: neither button appears (unchanged rule).
- [ ] **Lifetime = expiry ≥ 2100 (new definition)**: set a test member's
  expiry to 2100-01-01 → green star, no membership button, and opening the
  charge sheet from the members list shows "Lifetime membership — there is
  nothing to charge" with NO fee field / method chips / charge button.

## Device test — On Inn confirmation (2026-08-15, not yet released)

The hare's On Inn slot no longer marks + stops silently — it always confirms
first (the red End Run button already did). Cancel = nothing recorded.

- [ ] **Tap On Inn while tracking** → "Mark On Inn & end run?" dialog appears
  BEFORE any flash or mark; Keep Tracking → no mark on the track (verify on
  the map), tracking still running.
- [ ] **Confirm** → flash, mark drops, tracking stops.
- [ ] **Other slots unaffected** — Check/Label etc. still mark immediately
  (label popup first where applicable).
- [ ] **End Run button** dialog now says the run continues if you restart
  tracking (stale "cannot be restarted" copy fixed).

## Device test — live viewer GPS boost (2026-08-15, not yet released)

Root cause from the LH3 #2846 run: geolocator caches the platform position
stream with the FIRST subscriber's settings and silently ignores later ones,
so the lost compass's "own best/0m stream" actually relayed the idle stream
(lowest accuracy, fix per 100 m) once tracking stopped. Fix: ref-counted
`requestPreciseStream()`/`releasePreciseStream()` on LocationService (the one
real stream), held by the PackTrack map controller and the lost compass; the
map's blue dot is now its own Obx layer driven by `lastKnownPosition` instead
of a value frozen into the last map rebuild.

- [ ] **Not tracking, map open**: walk with the live-run map up, tracking OFF
  → blue dot moves every few metres, not every 100 m.
- [ ] **Not tracking, I'm Lost open**: distance/bearing readout and steering
  slide update as you walk; arrows rotate with the compass.
- [ ] **Close both surfaces** → idle stream restored (watch battery/location
  indicator settle; breadcrumb "STOPPED (idle stream, preciseRequests=0)").
- [ ] **Tracking unaffected**: start tracking with map open, stop tracking —
  points still record at 5 m cadence while ON; dot stays live after stop.
- [ ] **Replay map (run detail, past run)** still renders; dot live there too.

## Device test — sync serializer / duplicate members fix (2026-08-16, not yet released)

All three sync services — user, kennel and event admin — are serialised
(`AsyncSerializer`) so overlapping syncs can no longer double-insert rows
(the duplicated kennel-members list). NOT self-healing — a device that
already has duplicates keeps them until that domain is wiped (different
kennel/event admin; common domain only via full re-sync). Few users affected
per James.

- [ ] **Race check**: enter kennel admin and immediately pull-to-refresh the
  members list several times while the entry sync is still running → no
  member appears twice afterwards (fresh device or after visiting another
  kennel's admin to force a wipe).
- [ ] **Check-in double-refresh**: open check-in, pull-to-refresh repeatedly
  during the initial load → no duplicate hashers in the pack list.
- [ ] **Serialised, not dropped**: switch from kennel A admin to kennel B
  admin quickly — B's members list is B's (wipe still happens, second sync
  ran after the first, nothing skipped).
- [ ] **Boot + tab switch** (user domain now guarded too): cold-boot as a
  returning user and immediately bounce between tabs while the background
  full sync runs — runs/kennels lists stay correct, no duplicate runs or
  kennels, boot completes normally ("Filling Your Mug" unaffected on a
  fresh install).

## Device test — membership expiry badge (2026-08-11, not yet released)

Check-in list star steps down around a membership's end: green star → amber
triangle inside the last 10% of the kennel's membership period (~36 days on
an annual kennel) → red alert triangle AFTER expiry, kept up for 20% of the
period (~73 days annual) as a "chase the renewal" flag, then no badge.
Screen: run admin → check in.

- [ ] **A comfortable member still shows the green star** and the name is still
  green + bold.
- [ ] **Set a test member's `MembershipExpirationDate` to ~30 days out** on a
  12-month kennel → amber triangle, no exclamation.
- [ ] **~10 days out** → still amber (there is no pre-expiry red any more).
- [ ] **Expired yesterday** → red alert triangle, name black (they are no
  longer a member — only the badge lingers).
- [ ] **Expired ~2 months ago** (inside 20% of an annual period) → still red.
- [ ] **Expired >73 days ago** on an annual kennel → no badge at all.
- [ ] **Lifetime member** (renewal mode 3, expiry 2999) → green star, never a
  warning.
- [ ] **Virgins / visitors** show no badge — they go through the other UNION
  branches, which carry a NULL expiry column.
- [ ] **Non-following past member on the attendee list** (third UNION branch)
  who lapsed recently → red badge shows there too (it reads hkm4's expiry).

## Device test — pending next build: steering slide + carousel guard (2026-08-05)

- [ ] **3.0 splash sequence** (server images, no app code): once
  `version_3.0_*.avif` images are uploaded to the `splash-sequences` blob
  container, any device upgrading across the 2.15→3.0 minor-version boundary
  shows them once via the existing MainNavigationPage splash system. Verify
  on the first 3.0.x build: sequence shows once, Done lands in the app,
  3.0.0→3.0.1 does NOT re-show.

- [ ] **Lost-compass steering slide** (live run → I'm Lost, within 40 m of a
  trail): the arrow sits off-centre toward the trail's side and glides to
  centre as you converge; turning on the spot moves it side to side; it should
  drift smoothly, never hop, and sit dead-still once you're on the line.
- [ ] **Follow-me caption** now reads "Follow the trail — it runs this way".
- [ ] **Carousel guard**: open the run-detail map tab AND the live-run map for
  the same run, leave both up 30+ s — no "Bad state" errors in the boot log,
  runner-picker still snaps correctly after closing one surface.

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

- [ ] **First On-Inn kills the whole drawn track — wrong for multi-lane
  haring** (from the LH3 #2846 live run, 2026-08-15). James (haring) dropped
  `GLY::oninn::A=endRun` at the end of one lane, re-declared `TRL::4` five
  seconds later and kept laying — but `_isOnInn` truncates the polyline at
  the FIRST terminator, so 20+ min of live trail was invisible to everyone
  until the mark was deleted server-side (DeletePositions). Options: only
  honour a terminator as track-end when it's the LAST point (or no points
  follow within N min); or scope terminators per TRL lane segment. Also
  consider: the live map's incremental poll never removes deleted points —
  a deleted OIN stays in the client model until the map is reopened.
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
- [x] **Background boot sync — concurrency** (deferred 2026-06-20, RESOLVED
  2026-08-16). The overlap could corrupt: two concurrent syncs both pass
  bulkUpdateDatabase's check-then-insert for the same new rows and
  double-insert them (no unique index stops it) — this is what duplicated the
  kennel members list. All three sync services (user/kennel/event) are now
  serialised via `AsyncSerializer`: a sync arriving mid-flight queues, runs
  after the first commits, and degrades to a cheap delta.
