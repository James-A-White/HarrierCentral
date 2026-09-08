# Archive — component to-do files (retired 2026-09-08)

Superseded by `docs/backlog.md`. Kept because a large part of these files is not
task tracking at all — it is the reasoning behind decisions, root-cause analyses,
and the record of what shipped when. That has ongoing value and is not
reproducible from git history alone.

**Do not add to this file.** New work goes in the backlog; bugs and tasks go in
GitHub Issues. The device-test checklists that used to live here have moved to
`docs/verification-backlog.md`.

---

# app.md

# App TODO

Items flagged during development that need follow-up.

## 🚀 SHIPPED 2026-09-07 — "Dance baby!"

- **SPs** 152 deployed, 0 failed (twice: before and after the addEditUser guard).
- **API 1.0.36+34** live — `func azure functionapp publish harriercentralpublicapi`.
  Note CLAUDE.md says `func publish …`, which is not a real command; the memory
  `reference_api_deploy` has the right one.
- **mobile 3.0.10+1325** → iOS TestFlight, Delivery UUID
  `eacb2b73-aebc-421c-b8cf-ee41ed96b403`. 41 frameworks verified `platform IOS`
  before upload (the 3.0.9 409 check).
- Portal and public-web unchanged, not deployed.

### Signup was broken in FIVE places, all now fixed and verified end to end
A brand-new user could not create an account at all. Admin-added members were
fine, which is why signups kept appearing daily and it looked like it worked.

1. The "Get Started!" button sat off-screen on Android (body sized to the whole
   screen, not the Scaffold's box).
2. The button vanished for good after any failure (`isLoading` never reset).
3. The app sent the STRING "null" for latitude/longitude.
4. The app sent an EMPTY STRING deviceId; the SP's new-user mode needs NULL.
5. The shim's pre-auth allow-list did not include `addEditUser`, so a call with
   no deviceId was refused outright.
Plus: the app read the SUCCESS ENVELOPE (rowset 0) as the new profile, so the
account was created while the app sat silently on the form.

Verified on a Galaxy S22 emulator, Android 16: form → account created → device
authorised → Choose Profile Image → welcome deck → Hash Runs, and a second
launch goes straight to Hash Runs with no promos.

- [x] Four stale splash sequences (`CountryStats`, `zombie`, `BMPH3_2000`,
      `city_away_weekend`) set `Removed = 1`. They had run since 2024 with an
      end date of 2040 and were still being served daily. Restore SQL is in
      `HC.SplashSequence` — set `Removed = 0` on the id you want back.
- [x] Six `+hctest` accounts created while debugging are `Removed = 1`.

### Still open from this session
- [ ] **The "Welcome to Harrier Central 3.0" deck shows to brand-new users.**
      Someone who has never had the app is told about "the biggest update
      ever". It is deliberate (a 2026-08 fix made it show for new accounts) but
      it reads wrong for a first-time user — worth a decision.
- [ ] **A dialog contradicts itself**: title "We could not send your code" over
      body "An invite code has been sent to your email address."
- [ ] **Emulator clock drift breaks auth silently.** 196s of drift made every
      token fail `CHECK_ACCESS_TOKEN_V2` (±60s tolerance) with only "The access
      token is invalid. Please reinstall the app." Cold-boot the emulator before
      auth testing. Worth considering whether the app should detect large clock
      skew and say so.
- [ ] Nothing else in 3.0.10 has been device-tested: PackTrack durable queue,
      the Android foreground-service/wake-lock removal, connectivity backoff,
      Run Tools eligibility, auto check-in on tracking start. **The Android
      foreground-service change is the risky one — if the condition is wrong,
      run tracking loses its foreground service and Android stops delivering
      background location.** Test a real tracked run before Play.

---

---

## 🔎 GNH 2026 weekend error-log review (2026-09-06)

All on `dev`, none deployed. **The SPs must deploy before or with the next app
build** — self check-in stays broken in the field until they do.

- [x] `processPayment` self-service exemption — the `takePayment` gate had
      blocked self check-in for every hasher who is not hash cash since
      2026-07-19 (11 hashers hit it at GNH).
- [x] `ROLLBACK` moved above every in-transaction `INSERT HC.ErrorLog`
      (8 sites, 5 SPs) — the rollback erased the log row, which is why the
      above went unnoticed for seven weeks. Rule added to CLAUDE.md.
- [x] Zero run fee ⇒ no "pay" wording; the check-in dialog says **Check In**
      and the payment-provider icons no longer show on a free run.
- [x] Run Tools shows for anyone at the start in the run window, RSVP or not;
      starting tracking marks the tracker At Hash (⇒ RSVP Yes server-side).
- [x] PackTrack unsent points now survive the app being killed (persisted per
      event, restored in order, capped at 10k, 48h keep window). **NB the 138
      "ABANDONED" log lines were never 16,798 lost points** — a failed send
      always kept its batch; the wording was wrong and now reads "RETAINED".
- [x] `LocationService.ensure()` — no more `"LocationService" not found` out of
      a build method during a resume.
- [x] Pack list survives an attendee with no local hasher row (was killing the
      whole list); logs the count as a sync-gap signal.
- [x] Two dialogs crashed on Cancel (EnumFollowType into EnumEmailAlertState /
      into int). Every other cancelButtonReturnValue checked — the rest are fine.
- [x] Three uploads (profile photo, receipt, run image) discarded their HTTP
      response and stored the URL anyway, so a failed upload wrote a row
      pointing at a blob that does not exist. All three now fail loudly.
- [x] Android foreground service + wake lock removed from the idle location
      stream (also the Android 12+ `startForeground` refusal).
- [x] Test suite runs again — it had not compiled since the get_storage →
      shared_preferences migration. 48 tests pass.

Still open:

- [ ] **Down-downs blocked** — 8 × `hcapp_addDownDown` "Caller did not attend
      this run" on Saturday morning. The app only shows the button when it
      thinks you attended, so client and server disagreed about attendance.
      Probably downstream of the check-in failure; **re-check after the SP
      deploy** and chase properly if it recurs.
- [ ] The golden test is a text-metrics canary that breaks on every Flutter
      bump and cannot really catch a layout regression. Decide whether it earns
      its keep.
- [ ] `HC.Hasher.Photo` rows already pointing at missing blobs need cleaning up
      server-side: Flash Princess (2026-09-06), Budgie Smuggler and Tore de
      Pants (January). The app fix stops new ones; it does not repair these.

---

## 🔋 Battery — findings and what is now instrumented (2026-09-06)

Measured from 160 MetricKit daily payloads in `HC.ClientErrorLog` (August
onwards), not guessed:

- location services ran **41.6 hrs against 17.2 hrs of foreground time**;
- on the **126 device-days with no run tracking at all**, high-accuracy
  location averaged **4.8 min/day** against 6.0 min/day of foreground time;
- the GNH weekend logged 153 `PackTrack map OPENED` against 135 `CLOSED`.

Fixed (all on `dev`):
- [x] The map's precise boost (5m / best / 15s) is released whenever the map
      stops being visible, not only in `onClose` — backgrounding with the map
      open used to keep navigation-grade GPS running indefinitely.
- [x] Android idle streams no longer hold a foreground service + wake lock.
- [x] The connectivity watchdog no longer probes the network every 30s for
      ever (2,880 radio wake-ups/day): paused while backgrounded, backing off
      to 5 min while the answer is unchanged, reset on any change or resume.

Instrumented, so the next report is diagnosable:
- every location-stream reconfiguration logs mode / distance filter / accuracy
  / boost-holder count;
- precise-boost request and release log the running count;
- a boost held with no run tracking says so every 5 min with elapsed time — a
  leak now reads as a repeating line instead of a flat battery.

Checked and left alone: the payment outbox's 10s poll (no network, no wake
lock, returns immediately when idle).

- [ ] **Re-measure after a release.** The same MetricKit query should show
      high-accuracy time on non-tracking days drop toward zero. If it does not,
      the boost log lines will say who is holding it.
- [ ] Consider whether the always-on idle location stream is needed at all when
      no run is near — it exists to feed `isAtRunStart` and distance-to-event.

---

## ⬆️ Flutter / package upgrade — branch `flutter-upgrade` (2026-09-06)

Not merged, not device-tested. `flutter upgrade` is machine-global, so **the
installed toolchain is now 3.47.2 and dev was made green on it** (golden
regenerated, no dependency changes).

Done on the branch, each verified by analyze + 48 tests:
- Flutter 3.41.9 → **3.47.2** (Dart 3.11.5 → 3.13.2), no source changes.
- `pub upgrade` within existing constraints (firebase 4.14/16.6, flutter_map
  8.3.2, dio 5.11.1, sqflite 2.4.3, photo_manager 3.12.0, …).
- Majors with no source change: cached_network_image 3→4,
  calendar_date_picker2 2→3, sensors_plus 6→7, torch_light 1→2.

Blocked, with the reason:
- [ ] **Language version stays at 3.11.** Raising the pubspec `sdk:` constraint
      to 3.13 does not compile: freezed 3.2.5 emits `required final List<T> x`
      in const constructors, which 3.13 rejects. Fix is freezed 4.x — forbidden
      because **`ive_flutter_core` (git, pinned `6eb83f6`) depends on freezed
      ^3.2.3**. That git dep has to move first, or be vendored the way
      `ive_flutter_core_mobile` was for 3.0.7.
- [ ] **flutter_secure_storage 9→11 + device_info_plus 13 + package_info_plus
      10 + share_plus 13 are ONE coupled cluster** (the newer *_plus need
      win32 ^6; secure_storage 9 pins win32 ^5). Gated on secure storage — the
      device secret and keychain reset code — so it needs a device test
      including upgrade-from-installed, not an analyzer.
- [ ] **permission_handler 12→13** — location permission underpins PackTrack.
      Device test, fresh install and previously-granted install.
- [ ] **map_launcher 4→6** — a redesign (MapApp objects replace the enum,
      discovery results changed), touching 5 files of "open in maps".
- [ ] **keyboard_actions 4→5** — API break
      (KeyboardActionsConfig/Item/Platform), UI-only.

---

## 3.1 TRACK — post-run attendance claims ("I was there") + admin approval

James's idea 2026-09-07, from the RSVP-buttons-on-past-runs screenshot.

**Part 1 — hide the RSVP buttons on a past run. Small, ships on 3.0.x.**
- [ ] On the run detail RSVP tab, hide the three action buttons ("I'll be
      there!" / "I might come" / "I will not come") once the run is past.
      They take a lot of vertical space and mean nothing after the event.
- [ ] Use the SAME rule that moves a run between the future and past lists —
      `EventStartDatetimeGmt < julianday('now','-6 hours')`, GMT instant vs GMT
      instant (`query_runs.dart:671`). Reuse that expression so the tab can
      never disagree with which list the run is in.
- [ ] KEEP the Going/Maybe/Not-going counts and the roster. Only the three
      buttons go — the counts and attendee list are the useful part of a past
      run.
- [ ] The run-admin attendance screens are unaffected — admins still set
      attendance on past runs as they do today.

**Part 2 — claim attendance after the fact, kennel admin approves. 3.1.**

It is an ATTENDANCE feature, not an RSVP one: what people want retrospectively
is to be counted as having run (`AttendenceState`), not to state an intention.
Approval matters because run counts are the currency of hashing and the number
most worth lying about — and the count guard/SET path already has a history
(see [runcount-guard-churn] in memory).

- [ ] **Add a PENDING attendance value numerically BELOW `attendenceAtHash`
      (20) — 15 is the obvious slot.** Every existing consumer tests
      `AttendenceState >= 20` (run counts, stats, pack list, `isAtRunStart`),
      so a pending claim is invisible to all of them *by construction* — no
      audit of dozens of call sites, and no way to silently inflate a count.
      Approval is then just 15 → 20 through the existing `setEventAttendence`
      path, which already recalculates counts.
      - Backward compatible for free: a 2.1.2 / 3.0.x phone syncing a HEM row
        with state 15 reads it as "not at hash", which is correct. Worth having
        given shipped clients cannot be fixed retrospectively.
- [ ] **Reuse the `manageAttendance` permission** (the one that already gates
      bulk attendance) rather than inventing a new one. The natural approvers —
      the run's hare, a run admin — are already covered by it.
- [ ] **Approval surface is the real cost, not the data model.** There is no
      pending-queue anywhere today. Cheapest version needing no new
      navigation: show pending claims inline in the check-in / pack list for
      that run, where admins already go, with approve/reject there.
      Notifications later.
- [ ] **Time-limit claims** — otherwise people claim runs from 2019 to bump
      their count. Decide the window.
- [ ] **Decide what happens to a claim nobody actions.** Suggest leaving it
      pending and visible to the claimant rather than auto-approving after N
      days; auto-approval defeats the point of approving.
- [ ] **Per-kennel switch** — disabled / claims auto-accepted / claims need
      approval. Plenty of kennels will not police this, and a big kennel needs
      to. Extend `KennelFeature`, NOT `AppAccess` (see
      [admin-entry-gating] in memory).

Why 3.1 and not 3.0.x: this is DB + SP + sync domain + permission + UI +
notification. 3.1 already wipes and reloads the local DB for the UNIQUE
constraints, which is the natural moment to introduce a new attendance state.

---

# 3.1 TRACK — event-free payments

No branch exists; `dev`/`master` stay 3.0.x and 3.1 forks from `dev` when the
work starts. Design in memory: `project_promotional_credit`,
`project_31_track_payments`, `project_local_db_unique_constraints`.

## Why this is a separate track

Every payment today is bound to an event: `HC.Payment.EventId` and
`HasherEventMapId` are both **NOT NULL with foreign keys**. But four things
people pay for are not tied to a run at all:

| Product | Today | ProductType |
|---|---|---|
| Membership | forced onto some event | 2 |
| **Run packages** (buy 10, get 11) | cannot exist | new |
| Haberdashery | forced onto some event | 3 |
| **Promotions earned** (hare rewards, comps) | cannot exist | — |

It cannot ship on 3.0.x: `payments_model_ns.dart` declares
`required String eventId` and `required String hemId`, so a null would throw
`type 'Null' is not a subtype of type 'String'` and break payment sync on
every 2.1.2 and 3.0.x install in the field. No app release fixes a phone that
has not updated.

## Already live in production (dormant, safe on 3.0.x)

- [x] `HC.Payment.PromotionalCredit`, `PromotionalDebit`, computed
      `NetPromotional`; `HC.HasherKennelMap.PromotionalCredit`. Zero row churn.
      Sync SPs use explicit column lists, so 3.0.x clients never see them.
- [x] Balance recompute LEFT-joins `HC.Event` and orders by
      `COALESCE(EventStartLocal, PaidDate)` — event-less payments already count
      toward a balance. Verified neutral across all 7,011 live balances.
- [x] Free payments record nothing paid and nothing charged (28 rows corrected).

## 1. Server: let a payment exist without an event

- [ ] Make `HC.Payment.EventId` and `HasherEventMapId` **nullable**. Foreign
      keys tolerate NULL, so no constraint changes — but both are indexed, so
      check `IX_CreditBalance` survives the ALTER.
- [ ] **Version-gate the sync SPs.** Existing procs emit only payments that
      HAVE an EventId and a HemId, so old clients can never receive a row they
      cannot parse. 3.1 clients ask for the unbounded set.
      **Verified necessary:** `hcapp_syncUserData` and
      `hcapp_syncKennelAdminData` select straight `FROM HC.Payment` with NO
      event join. `hcapp_syncEventAdminData` is already safe — it filters
      `EventId = @eventId`.
      *Open decision:* a defaulted `@includeUnboundPayments SMALLINT = 0`
      parameter on the existing procs (Claude's preference — HC3 already
      contains `syncUserData`, `_392`, `_668`, `_705`, `_800`, forked procs
      that drifted) vs three parallel V2 procs (James's original sketch).
- [ ] **Audit every consumer that INNER JOINs Payment to Event** — each one
      silently drops event-less rows, no error, rows just missing:
      `hcapp_getPaymentReport` (x2), `hcapp_processPayment`,
      `hcapp_processBulkPayment`, `hcapp_setEventAttendence`,
      `nonApi_rptKennelRunStats` (x3), `hcportal_getCategoryDetail` and `2`.
      The two that hurt most are the payment report (the treasurer's money) and
      syncUserData (the phone would disagree with the server about a balance).
- [ ] `hcapp_processPayment` currently REQUIRES `@eventId` for productType 1
      and 2. Make it optional for the event-free products.

## 2. Run packages

- [ ] Per-kennel package config: name, price paid, runs promised, active flag,
      optional expiry. Organiser thinks in **runs**; the system stores **money**;
      store the run price assumed at purchase so drift is visible later.
- [ ] A purchase is ONE payment row with four amounts, e.g. pay 70 for 11 runs
      at 7: `Credit 70 | Debit 0 | PromoCredit 7 | PromoDebit 0`.
- [ ] Spending straddles buckets in ONE row:
      `Credit 0 | Debit 5 | PromoCredit 0 | PromoDebit 2` for a 7 run with 2
      promo left. **Promo floors at zero** — `PromotionalDebit = MIN(fee,
      available)`, cash absorbs any overdraft (72 hashers are already in debit).

## 3. Promotions earned

- [ ] Grant promotional credit for any reason — **hare rewards**, comps,
      recruitment. One row, `PromotionalCredit` set, `EventId` optionally
      pointing at the run they hared.
- [ ] Cash reconciliation must count cash rows ONLY. A grant is structurally
      identical to an overpayment, so without the split it reads as money taken.
- [ ] **Refunds pay cash paid, pro-rata — never credit face value**, or someone
      pays 70, refunds 77 and walks away 7 up.

## 4. Expiry — on RUN inactivity, not payment inactivity

James's design. Kennels with zero run fees for members have NO payment rows,
so payment inactivity would expire active members' credit.

- [ ] Per-kennel configurable durations.
- [ ] Default: promotional credit expires after **1 year of run inactivity**.
- [ ] Default: the whole kennel credit expires after **3 years**.
- [ ] Measured from `HC.HasherEventMap` attendance, not payments.
- [ ] Expiry is just another row (a negative promotional movement) so the
      ledger shows it. Idempotent and auditable.
- [ ] *Open:* does 3-year expiry also write off the 72 hashers in DEBIT?
      Symmetry says yes.

## 5. Member-facing transaction screen

- [ ] People see their **total** by default; a ledger screen shows full history
      with promotional broken out. `HC.Payment` is already the ledger — every
      row carries its movement (`NetPayment`) and running balance
      (`CreditAvailable`), so no new table is needed.

## 6. Kill the duplicate-row bug for good

- [ ] **UNIQUE constraint on the server primary key in every synced local
      table**, delivered by bumping `DB_VERSION` by 10 so `_handleDbUpgrade`
      forces a wipe + reauth + full reload. Tables are recreated, so the
      constraints land on fresh schema with no dedupe migration, and every
      device is healed rather than only the one that reported it.
- [ ] **FIRST: switch the bulk insert to `INSERT OR REPLACE`/`OR IGNORE`.** A
      UNIQUE index turns silent duplication into a thrown constraint violation,
      so without this sync starts failing loudly on exactly the race it is meant
      to fix.
- [ ] **Time the full re-sync before shipping** — every user reloads at once.
- [x] All local sync writes serialised onto one queue (shipped 3.0.7).
- [x] `ive_flutter_core_mobile` vendored to `lib/core_mobile/` (shipped 3.0.7),
      so both halves of the fix are now in one repo.

## 7. PackTrack usage should be visible in the database

Today the ONLY record that a run was tracked is Azure Table Storage. Answering
"which runs used PackTrack" (asked 2026-09-03) needs a partition-key walk of
`EventPositions` plus a join back to `HC.Event` by hand — there is no query
that answers it, and no reporting, no adoption metric and no admin view can
ask it either.

- [ ] **Mark the HEM record when a hasher tracks a run.** A flag (or a first/
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

- [ ] **Store a compressed copy of each hasher's track on the HEM record.**
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

## ⚠️ Standing constraint

**Money may be summed WITHIN a kennel, never ACROSS kennels.**
`HC.Kennel.CurrencyCode` is unpopulated for 393 of 394 kennels, so a
cross-kennel total silently adds won to pounds to yuan.

---

## 3.1 TRACK — kill the duplicate-row class of bug for good

James's call 2026-09-02. Design note in memory `project_local_db_unique_constraints.md`.

- [ ] **UNIQUE constraint on the server primary key in every synced local
      table**, delivered by bumping `DB_VERSION` by 10 so `_handleDbUpgrade`
      forces a wipe + reauth + full reload. The tables are recreated, so the
      constraints land on fresh schema with no dedupe migration, and every
      device is healed rather than just the one that reported it.
- [ ] **FIRST: switch the bulk insert to `INSERT OR REPLACE`/`OR IGNORE`.** A
      UNIQUE index turns silent duplication into a thrown constraint
      violation, so without this sync starts failing loudly on exactly the
      race it is meant to fix.
- [ ] **Also wrap the remaining apply paths in AsyncSerializer** —
      `hasher_kennel_map_service.dart:213/216/316/319/322` call
      `updateSqlTablesWithResultsFrom*` directly, outside the guard added on
      2026-08-16. That is the hole that duplicated CH3 - Aldgate on James's
      phone on 2026-09-01 while the server was clean.
- [ ] **Time the full re-sync before shipping** — every user reloads at once
      (~180 on 3.0.x plus 2.1.2), and it leans on the self-healing reauth path
      that was only just hardened.

---

## 🎯 BEFORE THE NEXT APP STORE PUSH — promotional credit

Agreed 2026-09-02. Design in memory `project_promotional_credit.md`.

- [ ] **Promotional credit as a tracked component of kennel credit.** Credit
      stays money and one currency; anything a kennel grants without taking
      cash is recorded as a distinct promotional part of the same ledger.
      Started as run packages (Brussels: pay €70, get 11 runs = €77 credit),
      generalised to any grant — **rewarding hares**, comps, recruitment.
- [ ] **Member-facing credit ledger screen.** People normally see only their
      total balance; the ledger shows full history with promotional broken out.
- [ ] **Portal:** per-kennel run packages — name, price paid, runs promised,
      active flag, optional expiry. Organiser thinks in runs, system stores
      money, and the run price assumed at purchase is stored alongside.

Decide before building: does promotional credit expire; draw order when both
kinds are held (promotional first); refund policy (refund *cash paid*
pro-rata, never credit face value — otherwise it is an arbitrage).

⚠️ `HC.KennelCredit` schema not yet inspected — check whether it already has a
type/reason column before designing the split.

---

## ✅ SHIPPED 2026-08-30 — Play policy fix + imported-photo track fix

- **Android 3.0.1+1314** → Play **production** (replacing the rejected 1312)
  AND internal. Both COMMITTED, `changesNotSentForReview` — **James must press
  Publishing overview → Send changes for review**; the API cannot.
  Verified in the shipped bundle: zero READ_MEDIA_* elements, legacy storage
  permissions capped at maxSdkVersion 28/32, original 2019 signing key.
- **iOS 3.0.2+1315** → TestFlight (Delivery 666661a1-6fa0-40c1-90e3-3a559fc73845).
  The name had to move: 3.0 went live, and Apple CLOSES a marketing-version
  train once it ships, so 3.0.1 was refused. iOS and Android names now diverge
  until Android's next build.
- **public-web 0.21.32** deployed.

### Still to verify after this release
- [ ] **Camera-roll import on a real ANDROID device with geotagged photos.**
  The system photo picker is now mandatory, but Android redacts EXIF location
  without ACCESS_MEDIA_LOCATION (not declared), and image_picker_android never
  calls setRequireOriginal. Import rejects photos with no GPS, so it may fail —
  possibly it already did before this change. Untested either way.
- [ ] Open the run with the imported photo and confirm the track and distance
  now look right on a device (verified numerically, not visually).
- [ ] Android tablet/foldable pass — the resizability opt-out was removed in
  1313 and large-screen layouts remain untested on Android.

---

## ✅ SHIPPED 2026-08-30 (second release of the day)

- **SPs** — 150 deployed, 0 failed. Includes the monitor version drill-down fix
  (it listed 1 user for 1314 while the tile counted 3: MAX(idx) picked each
  user's newest login of ANY version, and rows logging '<no HC version>' then
  failed the version filter). Verified live in the deployed definition.
- **portal 2.0.64+699** — LIVE (verified version.json). Label permanent at slot
  4, Hash View at 6; slots 7-12 configurable.
- **public-web 0.21.33** — LIVE. Trail TV preloads upcoming photos; "Fresh from
  trail" is live-mode only.
- **mobile 3.0.2+1316** — iOS TestFlight (Delivery 3df395d3-d612-4413-bef4-6dd97b51e9a7)
  and Play **internal only**. Watch Check/False buttons show the kennel's marks.
- **Kennel configs migrated** (BMPH3, HCTEST-ABC) — nothing lost; backup at
  ~/hc_trailslots_backup_20260830_110950.txt

### ✅ Play production: 1314 APPROVED AND LIVE (2026-08-30)
Google approved 3.0.1+1314 — the READ_MEDIA_IMAGES policy rejection is CLEARED
and Android is on the Play Store at full rollout for the first time since 2.1.2
(Oct 2025). Both stores are now shipping 3.0.

1316 remains on the INTERNAL track only, by James's instruction to leave a few
days before another production store build.

**Before promoting 1316 to production, check on a real device:**
- Camera-roll import with geotagged photos — the system photo picker is now
  mandatory and ACCESS_MEDIA_LOCATION is NOT declared, so EXIF GPS may be
  redacted and imports silently rejected. Untested; may already have been
  broken before the picker change.
- Marks on a kennel with a migrated config (BMPH3): 1316 renumbered the slots
  and the DB already holds the new layout, so 1314/1315 clients render those
  kennels with the OLD numbering until they update.

---

## ⏰ REMINDER — TURN OFF GLOBAL ERROR LOGGING (check with James first)

**Due on/after 2026-09-20** (≈3 weeks after 3.0 went live). Raise it with James
BEFORE turning it off — he may want it left on longer.

On 2026-08-30 debug-harvest logging was enabled for **ALL 7,108** active users
(previously 6) so 3.0's rollout could be watched. `HC.Hasher.Preferences` bit
0x100. Verified safe: every trigger on HC.Hasher is column-gated, so a
Preferences-only UPDATE bumps no `updatedAt` and forces no client re-sync
(confirmed: 0 rows re-stamped).

It costs storage — every booting device uploads its previous session's log to
`HC.ClientErrorLog` — which pulls against the Azure cost work in
`docs/azure_cost_audit.md`.

**Rollback (keeps the original 6 RunTracker testers on):**
```sql
UPDATE HC.Hasher SET Preferences = Preferences & ~256
WHERE (Preferences & 256) = 256
  AND id NOT IN (
    '895cc3d2-ac67-482d-b449-0390d845e0d6',  -- Alina Peltea
    '2b3ce666-bf2c-4565-9483-1e044cc152b2',  -- Old Squirty Bastard
    'd0b7ef01-c6e3-4723-9d2f-2ae864a59f1a',  -- Tuna Melt
    'ebd2cdb8-5731-4301-b14e-608874a9ea41',  -- Kilty as Charged
    '081610fa-88d4-44fc-9048-c0f77a8f5ad2',  -- Rack of Lamb
    '0cdbb109-215e-4b5f-a405-f6c9fbcb18ec'); -- Opee
```
Takes effect on each user's next login/boot. Logs arrive one boot LATE.

---

## ✅ 2026-09-07 — GPS filter: stationary radius now scales with accuracy

**And the cross-track outlier idea was measured and dropped. See below.**

**What changed.** `TrackPointFilter._collapseStationary` used a flat 25m radius
to decide "this hasher is not moving". That assumes a quality of GPS the phone
may not be providing. The radius is now the sum of the two fixes' accuracies —
floored at 25m so confident fixes behave exactly as before, capped at 60m
(`stationaryRadiusMaxMeters`) so a pair of hopeless fixes cannot swallow real
movement. Two fixes describe the same place when their error circles overlap.
Mirrored in `public-web/lib/packtrack.ts` (`stationaryRadius`).

**The case that forced it** (GNH 2026 Sunday, hasher `f58ca3ae`): stood at a
check for twenty minutes on fixes accurate to 60-116m. The readings ping-ponged
between two spots 37m apart — well inside their own error, outside a flat 25m
radius. The pause was never collapsed, so ~0.5 km of standing still was counted
as running. Worse, the raw track had NO out-and-back spike before filtering and
TWO after: the filter was introducing the artefact, not failing to remove one.

**Measured on all 15 Sunday tracks** (`test/fixtures/gnh_sunday_pack.json`,
2,650 points, covered by `test/unit/track_point_filter_real_track_test.dart`):

| | before | after |
|---|---|---|
| out-and-back spikes >100m after filtering | 4 | 2 |
| f58ca3ae | 1.95 km, 2 spikes | 1.68 km, 0 spikes |
| every clean track (7 of 15) | unchanged | unchanged |

The safety property that makes it shippable: sweeping the cap from 25m to 90m,
**every clean track measured exactly the same length at every value.** Only
noisy tracks move. 60 was chosen because the gains stop there and the losses
do not.

### ❌ Cross-track outlier detection — measured, not worth building

The earlier claim that cross-track comparison would catch 137 points a
per-track filter misses **does not survive contact with the data** — treat that
number as withdrawn. Built the corridor properly (every confident fix, acc ≤
20m, from every OTHER runner, on a 150m grid) and measured every point of every
Sunday track against it:

* median distance to the corridor **1.3m**, p99 66m, p99.9 97m, **max 192.7m**
* of 2,650 points, exactly **one** sits more than 150m off the corridor — and
  its accuracy is 157m, so the existing uncertainty smoothing already owns it
* the 24 raw spikes are almost all **inside** the corridor (1.8m, 4.9m, 12.3m
  from it) because they bounce between two places the pack genuinely went

So the corridor cannot separate a spike from a real position, and everything it
would flag is already flagged by `acc`. Building it would add a cross-track
dependency (every track needed before any track can be filtered), a spatial
index, and a real false-positive risk on a legitimate solo excursion — for one
point that accuracy already catches. **Accuracy is the signal; proximity is
not.** Do not revive this without new data showing a spike that lands off the
corridor AND reports good accuracy.

---

## 📸 NEXT UP — stop attaching imported photos to the importer's track

**Target: first half of September 2026**, once Play has approved 1314 and the
3.0 iOS rollout looks stable. Deliberately NOT in 1314: that build is blocked
on a Play policy rejection and must not wait for a schema change.

**Why.** An imported photo is written into the IMPORTER's GPS track
(`_enqueuePhotoMarker` → `markPointAt(overrideUserId: currentUserId,
atLat/atLng: <photographer's EXIF>)`). The visible damage — the track bending
out to the photographer and the inflated distance — was fixed 2026-08-30 by
excluding photo points from the polyline and distance on mobile and web. What
remains is that the photo still WEARS the importer's identity:
  * it inherits the importer's lane visibility, so hiding a trail (Normal/Long)
    hides someone else's photo with it;
  * anywhere marks are credited to a runner it reads as the importer's;
  * it surfaces in replay at the PHOTOGRAPHER's capture time, which is right on
    a shared timeline but reads oddly against your own dot.

**The coupling that makes this more than a one-liner:** the map takes a photo's
POSITION and TIME from the track point, so the `PHO::` write cannot stop until
the renderers read from elsewhere.

**What already exists** (checked 2026-08-30): `HC.KennelPhotos` already has
`Latitude`/`Longitude`, and BOTH clients already fetch the photo list via
`hcapp_getRunPhotos` to resolve blob URLs. The only missing datum is a capture
time — it currently lives ONLY in the track point's `timestampMs`.

**Plan**
1. [x] DB: `ALTER TABLE HC.KennelPhotos ADD TakenAtUtc DATETIME2 NULL` — RUN in
   production 2026-09-07. Script archived at
   `db/hc6/app/archive/2026-09-07_add_KennelPhotos_TakenAtUtc.sql`. Nullable, no
   backfill: for existing rows the true capture time is unknown and CreatedAt
   would be a lie. (Photographer credit NOT done — `UserId` is still the
   uploader.)
2. [x] SPs (2026-09-07, **written and parse-checked, NOT YET DEPLOYED**):
   `hcapp_addKennelPhoto` takes `@takenAtUtc DATETIME2 = NULL` and stores it;
   `hcapp_getRunPhotos` (both rowsets) and `hcapp_getRunAllPhotos` return
   `TakenAtUtc`. Contracts bumped: addKennelPhoto 1.2.0, getRunPhotos 1.1.0,
   getRunAllPhotos 1.1.0.
   ⚠️ **DEPLOY BLOCKER — the app now sends `takenAtUtc` on every photo upload.**
   The shim forwards every JSON property as a named parameter, so until these
   SPs are deployed EVERY photo upload fails with "has no parameter named
   @takenAtUtc". Deploy the SPs BEFORE any build carrying this app change ships.
   `publicWeb_getRunPhotos` deliberately untouched — it excludes position for
   privacy and has no map to place pins on.
3. [ ] Mobile: build photo markers from the photo list (position from Lat/Lng,
   time from TakenAtUtc) instead of from track points; stop calling markPointAt
   for imports. Keep reading legacy `PHO::` points so existing runs still show.
   NOT ATTEMPTED — `_buildCheckpointMarkers` / `_visibleMarkCount` /
   `_markerCacheKey` / `_selectedRunnerCues` all read the track point, and the
   memo key means a half-done switch shows nothing at all. It needs a device to
   verify, so it was not done blind overnight.
4. [ ] Web: same in `PackTrackMap.tsx` and `TrailTv.tsx`.
5. [ ] Optional later: migrate historical `PHO::` points out of the position
   store (the label is the photoId, which maps straight to the KennelPhotos
   row). They are inert now, so this is tidiness, not urgency.

**Done separately 2026-09-07 — the photo PIN was in the wrong place for a
different reason.** `_addKennelPhoto` stored `LocationService.lastKnownPosition`
while the `PHO::` marker used a fresh `LocationAccuracy.best` fix. Outside a
tracked run the location stream is in IDLE mode (250m distance filter, `lowest`
accuracy), so the stored coordinate could be hundreds of metres stale — or
(0,0) on a phone that had not moved since launch — and that is the coordinate
the gallery and any list-sourced renderer use. Both now take the same one-shot
high-accuracy fix, falling back to the stale one if the GPS times out. Also
fixed on the way: an imported photo queued while offline was stamped with the
phone's position and the queue time, not the photo's EXIF position and capture
time (`_queueForOfflineUpload` now takes explicit lat/lng/takenAtMs, and
`PendingPhotoUpload` carries `takenAtMs`).

NOTE: the GPS track lives behind its own Azure Functions (`StorePositions` /
`GetPositions` / `DeletePositions`), NOT in the SQL/SP layer — step 5 is a
different service from steps 1–2.

---

## 🎯 3.0 RELEASE RUNWAY (consolidated burn-down, 2026-08-23)

App Store live = 2.1.2 (Oct 2025). iOS beta = 1312 on TestFlight
(2026-08-28: card chat bubbles + SP badge 1.1.0, run share sheet
map/Trail TV, bigger RSVP/follow tap targets, spinner restored; 1311 =
offline check-in + outbox UI, payment outbox since 1310, watch app since
1309). Android: 1312 uploaded to the internal track via the Play API and
STAGED "not sent for review" 2026-08-28 — **James: Play Console →
Publishing overview → "Send changes for review"** (the API refuses to
submit for this app: HTTP 400 "Changes cannot be sent for review
automatically", Console-only; `tools/play_upload.py --send-for-review`
confirms it each time). First Android build to go through review since
2.1.2. iOS and Android build numbers are back in lockstep.
The detailed per-feature checklists further down hold the step-by-step
cases — this is the ordered index of what actually gates 3.0.

### P0 — gates submission (one or two hash runs + a bench evening)

- [ ] **Money block** (one run-admin session covers all): payment package
  (footer totals, chips, pending card, zero-price⇒FREE, combined
  membership+run button, atomicity smoke), membership charge paths,
  check-in membership/haberdashery buttons, membership expiry badge.
  → sections "payment package", "membership payments", "check-in
  membership/haberdashery", "membership expiry badge".
- [ ] **util_rewriteZeroCashRunPaymentsAsFree** — James runs @dryRun 1,
  reviews, then @dryRun 0. Before or with the money block.
- [ ] **PackTrack live block** (needs a real/moving run, 2 phones where
  noted): deferred-commit mark undo card (NEW semantics — capture at tap,
  commit on dismissal; supersedes the 1293 "mark undo" items), auto-stop
  steps ①–④ incl. admin stop-everyone, live-viewer GPS boost, map
  pending-tail + freshness pill, radar UNLOCKED on-the-spot spin (compass
  fix 2026-08-23), Multi Photo session to the 6-cap, mark-multiplication
  moving taps (closes the last open PackTrack investigation).
- [ ] **Upgrade path bench test** (iOS phone, 2.1.2 → current): "Welcome to
  Harrier Central 3.0" dialog → jungle splash → Done → normal boot; kill
  and relaunch → nothing re-shows. (Android equivalent verified on
  emulator 2026-08-22/23.)
- [ ] **Boot/sync bench**: sync-serializer no-duplicate checks (kennel
  admin pull-to-refresh races), fresh-install boot with no/stale
  credentials (regression on the 2026-08-22 early-boot alert fix).
- [ ] **App Store submission pack** (no code): fresh screenshots, What's-New
  text, listing copy, privacy questionnaire refresh (camera/photos/
  location/notifications answers are 2.1.2-era), decide version name
  (lift the 3.0.x pin), submit for full review.

### P1 — should pass before/while review runs (bench + one run)

- [ ] Lost compass block: own-track merge cases (airplane mode, solo,
  different-run guard), steering slide feel, "front-most hasher" copy
  (NEW), bullseye vs follow-me states.
- [ ] Run editor single-save block + GetX editor regression items
  (2.15.54/55 checklists — still fully untested on device).
- [ ] Photo review page block (2.15.21 checklist) + Hash Flash cover/
  featured regression.
- [ ] On Inn removal + On Inn confirmation checklists (partially witnessed
  on Android emulator 2026-08-22).
- [ ] Past Runs NEW behaviour eyeball: followed/attended-only list, RSVP-No
  runs visible again, 3-6h boundary gone (LH3 case).
- [ ] **MetricKit soak**: ≥1 week of 1292+ builds in the field, then review
  HC.ClientErrorLog for intact [METRICKIT] payloads — specifically Tuna's
  892MB RSS question.
- [ ] Splash verification leftovers: iOS Done→no-reshow (Android ✓).
- [ ] **1312 eyeball block** (bench): see "Device test — 3.0.1+1312" below —
  chat bubble states + one-time badge jump, share sheet on all three
  entry points, corner tap targets, spinner centred with diamonds.

### P2 — fine to trail the release

- Radar wedge easing feel, playhead-clock replay case, fullscreen map
  safe-area on notched phones, editor open/close ×10 perf, chat badge
  optimistic-clear regression, "Caution guaranteed?" taste call.
- **Play Console recommendations (reviewed 2026-08-28)**: resizability —
  SUPERSEDED 2026-08-28 by native large-screen support (see "iPad /
  large-screen" below): the manifest opt-out
  `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` was removed again. The other
  four are post-3.0: edge-to-edge tidy (drop `windowFullscreen` in
  LaunchTheme + nav-bar colour in main.dart), bitmap decode caps (ongoing),
  **R8/minify — only with a full Android device pass** (release-only
  reflection crashes in plugins are the risk; gain is small for Flutter).

### iPad / large-screen support (dev, 2026-08-28 — goes out in 1313)

- [x] Runner target `TARGETED_DEVICE_FAMILY = "1,2"` — the app is a native
  iPad app (was iPhone-only ⇒ phone-sized compatibility window on iPadOS 26).
- [x] `FormFactor` (`lib/util/form_factor.dart`): tablets (shortest side
  ≥ 600dp) rotate freely, phones stay portrait-only (main.dart +
  choose_profile_image.dart). Android opt-out removed from the manifest.
- [x] Full-width layouts kept (no letterboxing — James's call). Run images
  always fit-to-width at natural aspect, never cropped (James, 2026-08-29 —
  a tablet height cap was tried and removed). Tablet-only cap: QR codes max
  520pt (`maxQrSize`); three `Positioned(width: MediaQuery…)` tab views
  pinned with left/right; calendar dialog width capped.
- [x] iOS 26 status-bar bug: `UIStatusBarHidden` true→false in
  Debug-/Release-Info.plist (+ `fullscreen: false` in the native-splash
  config) so the bar is never hidden-then-shown — the re-show leaves the
  safe-area inset at 0 on iOS 26 (flutter/flutter#175520; on iPad the status
  bar sat over the app bar until the first rotation). Splash now shows the
  status bar on iPhone too — check it looks fine.
- [ ] UIScene lifecycle migration (Flutter warns every build; Apple will
  require it). Tried and reverted 2026-08-28: it did NOT fix the inset bug
  and it moves plugin registration / watch bridge / MetricKit channel into
  `didInitializeImplicitFlutterEngine` — needs a device pass for push,
  background location and the watch before it ships. NB the live plists are
  `Debug-Info.plist` / `Release-Info.plist`, not `Info.plist`.
- [x] Walked every reachable screen on the iPad Pro 13" simulator
  (portrait + landscape): tabs, drawer pages, run detail tabs, all run-admin
  and kennel-admin pages, Live Run Tools tabs, rose, kennel links.
- [ ] Verify on Melissa's physical iPad (rotation, windowed vs full-screen,
  Split View at phone width).
- [ ] Android tablet / foldable emulator pass before the opt-out removal
  ships (layouts are shared, but untested on Android large screens).
- [x] **3.0 SUBMITTED TO APPLE 2026-08-29** — state WAITING_FOR_REVIEW, build
  3.0.1+1313 attached, releaseType AFTER_APPROVAL (goes live automatically on
  approval — have the announcement ready; `docs/3.0_upgrade_note.md`).
  First App Store release since 2.1.2 (Oct 2025).
- [x] App Store listing copy pushed 2026-08-29 (description 1058 chars,
  What's New 1130) — kept in `docs/app_store_listing_3.0.md`.
- [x] Apple Watch screenshot DONE 2026-08-29 (368x448, APP_WATCH_SERIES_4,
  Watch SE 3 44mm) — required because the build embeds HarrierWatch.app.
- [x] App Store Connect screenshots DONE 2026-08-29: 8 iPhone (1320×2868)
  + 8 iPad (2064×2752) uploaded to the 3.0 version via
  `store/asc_upload.py --apply`; the stale 2023 iPhone SE and 2025 16 Pro Max
  sets were deleted. All 16 report COMPLETE, no errors. 3.0 is still
  PREPARE_FOR_SUBMISSION — James submits when ready.
- [x] In-app 3.0 promo deck replaced 2026-08-29 (7 slides → 8) with the same
  designs as transparent AVIF at 1170×2532. Originals backed up in-container as
  `backup_20260829_version_3.0_1..7.avif`.
- [ ] Taste: 2-column kennel/run grids in landscape would be the next
  iPad-native step; not started.

### Build-items still open (small, none gating)

- [ ] Strip any remaining TEMP mark-multiplication instrumentation once the
  moving-tap test closes the investigation.
- [ ] Apple Watch companion (see Watch entry below) — parallel track,
  NOT gating 3.0.

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

- [ ] **Apple Watch companion — James-approved direction (2026-08-23)**:
  a remote-control watch app while the phone app runs the session. Wrist
  shows live distance/elapsed; buttons: **Check, False Trail, On Inn
  (confirm first), I'm Lost** (opens a vector-back-to-trail view fed by
  the phone's lost-compass bearings + the watch's own compass). Marks ride
  WCSession → the phone's capture/commit flow (watch tap = immediate
  commit + haptic; no flash card on wrist). Parallel track — NOT gating
  3.0; realistic size ~4-8 focused sessions (SwiftUI target + WCSession
  bridge + Flutter platform channel + sim/device testing; TestFlight
  ships it embedded automatically).
  - [x] **Scaffold (2026-08-23)**: `HarrierWatch` watchOS target added to
    Runner.xcodeproj (xcodeproj gem; bundle id
    `com.harriercentral.app.watchkitapp`, versions track
    `$(FLUTTER_BUILD_NAME/NUMBER)` via Generated.xcconfig, SKIP_INSTALL,
    embedded via Embed Watch Content). SwiftUI app: stats header
    (~-prefix for Power Saver), Check/False/I'm Lost/On Inn(confirm)
    buttons, LostView polling shell. Phone side: `PhoneWatchBridge.swift`
    (WCSession ↔ `harrier_central/watch` channel) + Dart
    `WatchBridgeService` (permanent, services_init): 1s state push from
    LiveRunGeneralController ticker; `markFromWatch` = immediate
    capture+commit sharing the 8s slot cooldown, bypassing the flash-card
    pending state; On Inn = `endRun(markOnInn: true)`.
  - [ ] Phase 2: real lost-compass vectors in the `lostQuery` reply
    (currently a "use your phone" message); move the state broadcast into
    LocationService so the wrist doesn't freeze if the live-run page is
    closed mid-session while tracking continues; Start-tracking from the
    wrist (deliberately omitted — start needs the phone's pre-run checks).
  - [ ] Phase 2: pair watch sim + phone sim and test end-to-end; then
    on-wrist device test. Requires Xcode watchOS platform (downloaded
    2026-08-23 — any Mac building the app now needs it since Runner
    depends on the watch target).
  - [x] Next iOS dance: first archive containing the watch app — expect
    `-allowProvisioningUpdates` to mint the new watchkitapp profile;
    verify both bundles' versions in the IPA before altool upload.
    *(DONE 2026-08-26, build 3.0.1+1309: watchkitapp profile minted
    cleanly, Runner + HarrierWatch.app both verified at 1309 and
    Distribution-signed before upload; delivery 61873e3e.)*
  - [ ] **Wear OS port (post-3.0, after Apple Watch proves adoption)**: the
    Dart `WatchBridgeService` + channel protocol are transport-neutral —
    reuse as-is. New work: Kotlin bridge implementing the same
    `harrier_central/watch` channel over the Wearable Data Layer
    (MessageClient=sendMessage, DataClient=applicationContext), a small
    Compose watch UI mirroring ContentView, and Play distribution (Wear OS
    apps ship as a SEPARATE AAB under the same package — wear form-factor
    track + wear screenshots + wear quality review; NOT embedded like iOS).
    ~2-4 sessions since the protocol/design is done. Garmin = separate
    Connect IQ ecosystem, out of scope.
  Original tier analysis for reference:
  1. **Live Activity for tracking sessions** (days, no watch target):
     elapsed/distance/pack-nearby on the iPhone lock screen + Dynamic
     Island, auto-mirrored to the watch Smart Stack; App-Intent buttons
     (Stop/Check, executed on the phone) if wanted. Good iPhone feature in
     its own right.
  2. **Companion watch app** (~2-3 wk): SwiftUI + WatchConnectivity remote
     control — Start/Stop, marks grid, haptics; phone keeps GPS/upload.
     Ongoing maintenance tax of a second UI — skippable if Tier 3 is the
     real want.
  3. **Standalone watch tracking** (~4-8 wk, the killer feature: phone
     stays at the bag drop): HKWorkoutSession + watch GPS uploading
     directly — StorePositions is unauthenticated, so the phone only hands
     over eventId+userId at session start; no token gen on the wrist.
     Battery tuning + on-trail testing are the real costs.

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

- [ ] **First request after iOS resume can die on a waking network stack**
  (Opee's device log, 2026-08-15: syncUserData bad-fd transport failures and
  599 local timeouts at app-foreground moments; all self-healed via retry).
  RESOLVED PARTS: this is NOT a pooled-client bug — the resume sync uses
  one-shot http.post; the socket dies because iOS is still waking the network
  stack. The "0.4 ms retry" suspicion was a log-ordering misread (both lines
  describe attempt 1; real retries back off properly). The misleading
  "Unknown Server Error / -" snackbar is fixed (honest timeout/hiccup
  wording, 2026-08-15). REMAINING IDEA if the snackbars annoy: delay the
  resume-triggered background sync a couple of seconds after foregrounding
  so the first attempt doesn't race the network wake-up. Note:
  syncAllUserDataFromBackend threads one Client() through the six boot
  syncs — fine at cold boot (no suspend in between), but don't imitate the
  pattern for anything that can span a suspend.

- [ ] **PackTrack mark-multiplication root cause**: the ×7 moving-track
  bursts from the 2026-06-20 LH3 run were never reproduced (stationary and
  simulator are clean; the batch-retry duplication class was fixed by the
  idempotent StorePositions RowKey, api 1.0.31). Needs the moving-taps
  device test on "Test this Mess" before it can be closed or chased.
- [ ] **Tuna's device RSS peak 892MB** during 1h51m of tracking
  (2026-08-04 log). No crash, but that's high-water for a background
  tracking session — worth a profiling pass if any tracking-session OOM
  reports appear in MetricKit.

### Date-triggered

- [ ] **~2026-10-16 — re-check the hidden crop aspect-ratio button.** The
  image_cropper aspect-ratio preset sheet renders as an empty glass panel on
  iOS 26 (TOCropViewController predates Liquid Glass), so
  `aspectRatioPickerButtonHidden: true` was set at all five `cropImage` call
  sites on 2026-08-16. In two months: check whether an image_cropper release
  (>12.2.1) fixes the iOS 26 sheet; if so, bump it (or fold into the Tier-2
  dependency pass) and remove the five `IOSUiSettings` lines to restore the
  preset picker.

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

## PackTrack

- [x] **Stop⇒On-Inn & auto-stop** (IMPLEMENTED 2026-08-16, shipped blind —
  device tests below; full plan `docs/packtrack_auto_stop_plan.md`). Steps
  ①–③ live in mobile/public-web; step ④ (admin stop-everyone) is coded but
  inert until the API deploy. Still to build from that session: per-slot mark
  cooldown + undo toast (butt-dial double-tap), Tell-the-pack debounce, V2
  "everyone in?" detection.
- [x] **Ignore a mid-track On-Inn at read time** (DESIGN AGREED 2026-08-15,
  IMPLEMENTED 2026-08-16 as step ① of the auto-stop plan — mobile
  `_isTerminalOnInn` + public-web `isTerminalOnInn`, 2-min grace). A trail has exactly ONE On-Inn, at the end —
  an On-Inn followed by later points is always a mistake (runner tapped it,
  then resumed). On LH3 #2846 such a mark truncated 20+ min of live trail
  for every viewer until deleted server-side. Fix: readers (mobile
  `_isOnInn` path in run_tracker_map_controller + public-web viewer) honour
  an On-Inn — as terminator AND as icon — only when it is effectively the
  runner's LAST point (nothing after it beyond a short grace for straggler
  queued fixes). Otherwise ignore it completely: draw through, no icon.
  Zero API calls, no restart race, retroactive, and the open map's cached
  model self-heals as new points arrive (the incremental poll can't express
  deletions). The existing resume strip (DeletePositions) stays as
  best-effort physical cleanup; a `resumed:true` StorePositions flag was
  considered and DEFERRED (tidiness only once the read rule exists).
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


---

# db.md

# DB TODO

## Tier performance comparison — S0 / S1 / S0 (set up 2026-09-01)

Scaled **S1 (20 DTU) → S0 (10 DTU)** at **2026-09-01 ~15:52 UTC** (from
`master.sys.resource_stats`: last 20-DTU sample 15:46:49, first 10-DTU 15:58:16).

- [x] Query Store was at **8 MB of a 10 MB cap** and already size-purging the
      pre-scale week. Now **200 MB / 30-day retention / QUERY_CAPTURE_MODE = ALL**.
- [x] `HC6.nonApi_capturePerfBaseline` snapshots per-proc stats into
      `HC.PerfBaseline`, stamped with the tier **actually in effect during the
      window** — derived from `HC.TierLog`, not from the tier at capture time.
      `HC.TierLog` is self-maintaining: every capture observes the live
      `dtu_limit` and opens a new range when it changes.
- [x] S1 baselines captured: **`S1-night`** (01:00–05:00) and **`S1-day`**
      (07:00–15:00), both 2026-09-01, both post-prune so the data volume
      matches today's.

### The A/B/A plan

Run a few days at S0, scale to S1 for a few days, then back to S0. Capturing
S0 **twice** is what makes this clean — if the two S0 runs agree, any S1
difference is really the tier; if they disagree, workload drifted and the
whole comparison is suspect. A simple before/after cannot tell those apart.

After each phase, capture BOTH a night and a day window:

```sql
EXEC HC6.nonApi_capturePerfBaseline 'S0-run1-night', '<date> 01:00:00 +00:00', '<date> 05:00:00 +00:00';
EXEC HC6.nonApi_capturePerfBaseline 'S0-run1-day',   '<date> 07:00:00 +00:00', '<date> 15:00:00 +00:00';
-- then after scaling up: 'S1-run2-night' / 'S1-run2-day'
-- then after scaling back: 'S0-run3-night' / 'S0-run3-day'
```

Compare like with like:

```sql
SELECT ProcName,
       MAX(CASE WHEN Label LIKE 'S1-%night'      THEN AvgStatementMs END) AS S1_night,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgStatementMs END) AS S0_run1,
       MAX(CASE WHEN Label = 'S0-run3-night'     THEN AvgStatementMs END) AS S0_run3,
       MAX(CASE WHEN Label LIKE 'S1-%night'      THEN AvgLogicalReads END) AS S1_reads,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgLogicalReads END) AS S0_reads,
       MAX(CASE WHEN Label = 'S0-run1-night'     THEN AvgPhysicalReads END) AS S0_physreads
FROM HC.PerfBaseline
WHERE Label LIKE '%night' GROUP BY ProcName ORDER BY ProcName;
```

Rules for reading it:
1. **`TierChangedDuringWindow = 1` means the window spans a scale — discard it.**
2. **Check `AvgLogicalReads` first.** If it differs between windows the two ran
   different work and the duration ratio is meaningless.
3. **`AvgPhysicalReads` is the real risk indicator.** Still ~0 at S0 means the
   working set fits the smaller buffer pool. If it climbs, that is the memory
   cliff and it hurts far more than linearly.
4. **Match the time of day.** Proven necessary: `nonApi_checkReminders` ran
   36.66 ms at night and 29.66 ms by day on the SAME tier with identical reads.
   A night-vs-day comparison invents a 1.24x effect out of nothing.
5. Skip the first hour after any scale — cold buffer pool.

- [ ] When finished, consider setting `QUERY_CAPTURE_MODE` back to `AUTO`;
      `ALL` costs a little overhead on 10 DTU.

## Maintenance jobs — restored 2026-09-01

- [x] **Re-enabled `HC_prune_logs` and `HC_rebiuld_indexes`** (2026-09-01
      05:40 UTC) and ran both manually. All seven workflows are Enabled.
- [x] **Catch-up prune FINISHED** 2026-09-01 00:43:51, 100 micro-prune
      iterations. Oldest log row is now exactly 90 days back. **Used space
      5,812 MB → 2,801 MB of a 10,240 MB cap: 3.0 GB freed.**
- [x] **`HC_prune_logs` Succeeded in 3.6s** — its first ever successful run.
      Steady state fits inside the gateway window comfortably.
- [x] **Index rebuild run — and it reclaimed ~9 MB, i.e. nothing.** The space
      had already been released by the deletes themselves. The prune/rebuild
      scheduling adjacency buys nothing; see the db-log-retention memory.
- [ ] **Optional, not urgent:** `HC.IntegrationJob` is 681 MB for 32k rows
      (~21 KB/row) because of five NVARCHAR(4000) columns, all in-row. A
      rebuild or LOB compaction will NOT shrink it — only a shorter retention
      for that table, or nulling those columns on old rows, would.

## ⚠️ Every long maintenance Logic App reports Failed (pre-existing)

- [ ] `HC_rebiuld_indexes` and `HC_backup_tables` have failed with
      **GatewayTimeout at ~110s every single night** for as long as run history
      goes back — the SQL connector's synchronous limit, well below their
      PT20M/PT30M action timeouts. The work appears to continue server-side
      (backup tables were still being written 8s before the timeout), but the
      Logic App can never report success, so a real failure would be invisible.
      `HC_update_counts_credits` succeeds in 7s and is unaffected.
      Decide: split the SPs into sub-2-minute chunks, or move to a trigger the
      connector can poll asynchronously.

## Contact address

- [x] `connect@harriercentral.com` is dead. Replaced with
      `harriercentral@gmail.com` in 113 live procs across HC3/HC4/HC5/HC6/
      HC_BACKUP (2026-08-31, commit 1e72c262) and in the git baseline.
      Rollback copies in `HC.ProcBackup_20260831_ContactEmail` — drop that
      table once you are happy.

## Run-count guard fix (2026-07-30) — deploy + verify

- [x] **Deploy the symmetric change-guard fix** (`nonApi_updateRunCountsByUser` /
      `ForAllUsers` / `ForEventUsers`) via `./tools/deploy_hc6.sh`. Root cause of
      the ~100k/night "Activity" churn on the usage dashboard: Stage 2 haring
      guards compared the raw window value against the stored CASE-adjusted
      value, so every non-hare row fired on every recompute.
      *Deployed 2026-07-31 04:57 UTC (149 SPs, 0 failures). Read-only replay of
      the new guard predicts tonight's sweep stamps just 4 rows (all genuine
      `TotalHaring` staleness — the one-time convergence "wave"), Stage-3
      clears 0.*
- [x] **Verify the morning after 2026-08-01's 03:10 sweep**: VERIFIED
      2026-08-01 09:59 UTC — HEM rows stamped in trailing 24h = **49** (was
      101,706). Sweep completed in ~21s (03:10:21) vs ~4min pre-fix
      (03:14:02). Usage dashboard Activity row now shows organic numbers.

## HC6 Migration

- [x] Survey all HC6 SPs for calls to non-HC6 SPs originating outside the app/portal
      (Logic Apps, the API shim itself, scheduled jobs, etc.). Known candidates include
      the import-kennel functions. Migrate any remaining dependencies to HC6 so the
      HC3-5 schema artifacts can eventually be cleaned up.


---

# portal.md

# Portal TODO

Items flagged during development that need follow-up.

---

## Permissions editor — grouping + website perms (raised 2026-07-27, bedtime; NOT started)

Straightforward reorg (same safe pattern as prior regroups — `FeatureArea`
UPDATEs + `kSectionGate`, portal-only, no recompile):
- [ ] **Manage Songs → "Kennel Tools"** (currently its own "Songs" group).
- [ ] **Web / Newsletter → "Runs, Events, and Hash Cash"** (gated by View Run
  Admin Tools). NOTE: semantically odd; may get revisited once the portal-gate
  architecture below is sorted — confirm with James before moving.

New portal-only permissions (needs the architecture question resolved first):
- [ ] **Add "Edit Website" and "Design Website" permission functions**, scoped
  to the **portal only** (not the app), under Kennels. Use them to gate the
  Edit Website / Design Website buttons on the portal (Puck page builder).

Deferred architecture question (James: "We'll need to sort this out later"):
- [ ] **App-gate vs portal-gate collision.** Two "kennel admin" gates exist:
  `enterKennelAdmin` = "View Kennel Admin Tools" gates the **app** UI; but the
  portal also needs a "View Kennel Tools (Portal)" gate. Today `FeatureArea` /
  `GrantorType` don't distinguish app-scope vs portal-scope. Decide how to model
  platform scope (new column? new GrantorType? separate function sets?) before
  building the website perms — otherwise a portal-only perm leaks into app
  gating logic (`canAccessFeature`) or vice-versa. Discuss with James.

---

## Security / Auth

- [ ] **`hcportal_getLoginHistory` — missing scope check**
  Any authenticated portal user can pass any `@userId` and read that person's
  login history. `@hasherId` and `@callerType` are returned by `ValidatePortalAuth`
  but unused in this SP.
  Fix: add a check that `@userId` is a member of a kennel where the caller
  (`@hasherId`) has admin rights. Service accounts (`@callerType` 1 or 2) bypass.
  See conversation: 2026-05-16.


---

# public-web.md

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


---

# api.md

# API TODO

Items flagged during development that need follow-up.

---

*(none yet)*
