# Verification Backlog — features shipped without a device pass

149 unverified checks across 20 features, migrated out of `todos/app.md` on
2026-09-08. Tracked at the backlog level as **E16.F4** (Verification debt).

**These are work items, not product stories.** They belong in the GitHub issue
tracker — one issue per feature, with these checks as its task list — so another
developer can pick one up. This file is the holding pen until that migration
happens; see `E16.F4.S2`.

Some of these features have since shipped and been superseded. Anything here
predating the 3.0 App Store release should be re-read before it is trusted: a
check written against build 1235 may no longer describe the screen.

---
## Device test — 3.0.1+1312 (chat bubbles, share sheet, tap targets, spinner)

Shipped 2026-08-28 to TestFlight + Play internal (staged; James sends
for review in the Console). SP
`hcapp_getEventBadgeCount` 1.1.0 is already live, so 1311 users also see
the new unread semantics via the old header badge.

- [ ] **First launch badge jump**: global chat badge and card bubbles light
  up for every chatty run (last 90 days / future) and kennel thread not yet
  opened — expected once. "Clear all chats" (Unseen Chats mode) zeroes
  everything AND it stays zero after a pull-to-refresh / relaunch (Mode 1
  now inserts caught-up rows for run threads too).
- [ ] **Bubble states**: run card + kennel card — red solid + count when
  unread; open the chat → grey solid instantly (no refetch wait); a run/
  kennel with no messages → grey outline. Post the first message in an
  empty thread → outline turns solid on return.
- [ ] **Notification gating**: set a kennel's bell to Off → its kennel bubble
  and its runs' bubbles never go red (still grey solid if messages exist);
  Silver Bell (muted) DOES still badge. Set a single run's bell to Off →
  only that run stops badging.
- [ ] **Bubble placement**: kennel card bubble above the three dots, no
  longer crowding the info column; run card same, old free-floating red
  header badge gone; blue admin pending-photos badge unchanged.
- [ ] **Share sheet** from all three places — run map button under the
  compass, full-screen map share, Run Tools "Share My Run": bottom sheet
  with Interactive map / Trail TV rows; each hands the right link + copy to
  the OS share sheet. Uncounted run → no sheet, straight to the map share
  (legacy #/RID link). Sheet title style looks right on the white sheet.
- [ ] **Tap targets**: tap ~10px outside the RSVP icon (run card) → RSVP
  popup, not run details; same outside the follow checkbox (kennel card) →
  follow popup, NOT the kennel page (was navigating away on a near-miss).
  Photo long-press still works away from the top-left corner.
- [ ] **Spinner**: loading gates show the spinner centred with the background
  filling the screen (not tucked top-left on white); items are diamonds.
- [ ] **Android review outcome**: Play Console — 1312 approved/rejected;
  if rejected, capture the reason here.

## Device test — 3.0.1+1293 (mark undo card, ~distance, dialogs, splash fix)

- [ ] **Mark a Check** → central card only (no bottom toast), Undo button on
  the card, stays up ~8s, tap-away dismisses early.
- [ ] **Let the card time out** → mark appears on a freshly opened map at the
  TAP position/time (commit is deferred but stamped at capture).
- [ ] **Tap Undo fast** (within ~1s, before the GPS fix lands) → cleanly
  discarded, nothing on the map.
- [ ] **Undo in airplane mode** → instant, no error (nothing was uploaded).
- [ ] **Power Saver user's distance** shows "~" prefix on the live run page;
  Best/Balanced users show plain number.
- [ ] **Reload Data** (support page) → after restart, "Data Reload Complete"
  dialog (not "Profile Load Successful").
- [ ] **3.0 splash**: James's cold relaunch shows the 7-frame welcome once;
  Done lands in the app; next boot does NOT re-show. (Fresh 2.x→3.0
  upgraders on 1293 see it on the upgrade boot itself — wipe-race fixed.)

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

## Device test — stop⇒On-Inn & auto-stop (2026-08-16, not yet released)

Plan: `docs/packtrack_auto_stop_plan.md`. Steps ①–③ work with the CURRENT
API; the two ④ items need the API deployed first (EndEventTracking +
StorePositions flag echo).

- [ ] **End Run dialog**: while tracking, tap End Run → "Are you On Inn?"
  with THREE buttons. "I'm On Inn" → On-Inn mark at your position, tracking
  stops, map shows the icon at your line's end. "I stopped early" → tracking
  stops, NO mark, trail just ends. "Keep Tracking" → nothing recorded.
- [ ] **Read rule — resume**: end with "I'm On Inn", restart tracking, walk
  on 3+ min → the old On-Inn icon disappears from the map (mobile AND
  public-web viewer) and the line draws through where it was.
- [ ] **Read rule — history**: replay an old run whose track ends with an
  On-Inn → icon and truncation unchanged (terminal On-Inns still honoured).
- [ ] **Auto-stop prompt**: two phones; phone A ends with "I'm On Inn";
  phone B (tracking >20 min) sits still within 30 m of A's mark for ~8 min →
  B gets "Are you On Inn?" with the countdown line. "Keep Tracking" →
  no re-prompt for 30 min.
- [ ] **Auto-stop drink-stop immunity**: both phones stationary together
  10+ min with NO On-Inn marks nearby → no prompt on either.
- [ ] **Auto-stop unanswered**: trigger the prompt with phone B locked in a
  pocket → after ~5 min tracking stops by itself and an On-Inn appears at
  B's position (breadcrumb "auto-stop — prompt unanswered").
- [ ] **④ Admin stop-everyone** (AFTER API deploy): admin opens the trim
  overlay → "Stop everyone's tracking" → confirm → a phone still tracking
  and MOVING stops within ~1 min with the "Run ended" snackbar; the trim
  overlay button flips to "Re-open tracking".
- [ ] **④ Straggler override** (AFTER API deploy): after stop-everyone, the
  stopped phone presses Start Run Tracking again → keeps tracking, is NOT
  stopped a second time.

## Device test — payment package (2026-08-16, not yet released)

Needs the SP deploy FIRST (processPayment 1.4.0 + util_ rewrite) — the
report-page items work against the current SP, the zero-price and combined
items do not. After the deploy, run
`EXEC HC6.util_rewriteZeroCashRunPaymentsAsFree @dryRun = 1` by hand, review
the per-kennel counts, then re-run with `@dryRun = 0` (James only).

- [ ] **Footer totals**: a run with cash membership + haberdashery charges →
  Run fees / Memberships / Haberdashery lines all show, sum to Total
  collected; the "<null> paid" line is GONE on events without extras; an
  event WITH extras still shows its extras line.
- [ ] **Header chips all-products**: cash chip count+amount includes
  membership/haberdashery cash rows and matches the rows shown when the
  chip's filter is tapped.
- [ ] **Unconfirmed card row**: black text, card icon with amber clock
  badge; badge disappears after swipe-to-confirm; "Card pending" footer
  line shows the amount + count and drops off once confirmed; Total
  collected excludes pending, includes it after confirm.
- [ ] **Zero-price ⇒ FREE** (after SP deploy): cash-tap a member on a
  free-for-members run → recorded as Free (FREE chip counts it, cash chip
  does not), payment detail shows the 'member' note.
- [ ] **Combined button** (after SP deploy): check-in → hasher → charge
  membership → sheet shows BOTH buttons; combined on a priced run charges
  membership + member-price run fee, checks them in, snackbar shows both;
  on a free-for-members run the button reads "check in (run free)" and the
  run leg records as Free('member'); run already paid → combined hidden;
  members-list sheet → single button only (and no attendance change).
- [ ] **Combined atomicity smoke**: airplane mode mid-charge → NOTHING
  recorded (no membership without run leg); retry succeeds cleanly.
- [ ] **Historical rewrite** (after util run): an old run whose members paid
  "cash £0" now shows them on the FREE chip with 'member' notes; cash chip
  = real money only.

## Device test — mark guards + zombie poll fix (2026-08-16, not yet released)

- [ ] **Slot cooldown**: while tracking, tap Check twice quickly → ONE mark,
  one flash; second tap does nothing at all. Tap Check then Whichy Way
  immediately → both marked (different slots never block).
- [ ] **Undo**: mark a Check → "Marked" snackbar with UNDO for ~8s → tap
  UNDO → "removed" snackbar; a map opened fresh afterwards does NOT show the
  mark. (An already-open map keeps it until full reload — expected.)
- [ ] **Undo offline**: airplane mode, mark a Check, UNDO within seconds →
  removed (came out of the queue); signal back → the mark never appears.
- [ ] **Lost re-announce window**: I'm Lost → Tell the pack → immediately
  announce again → the live map shows ONE lost badge (moved, not doubled);
  wait >2 min and announce again → a second badge is allowed.
- [ ] **Zombie poll fix**: open a live run's map, close it within ~1s (an
  in-flight load), keep the app open 2+ min → boot log shows NO
  "loadPositions … Null check operator" lines (previously every 15s).

## Device test — map pending-tail + freshness pill (2026-08-16, not yet released)

Live map now fuses the viewer's own track: solid = confirmed on server,
dotted = recorded locally but not yet uploaded (bridged so they join). Pill
under the Map/Radar switch: "Tracks updated just now / N min ago", amber
once ≥2 min behind. Both only on live-window events, never in replay.

- [ ] **Normal signal**: while tracking with the map open, a short dotted
  stub appears at your line's tip and retracts every ~30 s as batches land.
- [ ] **Airplane mode mid-run**: dotted tail grows continuously from where
  the solid line stops; pill counts up and turns amber at 2 min. Signal
  back → solid line catches up, dotted retracts, pill returns to "just now".
- [ ] **Playback/scrub**: no dotted tail while playing.
- [ ] **Replay of an old run**: no pill, no tail.
- [ ] **Another runner selected**: their line unchanged — the tail only ever
  draws for YOUR track.
- [ ] **Radar hidden without tracks** (same build): a FUTURE run's map tab
  shows no Map/Radar switch at all (previously tapping Radar blanked the
  screen); a live/past run WITH tracks still shows the switch and the radar
  works; a live run that starts with no trackers gains the switch when the
  first track arrives.
- [ ] **Fullscreen map safe-area (iPhone 17 / notched)**: Map/Radar switch,
  freshness pill and locate button sit BELOW the Dynamic Island on the
  fullscreen map; embedded maps (run detail tab, live run) unchanged (AppBar
  absorbs the inset there). Radar canvas's switch+legend column also clears
  the island.
- [ ] **Playhead clock is the selected runner's**: replay a run where the
  selected runner finished before the longest track — their elapsed time
  freezes at THEIR finish (e.g. Opee ~60 min) while the playhead continues
  to the last runner's end; selecting the longer runner shows their clock
  still counting; time before the selected runner's start shows 0:00.

## Device test — On Inn slot removed (2026-08-15, not yet released)

On Inn is no longer a placeable mark anywhere: mobile drops it from the
defaults and cleanses it out of stored kennel configs at parse (endRun
action, oninn glyph, or legacy "ON IN" text); the portal editor drops the
default, the glyph-picker entry and the End Run action option, and cleanses
old configs on load (next save persists the cleansed JSON). Ending a run is
the End Run button's job. Historical GLY::oninn marks still RENDER on maps
(mobile kTrailGlyphs keeps the glyph; public-web untouched).
NOTE for next portal release: `flutter build web` before the master merge.

- [ ] **Mobile marks grid** (kennel WITH a saved config that included On Inn,
  e.g. CH3/LH3): no On Inn tile; Label/Caution still present; End Run button
  still ends the run after confirming.
- [ ] **Mobile marks grid** (kennel with NO config → defaults): 11 tiles, no
  On Inn.
- [ ] **Portal trail symbols page** on a kennel whose config included On Inn:
  that slot row shows empty (not On Inn), glyph picker has no On Inn, action
  dropdown offers only None/Add Text; save → reload → still gone.
- [ ] **Old run replay**: a historical track with an On Inn mark still shows
  the On Inn icon and truncates there (rendering unchanged).
- [ ] **Slot infrastructure sweep (2nd pass, same day)**: TrailSlotAction is
  addText-only; legacy icon mappings (oninn.png / I-500..504) unmapped both
  ends; portal slot 4 is now a variable-purpose slot — open a kennel whose
  config predates the removal, confirm slot 4's purpose dropdown shows
  "-- none --" (stored 'On Inn' purpose coerced, not crashing) and an edit
  + save does not write 'On Inn'/'endRun' back into the JSON.

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

- [ ] **Splash sequence asset rule** (learned 2026-08-22, black-box bug): the
  loader layers `<root>_background.avif` UNDER the transparent numbered
  frames. OMIT the background blob to get the app's jungle wallpaper behind
  the frames (what every `version_*` set before 3.0 did — the loader 404s
  and falls through); only upload one if it is genuine full-screen art
  (like `CountryStats_background`). The 3.0 set shipped an opaque
  near-black `_background` → black box on every frame, both platforms;
  fixed by deleting the blob (backup: `backup_version_3.0_background.avif`).
  Frame alpha + flutter_avif are healthy — don't debug those first.

- [ ] **3.0 splash sequence** (server images, no app code): the
  `version_3.0_*.avif` images (7 frames + background) ARE uploaded to the
  `splash-sequences` blob container (2026-08-07 — list the FULL container
  before concluding otherwise). The sequence did NOT show on James's 2.x→3.0
  upgrade because the DB-upgrade wipe erased `harrierCentralVersion` before
  the MainNavigationPage check ('' == '' → skip); fixed on dev `fbb5cc80`
  (re-stamp after wipe), in the next build. Still to verify on device:
  sequence shows once (a cold relaunch shows it even without the fix — the
  next boot re-stamps), Done lands in the app, 3.0.0→3.0.1 does NOT re-show.

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

## Device test — payment outbox + idempotent payments (2026-08-26, not yet released)

⚠️ DEPLOY ORDER: processPayment 1.5.0 (SP) must be deployed BEFORE any app
build carrying the outbox ships — the new build always sends
@clientPaymentId, which the 1.4.0 SP does not accept.

Every single-payment path (check-in charge, scanner, membership,
haberdashery, report corrections/confirms/cancels) now goes through
PaymentOutboxService: captured to persistent storage BEFORE the first send,
retried with the SAME clientPaymentId (= server Payment.id) until the server
acknowledges. Retries fire on app resume, connectivity return, and a 60s
sweep; queued captures survive app restarts. Server rejections are NOT
retried (dead-lettered with a loud snackbar). Bulk payment
(processBulkPayment) is NOT yet idempotent/queued — follow-up.

- [ ] **Normal charge online**: cash-tap at check-in behaves exactly as
  before (snackbar, list updates, report correct) — one Payment row.
- [ ] **Airplane mode charge**: enable airplane mode, cash-tap a hasher →
  "saved on this phone / will send automatically" snackbar; signal back →
  within ~60s (or on app resume) "Payment sent" snackbar; list/report then
  show the payment; server has ONE row with the client-generated id.
- [ ] **Kill mid-queue**: charge in airplane mode, force-kill the app,
  relaunch with signal → boot log shows "loaded 1 queued payment(s)";
  payment arrives without touching any payment UI.
- [ ] **Replay safety (the original bug)**: with a proxy/timeout or by
  toggling airplane mode DURING the request (send happens, response lost) →
  outbox keeps it queued, retry gets acknowledged via the idempotent replay
  path → exactly ONE payment row on the server, no duplicate.
- [ ] **Double-tap safety**: rapid double charge attempts on the same hasher
  → still exactly one live payment (existing UPDLOCK + new PK id).
- [ ] **Membership offline**: membership charge in airplane mode → queued
  snackbar, sheet closes; when it lands, expiry advances (verify in members
  list after sync).
- [ ] **Server rejection not retried**: force a validation failure (e.g.
  charge on a kennel where perms were revoked) → red "Payment NOT recorded"
  snackbar, outbox empty afterwards, no repeating dialogs.
- [ ] **Replayed PaidDate**: an offline charge delivered later records
  PaidDate ≈ when the admin tapped (capture time), not delivery time.

Round 2 (2026-08-27, from James's airplane-mode test of 1310 — offline
access + outbox visibility + faster reconnect):

- [ ] **Offline run-admin entry (cached run)**: visit run admin online once,
  go offline, re-enter → page renders from cache with the amber "Offline —
  showing saved data" note; Manual check-in opens and shows the pack list.
- [ ] **Offline run-admin entry (uncached run)**: offline, open admin for a
  run never visited → "not saved on this phone yet" message + Try again
  (NOT the old blanket "requires Internet" gate).
- [ ] **Queued banner**: charge in airplane mode → amber "1 payment saved on
  this phone, waiting to send" banner on check-in (bottom), payment report
  (top) and run admin; VIEW opens the queue sheet with the entry (label,
  time, amount, attempts).
- [ ] **Queue sheet actions**: "Send now" offline → honest snackbar; online
  → queue drains, sheet empties live. Discard → confirmation dialog warns
  money will not be recorded; entry removed; breadcrumb logged.
- [ ] **Reconnect speed**: airplane off with queued payments → they deliver
  within ~10 s (connectivity-edge poll) WITHOUT app restart or resume;
  "Payment sent" snackbars appear.
- [ ] **Live row refresh**: stay on the check-in page while a queued payment
  delivers → the hasher's row flips to paid by itself (paymentDelivered
  DataChange); same on an open payment report (rows + totals).
- [ ] **Restart-proof triggers**: queue a payment, log out/in or Reload Data
  (in-app restart), reconnect → still delivers (poll-based trigger fix for
  the recreated NetworkService).
- [ ] **Offline check-in list populated on entry** (fix for James's
  2026-08-28 screenshot, post-1311): airplane mode → run admin → Manual
  check in → the pack list shows immediately (previously blank until a
  filter was toggled); counters populated; pull-to-refresh offline
  re-reads local tables without wiping the list.
- [ ] **Per-row queued icon**: charge a hasher in airplane mode → THEIR row's
  payment circle immediately shows the payment-method icon at half opacity
  with a small amber clock badge (not the red $, not blank); other rows
  unchanged. When the queue delivers, the badge drops and the icon goes
  solid green by itself. Kill + relaunch offline → queued style still shows
  (outbox reloaded from disk).

## Device test — PackTrack runner list canvas (2026-08-26, not yet released)

Third canvas on the PackTrack screen: Map / Radar / **List** segmented switch.
The list is a sortable leaderboard (longest trail first, or closest to me)
sharing the same timeline/playback/filters as the other two — scrubbing the
replay reorders rows live. Runner dots use the per-runner track palette;
the radar blips were ALSO recoloured from uniform yellow to the same
per-runner palette (lost stays orange, stale = faded own colour) so map,
radar and list all agree. Shipped with `flutter analyze` only.

- [ ] **Switch shows three segments** on a run with tracks (map, radar, list);
  still hidden entirely on a future/untracked run.
- [ ] **List rows**: rank number, coloured dot matching that runner's map
  trail colour, name ("(you)" suffix on own row), trail distance in mi/km,
  "N m from you" second line (own row reads "that's you").
- [ ] **Sort pills**: "Longest trail" default; "Closest to me" reorders by
  separation; without a GPS fix it shows the explanatory snackbar.
- [ ] **Replay scrub reorders**: scrub the timeline in list view — distances
  and ranking change with the playhead.
- [ ] **Tap a row** → runner selected (bold + highlight); switch to Map →
  same runner selected/highlighted there, carousel synced.
- [ ] **Back gesture from list** returns to Map (not out of the live run);
  fullscreen button and north-lock hidden while the list shows.
- [ ] **Radar recolour**: blips now use per-runner colours with a white ring —
  confirm a lost runner still reads hard orange, and colours match the map
  trails for the same runners.
- [ ] **Live standalone radar page** (live_run_rose_page): same per-runner
  colours there too.
