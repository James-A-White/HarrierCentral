# Harrier Central — Product Backlog

**This file is the source of truth.** `docs/backlog.html` is a rendered snapshot of it,
published as an artifact for reading and sharing; it carries its own "status as at" date
and is refreshed on request, so a stale snapshot is visible rather than misleading.

Epics are organised by **what a hasher is trying to do, not by which codebase serves it** —
almost every feature spans three surfaces at once. IDs (`E5.F3.S4`) are stable: quote them
when assigning work to an agent, and never renumber an existing one. New work appends.

This replaced the `todos/` files on 2026-09-08. Bugs and individual work items now live in
**GitHub Issues**; this file is the map of what the product does, issues are the work queue.
Device-test checks moved to `docs/verification-backlog.md`, and the old files' reasoning and
shipped record to `docs/history/todos-archive-2026-09.md`.

`docs/backlog.html` is generated — run `python3 tools/render_backlog.py` after editing.

| Status | Meaning |
|---|---|
| `Shipped` | In production |
| `Building` | In flight now |
| `Next` | Designed, not built |
| `Backlog` | Not yet designed |

**Version names changed on 2026-09-19.** The stabilisation train that was `3.0.x`
is now **3.1**, because the release carrying 3.0.13–3.0.44 is far too large to be a
point release; the payments train that was `3.1` is now **3.2**. Forward-looking tags
in this file say 3.1 and 3.2 with those meanings. **Build identifiers quoted in the
stories below are historical and were NOT rewritten** — a build named `3.1.0+1380` was
genuinely uploaded to TestFlight under that name, and renaming it here would make this
file lie about what shipped. Read any `3.1.0+NNNN` below 1386 as the old payments
train, and any `3.0.x+NNNN` as what is now 3.1.

Surface tags: `App` (Flutter mobile) · `Portal` (Flutter web admin) · `Web` (Next.js public)
· `API` (Azure Functions shim) · `DB` (SQL Server stored procedures)

## Personas

Six roles, each with a distinct mechanism behind it. The two that get confused most often are **mismanagement** and **kennel admin**: they are independent grantor bitfields on `HC.HasherKennelMap`, and a function is allowed if **either** grants it. Somebody can run Harrier Central for their kennel while holding no club office at all.

| Persona | Mechanism | Description |
|---|---|---|
| **Visitor** | `no account` | Finds a kennel through the public web or guest discovery. Sees run calendars, trails and club info. Can be checked in to a run as a visitor without ever registering. |
| **Hasher** | `registered member` | Has an account and follows one or more kennels. Their membership is kennel-scoped, so the same person can be a member of six kennels with different standing in each. |
| **Hare** | `run-scoped` | Set the trail for one specific run. Held on `HasherEventMap.IsHare` and granted only for that event — it is the one permission that is not kennel-wide. |
| **Mismanagement** | `MismanagementRoles` | The club offices: Grand Master/Mistress, Vice GM, Religious Advisor, Hash Cash, Hare Raiser, Hash Flash. A bitfield of ceremonial titles that **may** also grant system functions. |
| **Kennel HC Admin** | `AppAccessFlags` | Runs Harrier Central for a kennel. A separate bitfield from mismanagement and frequently held by someone with no club office. Note `IsAdmin (0x01)` is not a bypass; `SuperAdmin (0x40000000)` is the only per-kennel one. |
| **Platform Admin** | `HC.PlatformAdmin` | Opee and Tuna Melt only. Four independent capabilities — `CanViewMonitor`, `CanManageNewsflash`, `CanEditKennel`, `CanManagePermissions` — and the last is held by Opee alone. |

---

## E1 — Identity & Account Access

Getting a hasher into the app and back into it after they change phones — without a password, because the club's own recovery route is an invite code and a hash name, not an email and a secret.

### E1.F1 · Device-bound authentication  
`App` `Portal` `API` `DB`

> A device secret plus a per-device time window mints a 30-second SHA-256 token for every call. There is no password anywhere in the system.

| ID | Story | Status |
|---|---|---|
| `E1.F1.S1` | As a **Hasher**, I want my phone registered once so that every later call authenticates without me signing in again. | `Shipped` |
| `E1.F1.S2` | As a **Hasher**, I want sensitive calls bound to the specific operation so that a captured token cannot be replayed against a different target or amount. | `Shipped` |
| `E1.F1.S3` | As a **Hasher** whose phone clock has drifted, I want to be told to turn on automatic time rather than to reinstall, so that I can actually fix it. | `Shipped` |
| `E1.F1.S4` | As a **Hasher**, I want the server to tolerate a couple of time blocks either side so that ordinary latency does not lock me out. | `Shipped` |
| `E1.F1.S5` | As a **Hasher** on a second device, I want to approve the new device from the one I already trust so that I am not locked out of my own account. | `Shipped` |
| `E1.F1.S6` | As a **hasher**, I want my device's credential to stay on that device, so that restoring a phone backup onto somebody else's hardware does not hand them my account (James, 2026-09-20, asking why the Android emulator already knew who he was). **The answer that time was innocent** — the emulator had the app installed since 2025-11-09 and `flutter run` updates in place rather than reinstalling, so the old session's prefs were simply still there. **The question it exposed is not.** `android/app/src/main/AndroidManifest.xml` sets no `android:allowBackup` and no `dataExtractionRules`, so Android's default of `allowBackup="true"` applies, and `deviceSecret` lives in plain `SharedPreferences` (`StringPrefsEnum.deviceSecret`), not in secure storage. Google Auto Backup can therefore carry a working device secret to Drive and restore it onto a **different physical device**, which then authenticates with no sign-in, no email code and no passkey — two devices, one credential, one `HC.Device` row. That contradicts `E13.G1.R1`, which promises identity is a *device-bound* shared secret. **Mitigations that already exist, so this is a hole not a fire:** `FlutterSecureStorage` items are encrypted with a Keystore key that never leaves the device, so those restore as undecryptable blobs; and because both devices share one row, E9.F7.S19's sign-out revokes the copy as well as the original. **Three ways to close it, in increasing order of merit:** (a) `android:allowBackup="false"` — blunt, and costs a legitimate new-phone setup its session; (b) `dataExtractionRules` excluding the credential keys — keeps backup for everything else; (c) **move `deviceSecret` into `FlutterSecureStorage`**, which makes backup irrelevant because the restored copy cannot be decrypted, and needs a one-boot migration for installs that already hold it in prefs. **iOS needs the same review** — `NSUserDefaults` is in iCloud backup, and keychain items restore to a new device unless written with `ThisDeviceOnly` accessibility. Deliberately NOT fixed before the 3.1.0 store push (James, 2026-09-20: "I want to ship the current version into production"); scheduled for the **3.2** train. | `Next` |
| `E1.F1.S7` | As a **Hasher** whose phone clock is wrong by minutes or hours, I want the app to correct for it and keep working, rather than every call failing with an invalid token, so that a bad clock is not a broken app (James, 2026-10-01). 35 invalid-token errors from 10 hashers in the 30 days to 2026-10-01. **Proposed (under discussion):** on an invalid-token reply the app asks the server for its UTC time (the `checkConnection` short-circuit in the shim, or the HTTP `Date` header every reply already carries), computes the offset, and — when it is between ~30 s and ±12 h — stores it per device and adds it to the time it mints tokens with, then retries once. The server's token check is unchanged, so the replay window stays what it is; outside ±12 h the existing "turn on automatic time" message (S3) stands. Each correction is logged to `HC.ErrorLog` with the offset so drift is visible in triage. **Decided (James, 2026-10-01):** the offset is kept per device on the phone, never on `HC.Hasher`; the first correction shows a quiet one-time notice, worded from the measured offset and direction: *"Your phone's clock is 1 hour and 36 minutes ahead of Coordinated Universal Time. If you are experiencing problems with some of your apps, you may want to consider setting your phone to set the clock automatically from an internet time source."* ("behind" when slow; minutes only under an hour.) **Built 2026-10-01:** `lib/util/clock_offset.dart` — learns from the invalid-token reply's HTTP `Date` header (no SP or API change), measured against the raw clock each time so a fixed clock heals itself; logged as `[ERROR][CLOCK]` in the client log harvest. ⚠ Known gap: not device-tested (needs a phone with its clock set wrong). | `Building` |

### E1.F2 · Self-service signup  
`App` `API` `DB`

> The path a brand-new hasher takes with nobody helping them. Broken in five stacked ways until 2026-09-07; admin-created accounts had masked it for months.

| ID | Story | Status |
|---|---|---|
| `E1.F2.S1` | As a **Visitor**, I want to create an account from first name, last name, hash name and email so that I can start using the app the day I hear about it. | `Shipped` |
| `E1.F2.S2` | As a **Visitor**, I want the signup screen to have a visible way forward so that I am not stranded on the form. | `Shipped` |
| `E1.F2.S3` | As a **Visitor** creating my first account, I want the call to be allowed before I have any credentials so that account creation is not gated on being authenticated. | `Shipped` |
| `E1.F2.S4` | As a **Visitor** whose email is already registered, I want to be told that and offered recovery so that I do not create a duplicate. | `Shipped` |
| `E1.F2.S5` | As a **Visitor**, I want a random bundled avatar assigned so that I have an identity before I upload anything. | `Shipped` |
| `E1.F2.S6` | As a **Visitor**, I want to sign up with Apple or Google so that I do not have to type my details on a phone. | `Shipped` |

### E1.F3 · Account recovery by invite code  
`App` `API` `DB`

> Every hasher permanently holds a compliant `URC:AAAAAA` code. It is the only recovery route, so a user without one is locked out of their own account.

| ID | Story | Status |
|---|---|---|
| `E1.F3.S1` | As a **Hasher** on a new phone, I want to enter my invite code and get my account back so that I keep my history and run counts. | `Shipped` |
| `E1.F3.S2` | As a **Hasher**, I want a fresh code minted automatically whenever mine is missing or malformed so that I am never told my account has no invite code. | `Shipped` |
| `E1.F3.S3` | As a **Hasher**, I want my code emailed to me on request, rate-limited so that repeated taps do not invalidate the one I was just sent. | `Shipped` |
| `E1.F3.S4` | As a **Hasher** who cannot remember which email I used, I want to search for myself by hash name so that I can identify my own account. | `Shipped` |
| `E1.F3.S5` | As a **Kennel HC Admin**, I want to send invite codes to my whole roster at once so that I can onboard a club in one go. | `Shipped` |

### E1.F4 · Profile & preferences  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E1.F4.S1` | As a **Hasher**, I want to set a profile photo from my camera, my library or the bundled avatar set so that the pack recognises me on the map. | `Shipped` |
| `E1.F4.S2` | As a **Hasher**, I want to control which emails and push notifications I receive so that the app is not noisy. | `Shipped` |
| `E1.F4.S3` | As a **Hasher**, I want a QR code identifying me so that Hash Cash can check me in without typing. | `Shipped` |

### E1.F5 · Guest & visitor access  
`App` `Web`

| ID | Story | Status |
|---|---|---|
| `E1.F5.S1` | As a **Visitor**, I want to browse upcoming runs worldwide before registering so that I can find a hash while travelling. | `Shipped` |
| `E1.F5.S2` | As a **Visitor** at a run, I want to be checked in as a guest so that I count in the attendance without creating an account. | `Shipped` |

### E1.F6 · Leaving the platform  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E1.F6.S1` | As a **Hasher**, I want to delete my account and personal data on request so that I can exercise my rights under GDPR. | `Shipped` |
| `E1.F6.S2` | As a **Hasher**, I want to log out and have the app return to a clean first-run state so that the next person on this phone sees nothing of mine. | `Shipped` |

---

## E2 — Kennels, Membership & Permissions

A hasher belongs to many kennels with different standing in each, and every permission decision is scoped to one of them. This epic owns the authorisation model the whole platform depends on.

### E2.F1 · Finding and following a kennel  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E2.F1.S1` | As a **Hasher**, I want to search kennels by name, city, region or country so that I can find my local hash. | `Shipped` |
| `E2.F1.S2` | As a **Hasher**, I want search to also match a kennel's own search tags so that "Scotland" finds kennels that are not filed under a Scotland region. | `Shipped` |
| `E2.F1.S3` | As a **Hasher**, I want following a kennel to pull down its full run history so that I can see everything, not just the last ten days. | `Shipped` |
| `E2.F1.S4` | As a **Hasher**, I want to join a kennel as a member so that my runs there count toward my totals. | `Shipped` |

### E2.F2 · The member roster  
`App` `Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E2.F2.S1` | As a **Kennel HC Admin**, I want to see every member with their run count, standing and contact details so that I can manage the club. | `Shipped` |
| `E2.F2.S2` | As a **Kennel HC Admin**, I want to add a hasher who is not yet on the platform so that I can register someone at the run. | `Shipped` |
| `E2.F2.S3` | As a **Kennel HC Admin**, I want to bulk-import a roster so that I can migrate an existing club without typing every member. | `Shipped` |
| `E2.F2.S4` | As a **Kennel HC Admin**, I want the roster on a desktop to be a dense grid and on a phone to be cards so that each is usable on its own screen. | `Shipped` |

### E2.F3 · Mismanagement roles  
`App` `Portal` `DB`

> GM, Vice GM, Religious Advisor, Hash Cash, Hare Raiser, Hash Flash — a bitfield on `HasherKennelMap` that is both a club office and, optionally, a permission grantor.

| ID | Story | Status |
|---|---|---|
| `E2.F3.S1` | As a **Kennel HC Admin**, I want to assign club offices to members so that the roster reflects who actually runs the hash. | `Shipped` |
| `E2.F3.S2` | As a **Hasher**, I want to see who to contact for what so that I know who the Hash Cash is before I turn up with no money. | `Shipped` |
| `E2.F3.S3` | As a **Kennel HC Admin**, I want to hold admin rights without holding any club office so that whoever is willing to run the software can do so. | `Shipped` |

### E2.F4 · Data-driven permissions (V2)  
`Portal` `DB`

> One authorizer, `CheckKennelPermission`, resolving a function key against role and flag grantors with a per-kennel tri-state override.

| ID | Story | Status |
|---|---|---|
| `E2.F4.S1` | As a **Platform Admin**, I want every kennel-scoped feature gated by one authorizer so that there is a single place a permission bug can live. | `Shipped` |
| `E2.F4.S2` | As a **Platform Admin**, I want a kennel to be able to grant or revoke a function against the global default so that clubs can differ without a code change. | `Shipped` |
| `E2.F4.S3` | As a **Platform Admin**, I want to edit the permission matrix in the portal so that changing who can do what is not a deployment. | `Shipped` |
| `E2.F4.S4` | As a **Hare**, I want edit rights on my own run only so that setting a trail does not make me an administrator of the club. | `Shipped` |

### E2.F5 · Member standing  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E2.F5.S1` | As a **Hash Cash**, I want a member's paid-up standing computed from their payment history so that I do not track subscriptions on paper. | `Shipped` |
| `E2.F5.S2` | As a **Hash Cash**, I want standing swept nightly so that a lapsed membership shows as lapsed without anyone touching it. | `Shipped` |
| `E2.F5.S3` | As a **Kennel HC Admin**, I want a richer standing model covering honorary, life and suspended members so that the roster matches how clubs actually work. | `Next` |

---

## E3 — Runs & the Calendar

The run is the atom of the whole platform. Creating one, finding it, getting to it, and keeping its numbering straight across a club that has been running for thirty years.

### E3.F1 · Creating and editing a run  
`App` `Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E3.F1.S1` | As a **Hare Raiser**, I want to create a run with date, time, location, hares and fees so that the pack knows where to turn up. | `Shipped` |
| `E3.F1.S2` | As a **Hare Raiser**, I want to schedule a recurring run so that I am not creating the same Monday trail every week. | `Next` |
| `E3.F1.S3` | As a **Hare**, I want to edit my own run's details up to the start so that late changes reach the pack. | `Shipped` |
| `E3.F1.S4` | As a **Hare Raiser**, I want to cancel a run with a reason so that nobody drives to a trail that is not happening. | `Shipped` |
| `E3.F1.S5` | As a **Hare Raiser**, I want the run's start time stored as both an instant and a wall clock so that a trail in another timezone displays correctly in both places. | `Shipped` |

### E3.F2 · Locations & the gazetteer  
`App` `API` `DB`

| ID | Story | Status |
|---|---|---|
| `E3.F2.S1` | As a **Hare**, I want to pick a country, then region, then city in a cascade so that I cannot file a run in a city that is not in that country. | `Shipped` |
| `E3.F2.S2` | As a **Hare**, I want to drop a pin or search an address so that the start is exact rather than approximate. | `Shipped` |
| `E3.F2.S3` | As a **Hasher**, I want one tap to open the run start in my own maps app so that I can navigate there. | `Shipped` |
| `E3.F2.S4` | As a **Hare**, I want the timezone inferred from the location so that I do not have to know it. | `Shipped` |

### E3.F3 · Browsing runs  
`App` `Web`

| ID | Story | Status |
|---|---|---|
| `E3.F3.S1` | As a **Hasher**, I want upcoming runs across every kennel I follow in one list so that I can plan my week. | `Shipped` |
| `E3.F3.S2` | As a **Hasher**, I want a run I attended today to stay above the next one so that I can still do my post-run admin. | `Shipped` |
| `E3.F3.S3` | As a **Hasher**, I want a run to move to the past six hours after it starts so that the app and the database always agree which side of the line it is on. | `Shipped` |
| `E3.F3.S4` | As a **Hasher**, I want to filter runs by kennel, date range and distance from me so that a long list stays usable. | `Shipped` |
| `E3.F3.S5` | As a **Hasher** with a slow connection, I want the cached list shown while the sync runs so that I never see "No runs" on a list that is still loading. | `Shipped` |
| `E3.F3.S6` | As a **Hasher**, I want a past run's card to show whether it has a PackTrack track, photos, chat and down-downs so that I can tell which runs have something to look at without opening each one. | `Shipped` |
| `E3.F3.S7` | As a **Hasher**, I want the PackTrack icon on a past run's card to say how many runners recorded a track so that I know whether there is a pack to replay or one lone trail. `TrackFirstPointAt` / `TrackLastPointAt` / `TrackPointCount` on the runner's own `HC.HasherEventMap` row (the app checks the tracker in as tracking starts, so the row exists), written by StorePositions (the `updatedAt` trigger ignores a track-only write), backfilled from GetPositions. | `Shipped` |

### E3.F4 · The run detail view  
`App` `Portal` `Web`

| ID | Story | Status |
|---|---|---|
| `E3.F4.S1` | As a **Hasher**, I want everything about a run on one screen — map, hares, fees, on-after, who is coming — so that I do not have to hunt. | `Shipped` |
| `E3.F4.S2` | As a **Kennel HC Admin**, I want a desktop rendering and a phone rendering of run detail so that neither is a compromise. | `Shipped` |
| `E3.F4.S3` | As a **Hasher**, I want to share a run to the interactive map, Trail TV or the photo gallery so that I can post it to the club's group chat. | `Shipped` |
| `E3.F4.S4` | As a **Hasher**, I want the shared link to preview with the run's own image so that it does not land as a bare URL. | `Shipped` |
| `E3.F4.S5` | As a **Hasher**, I want private notes on a run — mine to write, and filled in from a Strava title and description when I import a track — so that I can look back at what a run was like. `HasherEventMap.Notes` (NVARCHAR(4000), plain text — gzip was considered and rejected: notes are a few hundred bytes, gzip adds more than it saves at that size, and binary would break search, sync and readability), synced to the owner only. Written by `hcapp_setEventNotes` from a My notes section on the run detail page; the import processor fills it with the file's title and description whenever it matches a run and the note is blank, including a run tracked by phone — a note the hasher wrote is never overwritten. Sharing (James, 2026-09-11): a per-run flag `NotesVisibility` (0 private, 1 shared — a switch on the notes box) and two overrides for content rules, both bits on existing fields so no further ALTER: a Kennel HC Admin hides everything a hasher shares in that kennel (`HasherKennelMap.KennelStanding` & 0x1000, from the member menu), and a Platform Admin hides it everywhere (`HC.Hasher.Preferences` & 0x2000, `hcportal_setHasherNotesSuppression`). A note is public only when all three agree; the kennel and event syncs carry only notes that are, plus a `notesShared` flag so the owner sees when an override applies. The HEM columns ride one ALTER with the trigger disabled, James's run. Shipped 2026-09-11: ALTER run (trigger disabled, no rows stamped), SPs and API 1.0.45 live, app 3.0.23 on TestFlight and Play internal. **⚠ Known gap:** no portal screen for the platform override yet (SP only); the public web does not show shared notes yet (E11.F2.S6); the notes box, the share switch, the member-menu actions, the migration to 528 and the import fill await their first device run. 2026-09-12, on dev: the notes an archive fills now carry the athlete's private note and a one-line stats summary (gear, moving and elapsed time, heart rate, climb, calories, effort, steps, weather) under the title and description, and a re-import extends an earlier fill without touching anything the hasher wrote. | `Shipped` |
| `E3.F4.S6` | As a **Hasher**, I want a button on the run map that opens the run in my map app, as tapping its pin does — **Get me there** on the day of the run, **Get Directions** on any day before it — so that I do not have to copy the address into another app. No button the day after or later, none once the run has PackTrack data (the map is a trail by then; synced `TrackRunnerCount`, or tracks the map has loaded, since the count lags a live run), and none when the run has no coordinates. Same action as the pin: the saved map app, or the chooser. `runDirectionsFor` in `run_recency.dart` (unit-tested), `RunTrackerMap.bottomOverlay`. **Built 2026-09-26 on dev** — ⚠ Known gap: not yet seen on a device. | `Building` |

### E3.F5 · Run numbering  
`DB`

> Clubs number their runs continuously, sometimes into the thousands. Inserting a forgotten historical run has to renumber everything after it.

| ID | Story | Status |
|---|---|---|
| `E3.F5.S1` | As a **Kennel HC Admin**, I want run numbers recalculated when I insert a historical run so that the sequence stays continuous. | `Shipped` |
| `E3.F5.S2` | As a **Kennel HC Admin**, I want renumbering to happen inside the same transaction as the write so that a failure cannot leave two runs sharing a number. | `Shipped` |
| `E3.F5.S3` | As a **Kennel HC Admin**, I want to override a run's number by hand so that a club with an idiosyncratic history can still be represented. | `Shipped` |

### E3.F6 · Calendar integration  
`API` `Web`

| ID | Story | Status |
|---|---|---|
| `E3.F6.S1` | As a **Kennel HC Admin**, I want our runs pushed to the club's Google Calendar so that members who live in their calendar still see them. | `Shipped` |
| `E3.F6.S2` | As a **Hasher**, I want to subscribe to a kennel's runs as a feed so that they appear in my own calendar automatically. | `Backlog` |
| `E3.F6.S3` | As a **Kennel HC Admin** whose club lists its runs on its own website, I want to give Harrier Central the address of that page so that our runs appear in Harrier Central without anyone typing them in twice (James, 2026-10-04, tried on Sydney H3's sh3.link). Portal kennel editor › Runs Page (`HC.Kennel.RunsPageUrl`, with the last read's status beside it). The API's `RunsPageImport` timer (00:07, 06:07, 12:07, 18:07 UTC) fetches each page, fingerprints its text and calls Azure OpenAI (`harriercentral-openai`, deployment `runs-page` = gpt-4.1-mini, strict JSON schema) ONLY when the text changed — about 1,900 tokens a read; map short links are resolved to coordinates by following their redirects. `HC6.nonApi_importRunsPageRuns` writes them the way every inbound integration does (Fb* mirror + UseFb* flags, `InboundIntegrationId` 6, `EventFacebookId` 'runspage:<n>'): new numbers become runs, a number the kennel already has from any other source is left alone, an imported run's mirror is refreshed and its start time / hares only while unedited; nothing is deleted. Kennel bookkeeping (`RunsPageCheckedAt`) never stamps the kennel row. `POST /api/RunsPageImportNow` (X-Api-Key) runs one kennel now. **Test this page** in the editor (`/api/RunsPageTest`, portal token bound to the kennel + createEditRuns): reads the address on screen now, shows every run found and what importing would do (a dry run: `nonApi_importRunsPageRuns @dryRun=1` rolls back to a savepoint), and imports only on "Import these runs". The kennel editor's **Inbound Integration** drop-down (`HC.Kennel.InboundIntegrationId` = 6, "Runs page (AI)") is the switch; `HC.Integration` 6's Enabled flag only drives the monitor tile (James, 2026-10-05). Timer every 15 minutes: a kennel is read each tick on a run day (a run on its local today) and every ~6 h otherwise — the fetch is ~18 KB and the model runs only on changed text (sh3.link sends no ETag/Last-Modified, so a HEAD cannot replace the fetch). The monitor's **Runs page** tile replaced Facebook: new / updated runs over 14 days from `HC.IntegrationJob` rows (`nonApi_recordRunsPageJob`), kennels using it. Model calls are logged per call to `LOG.AiUsage` (E14.G3.R7). The 2026-10-05 changes are live (API +75, portal 741, SP 34, app 1448 shows the AI run icon). Errors land in `HC.ErrorLog` by stage (`Runs page fetch/model/DB/config failed`, `Runs page output suspect`); every model call logs tokens to `LOG.GeneralLog` 'runsPageModel'. Shipped 2026-10-04 (API 1.0.61+74, portal 2.0.87+740, SP build 33). Live 2026-10-05 for Sydney H3, Sydney Thirsty, London, City and West London (the Hague's page shows HC's own list). Run starts without a map link are geocoded with Azure Maps (`harriercentral-maps`; the AI writes a full `geoQuery`; kept only when High, or Medium on a full postcode, and within 60 km of the kennel's city). First kennel: Sydney H3 (SH3-AU) — first read imported runs 3094-3098 for 1,957 tokens ($0.0013). ⚠ Known gap: the timer imports without approval (the Test button is the preview); Google Calendar / iCal feeds (no AI needed) not built. | `Shipped` |

---

## E4 — Attendance & Check-In

Who said they were coming, who actually turned up, and how the Hash Cash records forty people in the ten minutes before the circle. Two separate state machines that must never be conflated.

### E4.F1 · RSVP  
`App` `Web` `DB`

> RSVP is intent — No / Maybe / Yes. Attendance is fact. They are different enums and conflating them has caused real bugs.

| ID | Story | Status |
|---|---|---|
| `E4.F1.S1` | As a **Hasher**, I want to say whether I am coming so that the hares know how much beer to buy. | `Shipped` |
| `E4.F1.S2` | As a **Hasher**, I want no RSVP controls on a run that has already happened so that I am not asked about a decision I can no longer make. | `Shipped` |
| `E4.F1.S3` | As a **Hasher**, I want to RSVP to several runs at once so that a weekend away is one action. | `Shipped` |
| `E4.F1.S4` | As a **Hare Raiser**, I want to copy the RSVP list from one run to another so that a recurring group does not re-declare every week. | `Shipped` |

### E4.F2 · Checking the pack in  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E4.F2.S1` | As a **Hash Cash**, I want to check people in from a searchable list of members and recent visitors so that I can work fast at the start. | `Shipped` |
| `E4.F2.S2` | As a **Hash Cash**, I want to scan a hasher's QR code to check them in so that I do not have to find them in a list. | `Shipped` |
| `E4.F2.S3` | As a **Hash Cash**, I want to check in a whole group in one action so that a visiting kennel is not forty separate taps. | `Shipped` |
| `E4.F2.S4` | As a **Hash Cash**, I want check-in to work with no signal and sync later so that a trail in a field is not a blocker. | `Shipped` |

### E4.F3 · Self check-in  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E4.F3.S1` | As a **Hasher** standing at the start, I want to check myself in so that I do not queue at the Hash Cash. | `Shipped` |
| `E4.F3.S2` | As a **Hasher**, I want to be prompted to check in when I arrive at the start around the right time so that I do not forget. | `Shipped` |
| `E4.F3.S3` | As a **Hasher** at a free run, I want the button to say "Check In" rather than anything about paying so that a zero fee does not read as a charge. | `Shipped` |
| `E4.F3.S4` | As a **Hasher** who is not logged in but is at the start at the right time, I want the run tools offered so that I can still join in. | `Shipped` |
| `E4.F3.S5` | As a **Hasher** who starts tracking, I want my RSVP set to attending and my attendance set to at-hash so that one action does not leave three records disagreeing. | `Shipped` |

### E4.F4 · Post-run attendance claims  
`App` `DB`

> Replaces the RSVP controls that used to linger on past runs. A claim is a request, not a fact, until a kennel admin approves it.

| ID | Story | Status |
|---|---|---|
| `E4.F4.S1` | As a **Hasher** who forgot to check in, I want to claim I was there so that my run count is right. | `Next` |
| `E4.F4.S2` | As a **Kennel HC Admin**, I want to be prompted to approve or decline a claim so that run counts cannot be inflated unilaterally. | `Next` |

---

## E5 — PackTrack Live Tracking

Recording where the pack went and playing it back. Tracks live in Azure Table Storage rather than SQL, which is why no stored procedure knows a run was ever tracked.

### E5.F1 · Recording a trail  
`App` `API`

| ID | Story | Status |
|---|---|---|
| `E5.F1.S1` | As a **Hasher**, I want to start tracking from the run tools so that my trail is recorded without any setup. | `Shipped` |
| `E5.F1.S2` | As a **Hasher**, I want to choose Best, Balanced or Power Saver so that I can trade precision against battery on a long trail. | `Shipped` |
| `E5.F1.S3` | As a **Hasher**, I want tracking to continue with the app in my pocket so that I do not have to keep the screen on. | `Shipped` |
| `E5.F1.S4` | As a **Hasher** out of signal, I want points buffered and sent when I reconnect so that a trail through a valley is not lost. | `Shipped` |
| `E5.F1.S5` | As a **Hasher**, I want tracking to stop itself when I have clearly finished so that my phone is not tracking me home. | `Shipped` |
| `E5.F1.S6` | As a **Hasher**, I want the app to draw no meaningful battery when I am not tracking so that it is not blamed for a flat phone. | `Shipped` |
| `E5.F1.S7` | As a **Hasher**, I want to start, mark and stop from an Apple Watch so that I do not have to take my phone out on trail. | `Next` |
| `E5.F1.S8` | As a **Hasher**, I want to arm tracking before the run and have it start by itself when I set off, so that I do not have to remember to press Start at the start (James, 2026-09-27). From T−2h Live Run offers **Auto start when I set off**; arming sets RSVP Yes and starts a background stream at the tap (iOS low power until T−5, then precise; Android precise from the tap, never re-subscribed in the background). A 15-minute ring feeds `AutoStartDetector`: with the run's start point, arrive within 200 m then be >150 m from it for 60 s; the track backfills 60 s before the crossing and nothing earlier leaves the phone. Tracking keeps the armed stream. Disarms if not at the start by T+30, and at T+2h. **Built 2026-09-27, 3.1.8+1415** — ⚠ Known gap: field-tested only from today (Black Death #200); the Android notification keeps the "Auto start armed" text once tracking; battery over a 2-hour arm unmeasured. | `Building` |
| `E5.F1.S9` | As a **Hare**, I want auto start to begin my track when I leave the start, whenever that is, so that the trail is recorded from its first metre without pack timing. Anchored on the run's start point when it has one (arming at home is fine), else on where the hare arms; precise from arming; no T−5 gate and no T+30 disarm. **Built 2026-09-27, 3.1.8+1415** with `E5.F1.S8`. | `Building` |
| `E5.F1.S10` | As a **Hasher** who RSVP'd Yes or is checked in, I want a push ten minutes before the run that opens Live Run ready to arm auto start, so that I do not have to remember to open the app. Server: `nonApi_checkReminders` sends it at T−10 in place of the check-in reminder for RSVP-Yes / At Hash hashers, with the same preference gate (`IN (1,3,4)`: muted gets the silent push, never-set gets nothing) and once-per-event stamp; only to devices on the build that understands it, others keep the check-in reminder. App: a new message type whose tap opens Live Run. **Built 2026-10-03 (James):** `nonApi_checkReminders` adds MessageType 3 "Get PackTrack ready" at the check-in moment (~10 min before) for hashers who said RSVP Yes or are checked in, unless their bell for the run or kennel is off — they get it INSTEAD of the generic check-in reminder; no 100 km fence. Sent only to builds >= 1439 (older apps read 3 as chat and keep the old reminder). The tap opens Live Run, checks them in if they only said Yes and are within the 1-mile auto check-in geofence, and arms auto start through the Live Run path (pre-flight included). The API now matches reminder recipients on MessageId (one run, two messages). **Deploy order: API before SPs**, or older apps would also get the new message. ⚠ Known gap: not deployed or device-tested. | `Building` |
| `E5.F1.S15` | As a **Hasher** who has armed auto start, I want the phone's own motion sensing to start my track the moment I set off on foot from the start, so that it starts sooner than the 150 m / 60 s GPS rule and never because I drove away (James, 2026-10-01: "I just want it to trigger the auto start for now"). The OS activity APIs, not raw accelerometer: iOS Core Motion `CMMotionActivityManager` (motion coprocessor, near-zero battery), Android Activity Recognition Transition API. While armed and within 200 m of the start: walking OR running ("on foot" — hashing is not a steady run) starts tracking, with the existing ring backfill; "in a vehicle" vetoes a start. The GPS departure rule stays as the fallback when permission is refused or the API is unavailable. Permission (iOS Motion & Fitness, Android Physical activity) is asked only when auto start is first armed. Scope is START only — no auto-pause, auto-stop or GPS throttling from activity. **Built 2026-10-01:** own native bridge (`harrier_central/activity`; iOS `MotionActivityBridge` in AppDelegate.swift, Android Play Services `ActivityRecognition` in MainActivity.kt — the pub plugin needs Flutter 3.44 + SwiftPM), pure `MotionStartRule` (8 unit tests), the GPS detector's `blocked` flag for the vehicle veto; `[AutoStart] motion:` and `set off (by motion|gps)` breadcrumbs. ⚠ Known gap: compiled for both platforms and unit-tested; not yet run on a phone — a motion trigger can only be tested by walking. | `Building` |
| `E5.F1.S16` | As a **Hasher** on Android, I want my trail recorded as finely as an iPhone records it, so that corners and checks are where I ran them (James, 2026-10-02). Android asked for a fix every 15 s, about 40 m between points at running pace, against iOS's 5 m distance filter; it now asks every 5 s on every tier (one plain point per 5 s kept), as iOS records the same on every tier. With high accuracy at intervals this short the receiver stays on regardless, so a longer interval saved little; the tiers' battery saving stays in the background upload cadence (`E5.F1.S14`). iOS is unchanged at 5 m — James asked about 2 m and decided against it, as phone GPS is only good to 3-5 m and finer spacing records the wander. ⚠ Known gap: built 2026-10-02, not deployed or device-tested; battery on Android to be checked from [METRICS]. | `Building` |
| `E5.F1.S11` | As a **Hasher** who has just ended their run, I want a card with my own distance and time, the checks I went through (of how many were marked), the drink stops I reached and the time I spent at them, so that I see my run, not someone else's. Checks and drink stops are read from every runner's marks, merged within 25 m, reached within 20 m (the map's rule), or placed by me; drink-stop time is the time my track stayed within 40 m. The map and rose now select me by default once my own track arrives (runner ids were compared case-sensitively, and a first-runner fallback stuck). Shipped to TestFlight/Play internal in 1416. A **My run summary** button on the run's Map tab and the full-screen map brings the card back for any run you tracked, worked out from your recorded track (in 1417). **⚠ Known gap:** an auto-stop or admin stop shows no card at the moment it happens — the map button is the way back to it. | `Building` |
| `E5.F1.S12` | As a **Hasher** looking at my run card, I want my running time and running pace with the drink stops taken out, so that I see how fast I actually ran rather than how long the pub took. "Running time" (shown when there were drink stops) and "Running pace" (per km or per mile, `formatPace`, same unit rule as distances) under the drink stops; values shrink rather than overflow. Built 2026-09-28. **⚠ Known gap:** not released (next app build). | `Building` |
| `E5.F1.S13` | As a **Hasher** tracking a run, I want the app to tell me when my phone cannot record a trail — and why — so that I find out at the start line, not from an empty map afterwards (James, 2026-09-30). City H3 #1941: of five tracks, one was on Power Saver (15 fixes in an hour), one had Location set to *While Using* (a 27-minute hole with the app in the background), one stopped early — and the one genuinely noisy phone was handled by the smoothing. Four parts: (1) a pre-flight when tracking starts — iOS Always + Precise, Low Power Mode; Android background location, battery optimisation, and a Power Saver warning with a one-tap switch to Best; (2) a live signal light on the Live Run page (age and accuracy of the last fix, a buzz after two minutes of silence); (3) on return to the foreground, a note when tracking had a gap over two minutes; (4) a track-health line on the run summary. **Deployed 2026-09-30:** app 3.1.8+1425 (James, Tuna Melt, Kilty). ⚠ Known gap: none of the checks can be exercised on a simulator — device-test the pre-flight, the signal light and the lost-you note. **Blocking since 2026-10-04 (James):** on iPhone, Location must be Always to start, arm auto start or scout (Mouthwash, WLH3 #2114: 7 points, then 93 minutes of nothing); no location at all also blocks; the dialog offers Cancel instead of Start anyway. Android no longer reports "While using" — its foreground service keeps a while-in-use session alive, and the app never requests background location. | `Building` |
| `E5.F1.S14` | As a **Hasher** on Power Saver, I want the same detailed trail as everyone else, with the battery saved by sending my position less often while the phone is in my pocket — and my position sent at once when I take it out — so that a battery-saving setting no longer costs me my trail (James, 2026-10-01: the 4G/5G radio, not the GPS, is what costs power). Every tier records at Best (5 m, 15 s fixes, one point per 15 s kept on both platforms); uploads every 30 s in the foreground, and 1 / 2 / 3 min in the background for Best / Balanced / Power Saver; an immediate flush on coming to the foreground. The Power Saver pre-flight warning and the "~" on its distance are retired; the map's freshness pill and the rose allow 4 minutes. ⚠ Known gap: built 2026-10-01; whether it saves battery is to be measured from the [METRICS] drain against requests per hour. | `Building` |

### E5.F2 · Trail marks  
`App`

> Checks, false trails, fish hooks, regroups, drink stops, On Inn — dropped by the hare as they lay, or by the pack as they run.

| ID | Story | Status |
|---|---|---|
| `E5.F2.S1` | As a **Hare**, I want to drop a typed mark at my exact position so that the pack can see the trail's structure. | `Shipped` |
| `E5.F2.S2` | As a **Hare**, I want to add my own text to a caution or label so that I can warn about a specific road. | `Shipped` |
| `E5.F2.S3` | As a **Hasher**, I want the On Inn to end the drawn track so that the polyline stops where the trail did. | `Shipped` |
| `E5.F2.S4` | As a **Hare**, I want to choose a glyph or free text for a mark so that the marker set is not limited to what was coded. | `Next` |
| `E5.F2.S5` | As a **Hare**, I want to tag a trail as Normal, Long or Walker so that viewers can filter to the route they actually ran. | `Next` |

### E5.F3 · GPS noise filtering  
`App` `Web`

> Two implementations that are deliberate mirrors of one algorithm — `track_point_filter.dart` and `packtrack.ts`. They must change together or the same run measures differently in each.

| ID | Story | Status |
|---|---|---|
| `E5.F3.S1` | As a **Hasher**, I want each fix pulled toward its neighbours in proportion to its own uncertainty so that a poor GPS day is cleaned rather than deleted. | `Shipped` |
| `E5.F3.S2` | As a **Hasher**, I want photo marks excluded from the track maths so that an imported photo cannot drag my trail sideways or inflate my distance. | `Shipped` |
| `E5.F3.S3` | As a **Hasher** who stood at a check for twenty minutes, I want that recognised as standing still so that jitter is not counted as distance. | `Shipped` |
| `E5.F3.S4` | As a **Hasher** on a bad-GPS day, I want the stationary radius to scale with my accuracy so that a stall on 100m fixes is still recognised as a stall. | `Shipped` |
| `E5.F3.S5` | As a **Platform Admin**, I want filter changes pinned by tests against real recorded tracks so that a tuning change cannot quietly eat real distance. | `Shipped` |

### E5.F4 · The live map  
`App`

| ID | Story | Status |
|---|---|---|
| `E5.F4.S1` | As a **Hasher**, I want to see everyone's live position on a map so that I can find the pack when I am lost. | `Shipped` |
| `E5.F4.S2` | As a **Hasher**, I want a radar view showing bearing and distance to each runner so that I can navigate to them without reading a map. | `Shipped` |
| `E5.F4.S3` | As a **Hasher**, I want a sortable list of runners by trail length or proximity so that I can pick who to follow. | `Shipped` |
| `E5.F4.S4` | As a **Hasher**, I want one consistent control column across the map, radar and list so that the buttons do not move when I switch view. | `Shipped` |
| `E5.F4.S5` | As a **Hasher**, I want a distress mark to show even when I have filtered that trail out so that a call for help is never hidden. | `Shipped` |
| `E5.F4.S6` | As a **Hasher** watching a live run, I want each 15-second poll to fetch only the points since the last one so that following the pack for an hour does not re-download the whole run every poll. **⚠ Known gap (found 2026-09-10):** incremental polling has never actually happened — the app sends the timestamp as `AfterTimestamp` but `GetPositions` binds `afterTimestampMs`, so every poll is a full fetch; and the map controller relies on that, replacing its runner list wholesale on every load (`assignAll`). Built 2026-09-10, both halves: the app sends `afterTimestampMs` (the key the server reads) and merges what comes back into the tracks it holds, de-duplicated by capture time and type, re-filtering and redrawing only the runners that gained a point; the server keys the incremental poll on the storage service's own system `Timestamp` (arrival, one clock, never written by us — James's high-water-mark idea with the service as the sequencer) and reaches back 60 s from the mark so a batch still landing during the last poll is caught next time. A full fetch is still taken on reset, in the admin editor, and every 5 min as the backstop for deletions an incremental poll cannot report; a stale On Inn (terminator followed by newer points) is dropped locally as the server would. Old apps keep sending `AfterTimestamp` and keep getting a full fetch, so the API shipped first. Shipped 2026-09-10 in API 1.0.43 / app 3.0.21. **⚠ Known gap:** the partition is still scanned on every poll (Table Storage only indexes the row key); only the bytes returned shrink. Not yet watched on a live run. | `Shipped` |
| `E5.F4.S7` | As a **Hasher** on the Live Run map, I want the same tool column the full-screen and run-detail maps have — compass, share, locate, track filter, GPX, trim — so that I do not have to go full screen mid-run to reach them (James, 2026-10-01, at Shoreditch #62: the Live Run map shows only Full screen, North lock and locate). Not a regression: the Live Run map never had the column — the tools moved to the full-screen map in 2.13 (1202), and `E5.F4.S4` unified only the full-screen and run-detail maps. **Build:** extract the full-screen map's `_controls` into ONE shared widget used by all three maps; on the Live Run map **Full screen** takes Close's place at the top and North lock joins the column, leaving the top-right clear for the Map/Radar/List switch; per canvas as now (no locate on radar/list); GPX and trim only once a track exists; trim stays admin-only. **Risks, why it was held out of the 2026-10-02 production build:** (1) the column scrolls and needs a bounded height — misplaced in the Live Run `Stack` it is a build error that greys the map mid-run, the same class as 1428's grey chat screen; (2) the full-screen map and trim editor register their controllers under their own tags — the Live Run map's differ, so a wrong `Get.find` crashes a tap or the build; (3) six buttons plus the switch and the replay panel crowd an iPhone SE or a large text size. **Done when:** a private dance and a minute on a live run screen (each button tapped, small phone checked) before it reaches production; the page cannot be built in a unit test (it needs the app's live services). | `Next` |
| `E5.F4.S8` | As a **Hasher** or spectator watching a live run, I want every poll after the first to download only what changed, deletions included, so that watching a big pack for an hour never re-downloads the whole run (James, 2026-10-02: "we should always be using watermarks to download only deltas"). Two gaps left by `E5.F4.S6`: the app still took a full fetch every 5 min because a poll could not report a deletion, and the web (run page every 30 s, Trail TV every 12 s) never sent a watermark at all. Now every delete — a resumed runner's On Inn, a LOST mark cleared or moved, a trim boundary — writes a tombstone to the existing `EventTrackingControl` table (no new table; partition = run, RowKey `del-…`, invisible to its one point-lookup reader and to every `EventPositions` partition scan), and an incremental `GetPositions` reply carries `removed`. A full fetch is taken only on first load, in the admin editor, and when the official window changes. The web's `createPackTrackPoller` holds the merged pack and polls by deltas, so a cleared LOST badge also leaves a watcher's map within one poll instead of up to 5 minutes. ⚠ Known gap: built 2026-10-02 (API, app, web), not deployed; the API must ship before the app and web. A track import that replaces a runner's track writes no tombstones (a finished run, not live-polled). The 60 s look-back still re-sends each recent point to a watcher several times; small, and kept because it is what stops a batch landing mid-poll being missed. | `Building` |

### E5.F5 · Replay & sharing  
`App` `Web`

| ID | Story | Status |
|---|---|---|
| `E5.F5.S1` | As a **Hasher**, I want to scrub and play back the whole run so that I can see how the pack moved. | `Shipped` |
| `E5.F5.S2` | As a **Hasher**, I want photos to appear at the moment they were taken during playback so that the replay tells the run's story. | `Shipped` |
| `E5.F5.S3` | As a **Visitor**, I want to watch a trail on the web without the app so that I can share it with anybody. | `Shipped` |
| `E5.F5.S4` | As a **Kennel HC Admin**, I want a big-screen event wall cycling through live and recent trails so that it can run on a TV at the on-after. | `Shipped` |
| `E5.F5.S5` | As a **Hasher**, I want to export a trail as GPX so that I can open it in my own running app. | `Shipped` |
| `E5.F5.S6` | As a **Hasher**, I want to import a GPX file from my watch or running app as my PackTrack trail so that a run I recorded elsewhere is on the map with everyone else's. Menu → Import GPX Track, or the route icon on the Hash Runs bar (a dialog explains that the run will be located and the track uploaded, then the picker opens); the run is found server-side (`hcapp_findRunForTrack`) from the first point's time (runs starting between 3 h before it and the last point) and position (a recorded start must be within a mile; a run with no location is accepted on time alone after confirming); several matches are offered as a list. The track is thinned to the app's own cadence, our own exported waypoints come back as marks, an On Inn is added at the end, and the points go through StorePositions like a phone's — so replay, the nightly archive and the run-card count need nothing new — then the hasher is checked in At Hash. A file with no timestamps is rejected; an existing track on that run is refused unless the hasher chooses Replace, which deletes it first. The app is also a handler for `.gpx`: "Open in Harrier Central" from Files, Mail and browser downloads on iOS (document type + `harriercentral://` scheme, `IncomingFileBridge`), "Open with"/Share on Android (intent filters, `MainActivity`), and a Harrier Central row in the iOS share sheet (a `ShareExtension` target that drops the file in the `group.com.harriercentral.app` container and opens the app). Strava's and Garmin's own apps do not export GPX — it comes from their websites — so the share path is Files → Harrier Central. Shipped 2026-09-10 in app 3.0.21 (TestFlight, Play internal) with `hcapp_findRunForTrack`. **⚠ Known gap:** foreign waypoints are ignored; the whole flow — picker, matching, replace, share extension — awaits its first device test. | `Shipped` |
| `E5.F5.S7` | As a **Hasher**, I want to hand Harrier Central a whole Strava or Garmin archive — or any GPX, TCX or FIT file — with one button, so that every hash run I recorded on a watch becomes my PackTrack trail without picking them out by hand. Everything is server-side (James, 2026-09-11: results must appear nearly immediately, and the raw files may later seed historic runs for new kennels): the app uploads the file straight to blob storage (`track-imports`, 4 MB blocks with progress), registers an `HC.TrackImport` job (James chose the table; bytes never enter SQL), then calls `ProcessTrackImport` in slices while the outcomes stream in; `ProcessTrackImportsNightly` finishes anything abandoned. Type is sniffed from the bytes: GPX/TCX (XML), FIT (own minimal decoder, verified on three real Garmin files), gzip, zip. Rules: an archive never overwrites an existing track; no recorded start ⇒ skipped; several runs that day ⇒ held with a choice; a single file is held instead so the person can confirm or replace. Every activity, matched or not, is recorded in ResultJson (start time/place, distance, duration, sport) for a future recurring-run discovery. StorePositions now stamps `TrackFirstPointAt`/`LastPointAt` and `EventTrack` from capture times, so a run imported months later is not "recently tracked". Attendance is raised to At Hash (`nonApi_ensureTrackAttendance`). Shipped 2026-09-11: table created, SPs and API 1.0.44 live, app 3.0.22 on TestFlight and Play internal. First real week (2026-09-12 sweep, three hashers, nine archives): every Strava TCX was "unparseable" — the files open with ten spaces before the XML declaration, which the parser refused; fixed on dev (parse after trimming), with GPS-less activities (a wearable counting steps, a gym session) now reported as "no GPS" rather than unparseable. Not yet deployed. **⚠ Known gap:** retention of the uploaded archives is undecided (nothing deletes them); no push when a long archive finishes; a slice of a big archive outruns the phone's 70 s wait because points are written one row at a time (no damage — the second pass skips runs already tracked — but an hour of timeouts on a 1 GB file); a GPX with an undeclared namespace prefix still fails to parse. Supersedes the phone-side GPX parser from S6. | `Shipped` |
| `E5.F5.S8` | As a **Hasher**, I want to re-run an archive I already uploaded so that runs whose start point was fixed after the first pass are found without transferring the file again. The import page lists previous uploads (their files are kept) with a Re-import button; `ProcessTrackImport` with `reimport` restarts the job from its first activity and the phone drives it as for a fresh upload. Runs that already carry a track come back skipped, as any archive pass does. Shipped 2026-09-12 (API 1.0.47, app 3.0.27). | `Shipped` |
| `E5.F5.S9` | As a **Hasher** looking at a run's PackTrack, I want each runner's track to say where it came from — PackTrack itself, Strava, Garmin, Fitbit … — so that an imported track is not mistaken for one the app recorded (James, 2026-10-04, after Hard On On's failed live track was replaced by a Garmin Connect file). `HC.HasherEventMap.TrackSource` (packtrack | strava | garmin | fitbit | apple | coros | suunto | polar | wahoo | komoot | file; `api/Endpoints/TrackSources.cs`): set by `PositionWriter` for every batch carrying GPS fixes — `packtrack` for the app's own uploads, the import's source for files (GPX `creator`, TCX `Creator`, FIT `file_id.manufacturer`; a Strava account archive is always `strava`). In no sync rowset; `GetPositions` returns it per runner as `trackSource` (cached a minute per run), and the app and web maps show it beside the selected runner's name when it is not PackTrack ("Hard On On · Garmin"). The trigger treats it as a track column, so writing it stamps nothing. LIVE 2026-10-04 (API 1.0.61+73, app 1445, web): column added and backfilled (476 packtrack, 366 strava, 1 garmin) with no row stamped; script archived. ⚠ Known gap: the runner list and Trail TV do not show it yet. | `Building` |

### E5.F6 · Track administration  
`App` `API`

| ID | Story | Status |
|---|---|---|
| `E5.F6.S1` | As a **Kennel HC Admin**, I want to trim the start and end of a recorded track so that the drive to the pub is not part of the trail. | `Shipped` |
| `E5.F6.S2` | As a **Kennel HC Admin**, I want to delete a track entirely so that a mis-recorded trail can be removed. | `Shipped` |
| `E5.F6.S3` | As a **Platform Admin**, I want to know from SQL which runs have tracks so that reporting does not require walking partition keys in Table Storage. `HC.EventTrack`, one row per tracked run, written by StorePositions per batch and backfilled from Table Storage; the per-hasher record is E3.F3.S7's `Track*` columns on `HC.HasherEventMap`. | `Shipped` |
| `E5.F6.S4` | As a **Hasher**, I want my own PackTrack trail stored as gzipped content on my `HC.HasherEventMap` row — one runner, one run, one compressed blob — so that my trail survives independently of the position store and a past run replays from the database alone. Written once when tracking ends, never per batch, beside the `Track*` summary columns E3.F3.S7 put on the same row. The phone is not involved (James, 2026-09-10): a nightly Azure Function (`ArchiveTracksNightly`, 03:30 UTC) archives every finished track that has no archive — rows StorePositions counted, plus runners on recently tracked runs whose row was never counted — delta-encoded varint + gzip at ~5.5 bytes a point. A later point (`StorePositions`) or a deleted one (`DeletePositions`) drops the archive so the next night rebuilds it. A runner found in a run's partition with no attendance row gets one (`nonApi_ensureTrackAttendance`, the same At Hash row a real check-in writes, run counts recomputed): every runner who has a track has an attendance row. `tools/archive_all_tracks.sh` runs the same sweep on demand over every tracked run. `GetPositions` serves a finished run from the archive on a full fetch once every counted runner on it has one (response carries `source: archive`; incremental polls stay on Table Storage so a resumed run still streams), so every client replays past runs from the database without a client change. Shipped 2026-09-10: writer in API 1.0.41, reader in API 1.0.42; first pass archived 309 tracks on 156 runs (1.5 MB) and created 2 missing attendance rows. | `Shipped` |
| `E5.F6.S5` | As a **Platform Admin**, I want the 709 legacy `PHO::` photo points removed from the position store once no shipped client reads pins from them, so that a photo lives only on its own row. **Due 2026-12-09**, after app ≤3.0.15 and web ≤0.21.44 are out of production — issue #336 has the check and the deletion path. | `Next` |
| `E5.F6.S6` | As a **Hasher** (and a visitor to the kennel's site), I want each run to have ONE authoritative trail — the hare's — held on the run itself rather than on any one runner's attendance row, so that the route, its distance and its marks are the run's record however many of the pack tracked, and survive a hare who never checks in (James, 2026-10-03). **Not designed — to discuss.** Joins `project_hare_pre_track` (3.2: a hare pre-tracks the trail while setting it, "for emergency use"). Ways a trail could arrive: the hare's live PackTrack while laying it (pre-lay, live hares), a GPX/TCX/FIT import (`E5.F5.S6`), an admin promoting one runner's track, or a kennel's own archive — Chichester's site holds a run AND a walk GPX per run (e.g. run 1093, 1094), so a run may have more than one authoritative lane (`E5.F2.S5` trail types). Storage would be columns on `HC.Event` (no new table without James), kept OUT of every sync rowset — HC.Event is synced to every phone and a track is fetched only when a map opens — and any ALTER needs the trigger dance. Open: what 'authoritative' changes (drawn as THE trail, the run's distance, Trail TV and the web), who may set or replace it, and whether it is hidden until the run starts or until asked for (pre-lay spoils the route). **Decided with James, 2026-10-03:** sources = the hare's live PackTrack, an admin promoting a runner's track, a GPX/TCX/FIT import; ONE lane per trail type (run file → Normal 3, walk file → Walkers 1); effects = drawn as THE trail (dashed, per-type colour), the run's distance, shown on runs nobody tracked, GPX download; set by the run's hares + kennel admins; during the run visible ONLY to a lost runner in the I'm-lost flow, otherwise once the run has ended (start + 4 h until On Inn detection). Stored as `HC.Event.OfficialTrailGzip` (COMPRESS of the lanes JSON) + `OfficialTrailInfo` (per-lane distance/source) — in no sync rowset; `trgUpdateModifiedOnDateForEvent` ignores a trail-only write (COLUMNS_UPDATED mask, rowversion bit allowed). **LIVE 2026-10-03:** columns (SP build 28), `publicWeb_getOfficialTrail`, the web run page (dashed lanes, distance, Download GPX). Chichester's full history imported 2026-10-03 (1,088 runs, 34 trails). **Scouting and promotion (decided 2026-10-03, built for app 1440):** a **Scout this trail** mode on the run's *Official trail* page (hares + admins; records on the phone only via `LocationService.scoutMode`, never on PackTrack), **Make official trail** beside a selected runner on the PackTrack map, and **upload a GPX/TCX/FIT file** (parsed server-side by `ParseTrackFile`, nothing stored); each asks which trail-type lane it is for (`hcapp_setOfficialTrail`, one lane per call, others kept). Points carry `t` = ms after the lane's first point; replay **auto-aligns** that first point to the first pack track's start (app and web); an untimed lane is drawn whole, never animated. The app map draws the trail dashed (`hcapp_getOfficialTrail`) and "I'm Lost" reveals it to the lost runner (start −1 h to +12 h). The public SP no longer returns `setBy`/`sourceRef`. **Backfill 2026-10-03:** `tools/promote_best_tracks.py` promoted the best runner PackTrack (most clean fixes in the longest unbroken stretch, per declared lane, from near the start) on 476 of 526 tracked runs (493 lanes, `source: auto`); 50 had no plausible track. ⚠ Known gap: new runs are not auto-promoted — re-run the tool, or make it a nightly job. **Kennel trail map start points (app 1442, SP build 31):** every visible run's start (Sync* lat/lon) as one pin per place (~10 m), sized by use; tap to step through the runs that started there. ⚠ Known gap: a scout in progress lives in memory only — a killed app loses it; the hare's live PackTrack is not yet promoted automatically (it is promoted by hand from the map). | `Building` |
| `E5.F6.S7` | As a **Hare**, I want to link my Strava, Garmin Connect or Fitbit account so that a scouted trail I recorded on my watch arrives as the run's official trail without exporting a file (James, 2026-10-03). Today the route is export → upload a GPX/TCX/FIT on the *Official trail* page (`E5.F6.S6`). Each needs an OAuth app registration, a token store and a webhook or poll — a token store is schema, so ask James before any table. | `Backlog` |
| `E5.F3.S6` | As a **Hasher**, I want no mark — photo, check or the admin's trim boundary — to ever be a vertex of my trail or a term in its distance, so that a marker placed off-trail cannot draw a straight line into my track. | `Shipped` |

---

## E6 — Photos & Hash Flash

The Hash Flash takes the pictures and approves what the club sees. Photos carry their own position and capture time, which is what lets them be placed on a map without borrowing somebody's GPS track.

### E5.F7 · Tracks on the device  
`App` `API` `DB`

| ID | Story | Status |
|---|---|---|
| `E5.F7.S1` | As a **Hasher**, I want my own trails and each run's runner count on my phone so that the run list, my trail on a run, and a map of every run I have done in an area work the same with or without a signal, and the app stops asking the server for what it already knows. Study and recommendation in `docs/packtrack_on_device_plan.md` (2026-09-12): the user sync's HEM rowset carries `trackGzip` (about 4 KB a track, under 1 MB for the heaviest runner), the nightly archive stamps `updatedAt` so a finished track syncs once, `HC.Event.TrackRunnerCount` replaces the track half of `hcapp_getRunActivity` (updated only when the count changes, so a live run does not churn followers' event rows), a Dart port of the archive codec with locally computed bounds and a simplified polyline, and a "Show my trails" layer on the Run Locations map coloured by kennel pin colour. Other runners' replays and the live map still need the server. **Shipped 2026-09-12 (SPs, API 1.0.47, app 3.0.27+1342; 573 runs backfilled):** James chose all four decisions and added the photo, chat and down-down counts to the same row. Server: `HC.Event` gains TrackRunnerCount/PhotoCount/MessageCount/DownDownCount (James runs `db/hc6/app/2026-09-12_event_activity_counts.sql` after deploying `nonApi_refreshEventActivity`: ALTER with the event trigger off, four triggers, backfill with it on), the user sync's HEM rowset carries trackGzip/trackPointCount/first/last, the nightly archive stamps updatedAt. App (DB_VERSION 529): run cards read the counts from the event row (RunActivityService and its per-screen call are gone), `TrackArchiveCodec` (Dart, tested against a production blob), `TrackIndex` (bounds + simplified path, local-only), "Show / hide my trails" on the Run Locations map (kennel pin colour, tap opens the run), and the run map falls back to the hasher's own archived trail when the server cannot be reached. Rule recorded in CLAUDE.md: run-card data is synced, never fetched while scrolling. Device test pending (`E16.F4`). | `Shipped` |

### E6.F1 · Capturing and uploading  
`App` `API` `DB`

| ID | Story | Status |
|---|---|---|
| `E6.F1.S1` | As a **Hasher**, I want to take a photo during the run and have it attached to that run so that I do not file it later. | `Shipped` |
| `E6.F1.S2` | As a **Hasher**, I want to choose whether each photo is private or submitted to the club so that I control what is shared. | `Shipped` |
| `E6.F1.S3` | As a **Hasher** with no signal, I want photos queued and uploaded later so that a trail in a field does not lose them. | `Shipped` |
| `E6.F1.S4` | As a **Hasher**, I want the stored position to come from a fresh fix rather than a stale idle one so that the pin is where I actually was. | `Shipped` |
| `E6.F1.S5` | As a **Hasher**, I want a full-quality copy saved to my camera roll so that the club's copy is not the only one. | `Shipped` |

### E6.F2 · Importing from the camera roll  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E6.F2.S1` | As a **Hasher**, I want to import photos I already took and have the app work out which belong to this run so that I am not filing them by hand. | `Shipped` |
| `E6.F2.S2` | As a **Hasher**, I want an imported photo pinned where it was taken rather than where I imported it so that the map is honest. | `Shipped` |
| `E6.F2.S3` | As a **Hasher**, I want an imported photo to carry its own capture time so that it appears at the right moment in replay. | `Building` |
| `E6.F2.S4` | As a **Hasher**, I want an imported photo to stop wearing the importer's identity so that hiding a trail does not hide somebody else's photo. **⚠ Known gap:** markers still read position and time from the `PHO::` track point; the renderer switch is not done | `Building` |
| `E6.F2.S5` | As a **Hasher**, I want a button on a past run that finds the photos of it still sitting in my camera roll so that the club's gallery gets the pictures I never got round to filing. Designed 2026-09-12 (James). Scan is **per run and on demand** — never a background sweep of the roll. Candidates are photos captured from 30 minutes before the run's start to six hours after it, **that carry a location**: a photo with a time but no coordinate is discarded rather than offered, because a roll full of unrelated pictures is worse than a missed one. Location is read from the media store as well as the EXIF, since a forwarded or permission-stripped photo often keeps one and not the other. A candidate must fall near the hasher's **own trail for that run** (any point, not just the start — the On-Inn and the far end of trail are both a long way from the circle), falling back to a radius around the start where they have no track. Only runs they attended are offered. The matched photos appear in a **selector the hasher ticks**, carrying the notice that what they send may become publicly viewable; nothing uploads on its own. Uploads take the existing path, so capture time, coordinate, asset id and the Hash Flash review queue all apply, and a photo already uploaded is skipped on its asset id. Built 2026-09-12 on dev, not shipped: `CameraRollScanService` (window and geofence as pure, tested rules), `ScannableRunsQuery` (attended runs, own trail, from the local DB), `hcapp_getMyPhotoAssetIds` (sp 102, deployed) so the sweep knows what is already up, a per-run selector reached from Find my photos on the run's gallery, and a kennel-level `Photos on your phone` listing every run as `14 eligible · 6 added`. **⚠ Known gap:** full camera-roll permission is requested at runtime but the store privacy declarations are not updated, and neither screen has been run on a device. | `Building` |

### E6.F3 · Hash Flash approval  
`App` `Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E6.F3.S1` | As a **Hash Flash**, I want a review queue of submitted photos so that nothing reaches the public site unapproved. | `Shipped` |
| `E6.F3.S2` | As a **Hash Flash**, I want to approve, reject or delete in bulk so that a hundred photos is not a hundred decisions one at a time. | `Shipped` |
| `E6.F3.S3` | As a **Hash Flash**, I want to nominate a cover photo for the run so that the run card has a face. | `Shipped` |
| `E6.F3.S4` | As a **Hash Flash**, I want to crop a photo without destroying the original so that a bad framing is fixable and reversible. | `Shipped` |

### E6.F4 · Viewing photos  
`App` `Web`

| ID | Story | Status |
|---|---|---|
| `E6.F4.S1` | As a **Hasher**, I want photos as pins on the run map so that I can see where each was taken. | `Shipped` |
| `E6.F4.S2` | As a **Hasher**, I want a swipeable carousel from any photo pin so that I can browse without going back to the map each time. | `Shipped` |
| `E6.F4.S3` | As a **Visitor**, I want a public gallery for a run so that a shared link shows the pictures without the app. | `Shipped` |
| `E6.F4.S4` | As a **Visitor**, I want the public gallery to expose no GPS coordinates so that an unauthenticated page cannot leak where people were. | `Shipped` |
| `E6.F4.S5` | As a **Hasher**, I want a photo to be its own thing — a location, a time and a photographer — rather than a point on somebody's track, so that uploading photos to a run I was not on never records me as having a track and a photo's fix can never bend a trail. | `Shipped` |

**⚠ Known gap:** the public map and Trail TV now read pin coordinates from a new unauthenticated `publicWeb_getRunPhotoPins` feed (Public and Cover photos only). This is the same exposure the PHO:: track marks carried through the track payload; the gallery feed itself still carries no coordinates, so `E6.F4.S4` holds.

---

## E7 — Circle, Down Downs & Songs

What happens after the trail. The Religious Advisor runs the circle, hands out down downs, and picks the songs — and the app has to keep up with somebody shouting over forty people.

### E7.F1 · Down downs  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E7.F1.S1` | As a **Religious Advisor**, I want to record a down down against a hasher with a reason so that the circle has a running order. | `Shipped` |
| `E7.F1.S2` | As a **Religious Advisor**, I want to mark one done, undo it, or cancel it so that a mistake in a noisy circle is recoverable. | `Shipped` |
| `E7.F1.S3` | As a **Hasher**, I want to nominate somebody for a down down so that the circle is not only the RA's ideas. | `Shipped` |
| `E7.F1.S4` | As a **Religious Advisor**, I want a live count of drinks poured so that the beer meister knows where they stand. | `Shipped` |
| `E7.F1.S5` | As a **Hasher**, I want a past run's down downs — marked done or not — on its detail page, and as a manager a way into the charges page from there, so that a circle nobody marked done on the night is not lost. Before this, six of the eight runs with charges showed none. | `Shipped` |
| `E7.F1.S6` | As a **Hasher**, I want to enter a charge whether or not I am checked in so that a nomination from the circle is never refused. `hcapp_addDownDown` 1.1.0 drops the attendance check; where the kennel (or the run) lets hashers set their own attendance, entering a charge checks the caller in At Hash, otherwise their attendance is left as it was (James, 2026-09-12). Eight refusals at one German Nash Hash run on 2026-09-05 were RSVP'd members who had not checked in. SP deployed 2026-09-12. | `Shipped` |
| `E7.F1.S7` | As a **Hash Cash** (or whoever runs the circle), I want to change who a charge is against — including a name typed for someone not in the app — and to add a charge straight from the Down Downs list, so that a mistyped name or a wrong hasher is fixed without cancelling and re-entering the charge (James, 2026-09-26, LH3 #2852). Edit Down Down gains the Add page's people picker (typed names as chips; the run's hashers ticked when charged, and a charged hasher not on the attendee list added so a save cannot drop them); `hcapp_updateDownDown` 1.1.0 takes optional `@hasherIds` / `@externalNames` (NULL = unchanged, so older apps are unaffected) and refuses an edit that leaves nobody charged. The Down Downs list has an **Add charge** button. **Built 2026-09-26 on dev** — ⚠ Known gap: SP not yet deployed (must precede the app build that sends the new keys); not yet seen on a device; a hasher newly added by an edit gets no push. | `Building` |

### E7.F2 · Songs  
`App` `Portal` `Web`

| ID | Story | Status |
|---|---|---|
| `E7.F2.S1` | As a **Hasher**, I want the club's songbook on my phone so that I can join in without knowing the words. | `Shipped` |
| `E7.F2.S2` | As a **Religious Advisor**, I want to push the current song to everyone at the run so that the whole circle is on the same verse. | `Shipped` |
| `E7.F2.S3` | As a **Kennel HC Admin**, I want to choose which songs our kennel uses so that the songbook reflects our club. | `Shipped` |
| `E7.F2.S4` | As a **Platform Admin**, I want to add and edit songs centrally so that every kennel benefits from one library. | `Shipped` |

### E7.F3 · Hash trash  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E7.F3.S1` | As a **Religious Advisor**, I want to write the run's hash trash so that there is a record of what happened. | `Shipped` |
| `E7.F3.S2` | As a **Hasher**, I want to read the hash trash on the run detail so that I can relive a run I was at or catch up on one I missed. | `Shipped` |

### E7.F4 · Naming & ceremony  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E7.F4.S1` | As a **Religious Advisor**, I want to record that a hasher was named, with their old and new name so that the club's history is kept. | `Backlog` |
| `E7.F4.S2` | As a **Hasher**, I want milestone runs flagged in the circle so that nobody's 100th passes unmarked. | `Backlog` |
| `E7.F4.S3` | As a **Hasher**, I want virgins and visitors identified at the start so that the circle can welcome them properly. | `Shipped` |
| `E7.F4.S4` | As a **Religious Advisor**, I want the award list to show who is *due* a milestone down-down if they turn up — greyed out until they check in — so that I can plan the circle before the pack arrives. All \| Coming \| At Hash switch (Coming = checked in, or RSVP'd Yes/Maybe, or named hare) on today's and upcoming runs only (the prediction adds one run to today's totals, so it is wrong for a past run). "Due" = ran with the kennel in the last 12 months with at least one run, or RSVP'd Yes/Maybe, or named as hare; never an RSVP of No; a first run needs an RSVP. Worked out on the phone from the event-domain sync, no SP change. **Built 2026-09-25** (app, dev), checked on Barbados run 2351 against server counts. **⚠ Known gap:** not in a store build yet. | `Building` |

---

## E8 — Money & the Hash Cash Ledger

Run fees, memberships, kit and credit. Every movement is a ledger entry, and the ledger has to balance whether the money arrived as cash in a bucket or as credit the club gave away.

### E8.F1 · Run fees  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E8.F1.S1` | As a **Hare Raiser**, I want to set different prices for members, visitors and virgins so that the run charges what the club decided. | `Shipped` |
| `E8.F1.S2` | As a **Hash Cash**, I want to take payment at check-in in cash, credit or card so that everybody can pay however they turned up. | `Shipped` |
| `E8.F1.S3` | As a **Hasher**, I want to pay my own run fee from my phone so that I do not need the Hash Cash to be free. | `Shipped` |
| `E8.F1.S4` | As a **Hash Cash**, I want to charge a whole group in one action so that a visiting kennel is one transaction. | `Shipped` |
| `E8.F1.S5` | As a **Hash Cash**, I want a zero-value run to record attendance without pretending money moved so that free runs do not pollute the ledger. | `Shipped` |

### E8.F2 · Memberships  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E8.F2.S1` | As a **Hash Cash**, I want annual, rolling and calendar-year renewal modes so that the platform fits how our club actually charges. | `Shipped` |
| `E8.F2.S2` | As a **Hasher**, I want to renew my membership from the app so that I do not have to catch the Hash Cash at a run. | `Shipped` |
| `E8.F2.S3` | As a **Hash Cash**, I want a renewal to be credit-neutral in the ledger so that taking a subscription does not look like income twice. | `Shipped` |
| `E8.F2.S4` | **3.2 cleanup (James, 2026-10-02: hold off, do it in 3.2).** As a **Kennel HC Admin**, I want a hasher's membership to be exactly what its end date says, so that one person is never a member on one screen and not on another. Membership is the kennel's grant and ends on a date: a hasher is a member while `HasherKennelMap.MembershipExpirationDate` is in the future (permanent = 2100-01-01 or 2999-12-31). The `IsMember` flag has drifted from it — on 2026-10-02, 1,407 permanent memberships had IsMember = 0 and 297 flagged rows were expired or blank. Retire the flag: switch every reader to the date (25 files across SPs, app, portal and web read IsMember as of 2026-10-02), then derive or drop the column. Also trace what writes expiry years 2855-2859 (~290 rows — likely months added to a permanent date). Until then, new rules test the date, never the flag (`E9.F1.S27`). | `Backlog` |

### E8.F3 · Haberdashery  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E8.F3.S1` | As a **Hash Cash**, I want to sell shirts and badges through the same payment flow so that kit sales are in the same ledger as everything else. | `Shipped` |
| `E8.F3.S2` | As a **Hash Cash**, I want reports broken down by product type so that I can see kit income separately from run income. | `Shipped` |

### E8.F4 · Credit  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E8.F4.S1` | As a **Hash Cash**, I want members to hold a credit balance so that somebody can pay for ten runs up front. | `Shipped` |
| `E8.F4.S2` | As a **Kennel HC Admin**, I want credit switchable per kennel so that clubs that do not work that way never see it. | `Shipped` |
| `E8.F4.S3` | As a **Hash Cash**, I want run packages and hare rewards recorded as tracked promotional credit so that giveaways are visible rather than lost income. | `Building` |
| `E8.F4.S4` | As a **Hasher**, I want to see my own credit ledger so that I know what I have left. | `Building` |
| `E8.F4.S5` | As a **Hash Cash**, I want per-kennel run packages — pay for eleven runs, get twelve — so that a discount is recorded rather than fudged. | `Next` |
| `E8.F4.S6` | As a **Hash Cash**, I want promotional credit to expire on run inactivity rather than payment inactivity so that a lapsed hasher's comps do not sit on our books forever. | `Next` |

### E8.F5 · Payment integrity  
`App` `DB`

> A payment taken twice is worse than one not taken at all. The client-generated payment id is the primary key, which makes a retry idempotent by construction.

| ID | Story | Status |
|---|---|---|
| `E8.F5.S1` | As a **Hash Cash**, I want a retried payment to be recognised as the same payment so that a flaky signal cannot double-charge somebody. | `Shipped` |
| `E8.F5.S2` | As a **Hash Cash**, I want payments taken offline held in an outbox and sent when I reconnect so that nothing is lost in a field. | `Shipped` |
| `E8.F5.S3` | As a **Hash Cash**, I want monetary values held as fixed-point decimals so that rounding never loses a cent. | `Shipped` |
| `E8.F5.S4` | As a **Hasher** paying my own free run fee, I want that permitted without an admin grant so that self check-in is not silently refused. | `Shipped` |
| `E8.F5.S5` | As a **Hash Cash**, I want a payment to exist without belonging to a run so that a membership or a kit sale is not forced to invent an event. **⚠ Known gap:** `HC.Payment.EventId` is NOT NULL, and the sync SPs must be version-gated before it can change — shipped clients would break | `Next` |

### E8.F6 · Receipts & reconciliation  
`App` `API` `DB`

| ID | Story | Status |
|---|---|---|
| `E8.F6.S1` | As a **Hash Cash**, I want to record expenses against a run with a photographed receipt so that the run's true cost is known. | `Shipped` |
| `E8.F6.S2` | As a **Hash Cash**, I want a payment report per run and per period so that I can reconcile the bucket against the app. | `Shipped` |
| `E8.F6.S3` | As a **Hash Cash**, I want that report emailed to me on a schedule so that reconciliation is not something I have to remember. | `Shipped` |

### E8.F7 · Taking money on the trail  
`App` `API` `DB` `3.2`

| ID | Story | Status |
|---|---|---|
| `E8.F7.S1` | As a **Hash Cash**, I want to take a card or phone payment at the trail by handing the amount to the kennel's own payment app and getting the result back, so that a hasher with no cash can still pay on the day and the money lands in the club's account rather than in somebody's pocket (James, 2026-09-18). **The model is decided (James, 2026-09-22): the kennel holds the merchant relationship.** The club signs up with SumUp itself, the Hash Cash's phone has the club's SumUp app signed in, and Harrier Central hands off to it — amount, currency, title, our `clientPaymentId` as SumUp's *foreign transaction id*, and a callback URL. Harrier Central is never merchant of record, holds no credentials, calls no provider API and never touches the money, so it inherits no chargebacks, no KYC and no licensing for 394 independent clubs. **It also means we never integrate Tap to Pay:** the tap happens on SumUp's own screen, in SumUp's app, which keeps us out of PCI scope and out of Apple's PSP entitlement process entirely — the same hand-off shape as the WhatsApp run notice. **Card is NOT a new `EnumPaymentType`.** The payment reports branch on `paymentType == paymentCash.value || …` equality chains, so a new value 9 would match nothing and every client below the card build would show a paid hasher as UNPAID in the screen used to reconcile the bucket — money in the bank, ledger says no. `paymentTypeStr` and `paymentTypeCode` are also PERSISTED computed columns with a CASE over `PaymentType`, so a new value means altering two persisted computed columns on a large table. The enum answers *did the club get the money and how much*; the rail belongs in `PaymentProvider`, which already exists and already carries 289 PayPal and 42 Tikkie rows past every shipped client without a change. **The pending row is written BEFORE the hand-off**, because once we leave the app we may never come back: `PaymentType = Not paid` with `PaymentProvider` and `clientPaymentId` set — honest, and old clients read it correctly with no change. The callback flips it to the cash-equivalent type, fills `CreditAmount` and stamps `PaymentReference`. A lost callback therefore leaves a visible "awaiting confirmation", never a payment that vanished. **Built 2026-09-26 on dev, 3.1 track (James: "implement SumUp supporting the App switch and the terminals"):** `hcapp_processPayment` 1.7.0 writes the marker (type 1 + provider + clientPaymentId on a run fee, credit 0 / debit 0); success is an ordinary type 3 with provider `sumup` and reference `SU:<smp-tx-code>`, failure an ordinary type 1 — both with ids derived from the marker so a repeated answer is a replay. App: `CardPaymentHandoff` (Payment Switch URL: iOS `amount` + callbacksuccess/fail, Android `total` + `app-id` + `callback`; answer on `harriercentral://sumup-result`), a "Card £x with SumUp" button in the check-in payment sheet, the extras question shared with cash. Terminals need no code: SumUp's app takes the card with Tap to Pay or its paired Solo/Air reader. ⚠ Known gap: nothing works until (1) James creates the SumUp **affiliate key** for `com.harriercentral.app` and it goes into `SUMUP_AFFILIATE_KEY` (empty = button hidden), (2) the migration `2026-09-22_kennel_payment_provider.sql` is run and THEN the SPs deployed, (3) a kennel is set to SumUp in the portal. Not yet tested against a real SumUp app — that is `E8.F7.S9`. Run fees at check-in only; not the scanner, membership or haberdashery. | `Building` |
| `E8.F7.S2` | As a **Kennel HC Admin**, I want to say which payment app my kennel uses and which merchant account is ours, so that the Take card payment button appears for the right clubs and cannot pay the wrong account. Two pieces of config and no more, because **the account itself lives in the provider's app, not in our database**. The risk this closes is specific: the SumUp app on that phone may be signed into the Hash Cash's PERSONAL account — the tap succeeds, the hasher is charged, we record it as paid, and the money is in the wrong place. A callback alone cannot detect that. SumUp returns the merchant code, so the club's expected code is stored once and compared on return, and a payment taken on the wrong account is refused rather than confirmed. **⚠ Known gap (found 2026-09-26): SumUp's Payment Switch callback does NOT return the merchant code** — only status, transaction code and our foreign-tx-id, per SumUp's docs and both official sample repos. So the check cannot happen on return. Built instead: the club's code is shown before every hand-off ("check the SumUp app is signed in to the club's account, MC…"), and a payment taken on a personal account surfaces in the provider-export reconciliation (`E8.F7.S3`) as IN HC ONLY. Provider is a **lowercase string, not an int enum (James, 2026-09-22)**: `HC.Payment.PaymentProvider` is already `NVARCHAR` and already holds 331 rows of `PayPal` and `Tikkie`, so an int on the kennel would mean translating on every write and leaving the payment reports grouping by one vocabulary while the config used another. The token a kennel is configured with is the token written onto the payment, and it is the same word the provider's own export uses. The collation is `CI_AS` so the existing rows need no migration; Dart lowercases at the boundary, the same rule the codebase already has for UUIDs. What went wrong with `KennelPaymentScheme` was not string-ness but that it is UNCONSTRAINED — which is why it holds `12`, `14` and `16` next to `PayPal` — so `HC.Kennel.CardPaymentProvider` carries a CHECK constraint and adding a provider is a deploy. Follows the `DefaultMessagingPlatform` precedent — provider-plural from day one, because no single vendor covers kennels in Taiwan, Barbados, Germany and the US. **First two providers: SumUp and Zettle (James, 2026-09-22) — and they are different KINDS of integration, which is the real reason the seam exists.** SumUp is *Payment Switch*: an app-to-app URL scheme, the tap happens in SumUp's app, the club is already signed in there, and we hold one app-wide affiliate key tied to our bundle id. Zettle is an *embedded Payments SDK*: the tap happens inside Harrier Central, the merchant authorises by **OAuth with a deep-link callback**, and we hold app credentials plus each kennel's token — which must be stored, refreshed, revoked, and outlives the officer who granted it. So a provider is not a name, it is a **mode** (`handoff` | `sdk`), and the payment record must come out identical either way: provider, reference, merchant identity, fee from the import. A design that assumed hand-off would have to be undone for Zettle. Zettle's Flutter binding is a community plugin rather than a first-party one — a maintenance question for a payments path, and the alternative is our own platform channel. **⚠ Research 2026-09-26 (`docs/payments_on_the_trail_options.md`) — for James to decide, the choice above stands until he does:** Zettle (now "PayPal Point of Sale") trades in 12 countries, and SumUp trades in all 12 of them, so Zettle adds no country; it has no app switch, and whether its SDK can do Tap to Pay is unconfirmed. The seam should stay provider-plural either way — Stripe is the provider that reaches New Zealand, Singapore, Malaysia and Japan. | `Building` |
| `E8.F7.S3` | As a **Hash Cash**, I want to upload my payment provider's transaction export and see it matched against Harrier Central's books, so that the accounts are right even when the app never heard how a payment ended. **This is the accounting backbone, not a fallback (James, 2026-09-22: "all of the accounting happens in Harrier Central").** The callback is the user experience; the import is what makes the books true, and it is the only mechanism that can see the third case. Reconciliation runs three ways: MATCHED (our row ↔ their transaction, joined on `clientPaymentId`, which we send as SumUp's foreign transaction id so their own statement carries our identifier); IN HC ONLY (we confirmed money the provider never took — phantom income); AT PROVIDER ONLY (the club has money the books do not know about — a lost callback, **or a Hash Cash who sold a shirt straight from the SumUp app**, which no callback will ever tell us about and which is still the club's money). Reuses the server-side file import built for GPX/TCX/FIT — upload, parse, match, report what did not match. The import also carries the two numbers the callback does not: the provider's fee per transaction, and the payout id that ties a batch settlement to the club's bank line, since SumUp settles next day in batches and the bank shows one line per payout rather than one per payment. | `Next` |
| `E8.F7.S4` | As a **Hash Cash**, I want the provider's fee recorded against the payment so that the club's books tie to the club's bank. **Kennels absorb the fee rather than passing it on (James, 2026-09-22)** — the hasher pays £5, the club banks £4.91 — so gross alone can never reconcile. Two nullable `smallmoney` columns on `HC.Payment`: `ProviderFee`, and `PlatformFee` stubbed for a cut Harrier Central may one day take and **deliberately not exposed** — no UI, no report, not in a sync select list. **`ProviderFee` is blank until reconciled (James, 2026-09-22)**, not estimated from a stored rate: an estimate in a book of record is a liability, and NULL honestly means "not yet reconciled". Filled by `E8.F7.S3`. **`NetPayment` is not touched** — it is a PERSISTED computed column, `CreditAmount - DebitAmount`, meaning net movement on the row, and 7,011 live balances lean on it; net-to-club (`CreditAmount - DebitAmount - ProviderFee - PlatformFee`) is a report-level calculation instead, which is the only place it is consumed. Both columns are nullable with no default so the ALTER is metadata-only, but `HC.Payment` is synced — **James disables the `UpdatedAt` trigger and runs it**. Safe for shipped clients because the sync SPs use explicit column lists, exactly as `PromotionalCredit` shipped unnoticed. **What the stub cannot do:** in this model the money goes kennel-direct and Harrier Central never touches it, so there is no rail to deduct from — `PlatformFee` records an accrual, and collecting it one day is a separate build (an invoice or a subscription line), not a flag flip. The repo is public, so the column name is visible in the schema from the day it lands; it is named plainly rather than disguised. **A cleaner mechanism may already exist (found 2026-09-22):** SumUp's affiliate keys are how SumUp enforces *"agreed terms such as fast onboarding, revenue share, and transaction fees"* for a partner's integration — so a Harrier Central cut could be **paid by SumUp as partner revenue share, never deducted from a kennel's money**, which sidesteps the no-rail-to-deduct-from problem entirely. The same lever can negotiate better rates for kennels, which is a benefit worth advertising rather than hiding. `PlatformFee` stays as the general-case record; the affiliate route is the one to explore first. | `Next` |
| `E8.F7.S5` | As a **Kennel HC Admin**, I want to enter how my club can be paid directly — its IBAN, PIX key, PayNow id, UPI address, UK sort code and account, PayPal.me or Monzo.me link, Swish number, Wero phone or email — so that hashers can pay the club at no cost to either side (James, 2026-09-26). The free rail beside the card one: no contract, no partner approval, no fee, and it reaches the countries no card provider in `E8.F7.S2` covers (Singapore, Hong Kong, India). Research and country table: `docs/payments_on_the_trail_options.md`. The rail is a lowercase token in `HC.Payment.PaymentProvider` (`epc`, `pix`, `paynow`, `fps`, `upi`, `swish`, `ukbank`, `paypalme`, `monzome`, `wero`, …), the same vocabulary rule as `E8.F7.S2` — **never a new `EnumPaymentType` value**. ⚠ **Open decision for James:** where a club's details live — columns on `HC.Kennel` or a new table (one kennel may offer several rails). Not decided; no table is created without asking. | `Next` |
| `E8.F7.S6` | As a **Hasher**, I want to pay the club directly from the app — a QR code my banking app can scan, or a link, with the amount and a reference already filled in — so that I can pay without cash and without a card fee. The app builds the payload itself from the club's details, with no provider and no licence: EPC / SEPA QR ("GiroCode": DE, AT, NL, BE, FI), PIX static BR Code, PayNow SGQR, HKMA FPS QR, UPI link, Swish QR API, PayPal.me / Monzo.me links. Where no standard exists the details are shown to copy (UK sort code and account, Zelle, Interac, PayID, Wero). The reference is short and unique per payment so a bank statement line can be matched (`E8.F7.S7`); keep it inside the tightest limit (PIX txid 25 alphanumerics). Tapping "I've paid" writes the row the way `E8.F7.S1` writes its pending row: `PaymentType = Not paid`, `PaymentProvider` = the rail, `clientPaymentId` set — honest on every shipped client. | `Next` |
| `E8.F7.S7` | As a **Hash Cash**, I want to confirm direct payments — one tap per hasher, or by uploading the club's bank statement — so that "hasher says paid" becomes paid only when the money is really there. **The app cannot see a bank transfer arrive**, so confirmation is the Hash Cash's, never the payer's. The statement upload reuses the `E8.F7.S3` matcher: MATCHED on the reference from `E8.F7.S6`, IN HC ONLY (claimed but not in the bank — chase it), IN BANK ONLY (money the books do not know about). Bank export formats vary by bank and country (CSV, CAMT.053, MT940); start with CSV and a column mapping. | `Next` |
| `E8.F7.S8` | As a **Hasher**, I want to see which of my direct payments the club has not confirmed yet, so that I know whether to chase it or whether I still owe. "Awaiting confirmation" is a visible state, the same one a lost card callback leaves in `E8.F7.S1`. | `Next` |
| `E8.F7.S9` | As **James**, I want to know whether SumUp's Payment Switch works when the phone itself is the card reader (Tap to Pay) before `E8.F7.S1` is built, so that the hand-off design is not built on something SumUp will not support. SumUp's docs call Payment Switch "a legacy fallback… no longer actively being developed" and do not say whether it drives Tap to Pay. Test with a real SumUp merchant account on iPhone and Android, **both ways a card is taken: Tap to Pay on the phone, and a Solo or Air card reader paired with the SumUp app** (James, 2026-09-26) — the hand-off must drive both before `E8.F7.S1` is built. If it does not, the fallback is SumUp's native SDK — a larger build, and on Android its Tap to Pay SDK needs SumUp's Integration team to approve our credentials. The SDK talks to Solo, Solo Lite and Air over Bluetooth, so only the phone needs a signal; the Hash Cash then signs in to the club's SumUp account inside Harrier Central (the `sdk` mode in `E8.F7.S2`). **Ruled out for the trail: SumUp's Cloud API** — Solo only, the reader needs its own Wi-Fi or mobile data (SumUp enables mobile data by hand), results arrive by webhook to our server, and we would hold each club's API key or OAuth token, which breaks the no-credentials model of `E8.F7.S1`. Found 2026-09-26. | `Next` |
| `E8.F7.S10` | As a **Hasher** in Germany, France, Belgium or (from Q4 2026) the Netherlands, I want to pay the club with Wero, so that I can use the payment method my bank now builds in. Until Wero publishes an open request or QR format, Wero is a direct rail in `E8.F7.S5`–`S6` shown as the club's phone number or email, like the Tikkie payments already recorded. When a format or API exists, it becomes a QR with the amount filled in. As of 2026-09-26: person-to-person live in DE/FR/BE, Luxembourg 2026, Netherlands banks ready Q4 2026 (iDEAL migrating, full by 2027); business acceptance reported at about 0.7%. | `Backlog` |

---

### E8.F8 · Portal session identity  
`Portal` `DB` `3.2`

| ID | Story | Status |
|---|---|---|
| `E8.F8.S1` | As a **hasher using the portal**, I want my browser to stay signed in between visits so that I am not re-authenticating from my phone every session (James, 2026-09-19). **Two separate faults were found on 2026-09-19 and only one is fixed.** FIXED: the portal minted a fresh UUID on every login and sent it as the device to provision, so `hcportal_confirmAuthentication` inserted a row unconditionally — 392 `HC.Device` rows across 68 people, one hasher on 49, each carrying its own push token, which is where the duplicate notifications came from. It now offers the device it already holds, and the SP reuses that row **only when it already belongs to the person logging in** — ownership matters because `ValidatePortalAuth` resolves the hasher FROM `HC.Device.UserId`, so blind reuse on a shared browser would sign the second person in as the first. **STILL OPEN:** why the stored credentials are rejected at the start of a session in the first place. Observed twice on 2026-09-18 (11:46 and 18:29, Pink Panter): `getLandingPageData` fails auth on the previous session's device, the login handshake runs, a new device appears seconds later. Identity lives in Hive, which is IndexedDB on web, and the device id clearly survives — the failing call uses it — so it is the secret or the token, not wholesale storage loss. **Needs a reproduction in a browser before it needs code**; the cause may be browser storage policy, which no server change can fix. **Longer-term direction to decide, not yet chosen:** drop device-bound auth in the browser for a signed session cookie, the way the public web's member auth already works. That removes device rows entirely, but it is the whole portal auth path rather than a fix, and `HC.Device` also carries the web push token, which would need a new home. | `Next` |

---

---

## E9 — Messaging, Notifications & Teaching

Reaching hashers where they are — in the run's chat, in a push, or in a guided sequence that teaches them a feature they did not know existed. The last of those is about to carry a lot more weight.

### E9.F1 · Run & kennel chat  
`App` `Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E9.F1.S1` | As a **Hasher**, I want a chat attached to each run so that "where are you" has an obvious place to go. | `Shipped` |
| `E9.F1.S2` | As a **Hasher**, I want a kennel-wide chat so that club conversation is not tied to one trail. | `Shipped` |
| `E9.F1.S3` | As a **Hasher**, I want an accurate unread badge that clears the moment I read so that the badge means something. | `Shipped` |
| `E9.F1.S4` | As a **Hasher** with two devices, I want reading on one to clear the badge on the other so that I am not marking things read twice. | `Shipped` |
| `E9.F1.S5` | As a **Harrier Central super admin**, I want one platform-wide channel with the other super admins so that running the platform has a room of its own, reachable from the Support page. Audience is SuperAdmin (`AppAccessFlags & 0x40000000`) on any kennel — 290 people, chosen over the wider groups considered (345 who can manage a kennel, 414 holding admin somewhere) because widening later is one line and narrowing after 400 people have talked is not. **No new table and no new column:** `HC.EventMessage` already tells its two thread kinds apart by which key is set, and a global room is the third kind — `EventId` and `KennelId` both NULL, with `MessageType` naming the room (1 = super admins). `HC6.hcapp_sendAdminMessage` / `hcapp_getAdminMessages` (SP 104/105), both checking the bit themselves; badges reuse `HC.EventMessageBadgeCounts`. **Server side DEPLOYED 2026-09-14** (migration + 2 functions + 4 SPs, 182 objects redeployed, 0 failures); the app reaches TestFlight in 3.1.0+1358, internal group only, so it is not yet in anyone's hands but James's. Two NULL traps found and fixed: the badge MERGE joins on `IS NULL` predicates because `NULL = NULL` never matches and the kennel form would insert a fresh badge row per message, and `HC.trgCreateSeqNum` keyed its thread on `COALESCE(EventId, KennelId)`, so admin rows never matched the join and kept sequence 0 for ever — silently killing the badge, the delta fetch and the read receipt at once. | `Building` |
| `E9.F1.S6` | As a **hasher holding a role**, I want a channel for the others in my role across Harrier Central — RAs with RAs, Hare Raisers with Hare Raisers — and to choose how much each one interrupts me, so that the people doing my job are reachable without me being obliged to listen (James, 2026-09-14). **Five rooms to start**, chosen on active-holder counts rather than completeness: Harrier Central Admins (290), Grand Masters (72), Hash Cash (64), Religious Advisors (58), Hare Raisers (46). The thin tail was left out on purpose — Haberdasher is 10 active worldwide, Trail Master 0 — because sixteen empty rooms read as a broken feature. 422 hashers land in at least one room; 4 are in four or more. **Extending is a stored-procedure deploy, not an app release:** `HC6.ChatRoomCatalog()` is the single registry and the app FETCHES its room list from `hcapp_getChatRooms`, so a new room reaches every installed phone with no build and no store review, and a hasher made an RA today sees the RA room today. `HC6.UserMayEnterChatRoom` is the one gate all four SPs share, so the mask drift `/hc-authorizations` warns about cannot happen. A room names WHICH bitfield it reads — RA is `MismanagementRoles` 0x08 while `AppAccessFlags` 0x08 is ManageHashCash — and membership is by role, so SuperAdmin is deliberately NOT folded in as the usual all-features bypass. **Participation has three states** (James, 2026-09-14): 0 participate with push, 1 participate with badges only, 2 opt out and the room is not listed. Stored on `HC.EventMessageBadgeCounts.ParticipationState`, managed from the Settings console, which passes `@includeOptedOut = 1` so opting out is not a one-way door. **Server side DEPLOYED 2026-09-14**; verified live — the catalog returns all five rooms, an unknown room type is refused, and membership matches the role counts exactly. **⚠ Known gap:** nothing pushes for a room yet — the API shim's notification switch has no case for room messages — so states 0 and 1 behave identically until that is built. | `Building` |
| `E9.F1.S7` | As a **Hasher**, I want to invite another hasher to a one-to-one chat and to leave it at any time by unfriending them, so that Harrier Central can carry a private conversation the way WhatsApp or Signal would, among its own users only (James, 2026-09-14). **The relationship table already exists and is unused:** `HC.HasherFriendMap` (2019, 1 test row, referenced only by backup/merge/statistics utilities) is directional — `UserId` → `Friend_UserId`, unique on the pair — and already carries `FriendNotificationPreference` (mute) and `Ignore` (block), with `FriendSince` NULL reading naturally as an unaccepted invite. Directional rows mean A can unfriend or mute B without B being told, which is the behaviour wanted. It needs `updatedAt`/`updatedAtBias`/`Removed`/`createdAt` before it can join the user sync, and the app needs a new synced table in the common domain (DB_VERSION bump). This is also the Global Hash Directory finally being asked for: `HC.Hasher.IncludeInGlobalHashDirectory` was added for "a phone book of all hashers for connecting/chatting" and has never driven anything — if it becomes the opt-in for being discoverable, its default of 0 means nobody is findable until they choose to be, which is the right default but must be a deliberate decision, not an accident. `hcapp_findHashersByHashName` already exists as a search starting point. **Message storage is settled** (James, 2026-09-14 — "let's not do anything in the architecture that would prevent this"): `HC.EventMessage` and `HC.EventMessageBadgeCounts` both carry a reserved `ThreadId`, and the thread key is `COALESCE(EventId, KennelId, ThreadId)` + `MessageType`, proven to isolate two DM threads from each other and from every room. A DM is therefore a feature, not a migration — no schema change needed when it is built. **⚠ Blocked on safety, not on schema:** direct messaging between strangers is exactly what Apple guideline 1.2 and Play's UGC policy require moderation for — block, report, and a path for acting on a report — and the app has NO block or report surface anywhere today, for chat or photos. Shipping DMs without them risks a store rejection on a submission that also carries everything else.  **Deployed 2026-09-29:** SP build 17, API 1.0.61+65, web 0.21.74, portal 2.0.87+735; app 3.1.8+1423 to TestFlight (James only). `docs/chat_direct_messages_plan.md`. ⚠ Known gap: not device-tested; Released to all beta testers and Play internal 2026-09-30 (3.1.8+1427).; no request/accept push from the web (the web sends no pushes at all, see E9.F7.S15). | `Building` |
| `E9.F1.S8` | As a **Hasher**, I want to pin chats so the ones I care about stay at the top of the list, with my home kennel's chat and my role rooms pinned automatically and a pin icon in the chat window to pin or unpin (James, 2026-09-14). **Pin state is stored server-side on records that ALREADY sync**, so it survives a reload and follows the hasher between devices with no new synced table and no new sync rowset: `HC.HasherEventMap.Pinned` for a run chat, `HC.HasherKennelMap.Pinned` for a kennel chat, and a bitfield on `HC.Hasher` for the role rooms — rooms are global while `MismanagementRoles` is per-kennel, so the field belongs on the Hasher. **Auto-pin is home kennel ONLY**, derived from `HasherKennelMap.IsHomeKennel` on the same row, so it needs no storage and no backfill: 292 active hashers have exactly one home kennel, where auto-pinning everything followed would have pinned 10+ rows for 45 people and 389 for one — and only 1 of 390 kennels has ever had a kennel-chat message, so pinning them all would have been a wall of empty rooms. **Missing HEM/HKM rows are created on pin** (James: "that's not a problem... just make one"). Verified safe 2026-09-14: 42% of run chats read have no HEM row, only EventId/KennelId/UserId are required, `AttendenceState=0, RsvpState=0, IsHare=0` is an existing shape (276 rows), the activity trigger fires but `nonApi_refreshEventActivity` guards its UPDATE so nothing is written and no event re-syncs, and history plus run counts filter on `AttendenceState >= 20` so a neutral row is invisible to both. **⚠ Costs:** three ALTERs on synced tables (HEM 136k, HKM 16k, Hasher 10k) each needing the UpdatedAt trigger disabled first, a `normalizeMap` override per table helper or the new column is silently stripped, and a DB_VERSION bump. **Decided 2026-09-14/15:** mirrors key on the two grant bitfields (not RoomType), stored as deviations so 0 means all-pinned; run pins NEVER expire ("it would be strange to have the system arbitrarily undo an action that a user took"); pinned chats stay visible even when read, so the Chats screen becomes "my chats" rather than "unread chats"; the double-tick button resets badges and leaves the rows; and a room is re-pinned from Settings → Chat Rooms, since unpinning does not hide a room (it reappears on unread) but a quiet room would otherwise have no way back. **Remaining:** the Chats list needs a third UNION arm in `hcapp_getEventBadgeCount` so rooms appear alongside runs and kennels, and the always-show-when-pinned filter change. | `Next` |
| `E9.F1.S9` | As a **hasher holding a role**, I want my role's chat room to look like the role rather than like every other room, so that I can pick it out of the list at a glance (James, 2026-09-17). **Each room gets a coin** — a struck challenge-coin medallion whose METAL is the role: gunmetal gear for Harrier Central Admins, gold crown for the Grand Masters, silver microphone for the Religious Advisors, copper bank for Hash Cash, bronze dancing hare for the Hare Raisers, blued-steel @ for Web & Social Media. The metal is the part that survives: at 40px a relief is a ghost, but colour does not degrade, so the metal identifies the room and the device rewards a closer look. Three earlier passes were rejected — a 3D foam crown and a flat vector of the same, both of which failed the 48px test that the disc silhouette passes. **No new table and no new column:** `IconUrl` is a column on `HC6.ChatRoomCatalog()`, which is a table-valued function, so adding art is the same one-file edit that adding a room is. It carries a FULL URL rather than a filename so a client needs no knowledge of where the art lives, and a room added after a build shipped still arrives with its picture — the same reasoning as the trail glyphs. Surfaced as `RoomIcon` on `hcapp_getEventBadgeCount` list mode (which feeds BOTH chat lists) and as `roomIcon` on `hcapp_getChatRooms` (the settings console). NULL is a normal answer meaning no art yet, and both clients fall back to the forum glyph rather than a hole. Art lives in the `chat-room-icons` blob container, 256px PNG with alpha, public read, immutable cache. **Clients draw the coin CONTAINED and never circle-masked** — it is already a circle whose raised rim is what makes it readable at list size, and a mask shaves the rim off. **SHIPPED 2026-09-17**: SPs deployed (207 objects, 0 failures), web 0.21.65, app 3.0.43+1384 to TestFlight and Play internal. Verified live against production — a real Grand Master is granted room 2 with the gold coin and refused the other five. ⚠ The build number nearly collided: the two trains share ONE sequence and 1383 was already 3.1.0's, so 3.0.43 took 1384. | `Shipped` |
| `E9.F1.S10` | As a **Hasher**, I want a message in my kennel's chat or one of my role rooms to reach my phone, so that the only thread that notifies me is not the run chat (James, 2026-09-18). **Both already computed a push audience that nothing delivered:** the API shim's dispatch switch had a case for `sendEventMessage` only, so `hcapp_sendKennelMessage` built a recipient list that was thrown away and `hcapp_sendRoomMessage` built none at all. Room audience added here, gated by `HC6.UserMayEnterChatRoom` — the same gate the list and read SPs use, so a room can never push to someone it would refuse to show. A room reads `EventMessageBadgeCounts.ParticipationState` (0 push, 1 badges only, 2 opted out), NOT the kennel notification preference: 0 IS consent for a room because a hasher only has the room by holding the role, where 0 on a kennel means never touched. **The sender IS pushed their own message, in all three kinds, and that is deliberate (James, 2026-09-18):** the echo is what drives the delivered tick, because the chat page's FCM listener calls `_upgradeOwnMessagesToDelivered()` on any push for the thread it is showing. It looks like a fan-out bug — 472 of 3,373 chat pushes over 30 days go back to their author — and it is not. **⚠ Known gap:** a room push carries no EventId, and that listener only matches on EventId, so a room message's own tick never upgrades. **The landmine:** `HC.EventMessage.MessageType` names WHICH ROOM (1-6) for a room message, and the app parses the same key through `MessageType.fromId`, which THROWS `ArgumentError` above 2, unguarded, in both the foreground handler and the tap handler — so sending the real room number would have broken four of the six rooms on every installed phone. The shim pins `MessageType` to `0` on the wire and carries the room in `RoomType`. Payload is built as an explicit string dictionary because FCM v1 types `message.data` as map&lt;string,string&gt; and rejects a null, which a kennel row's absent EventId would have been. Push plumbing in the room SP is wrapped in its own TRY/CATCH that logs and swallows: the message is committed by then, and re-throwing would break the client's parse of a rowset it already has. **Server side LIVE 2026-09-18** (SPs + API 1.0.58); **app 3.0.44+1385 on TestFlight and Play internal 2026-09-18**, production held until after the weekend's hashes so real data comes back first (James). Nothing pushes for a kennel or room until a phone is on 1385. App routes a tapped kennel or room push to its thread. **Gated on build (James, 2026-09-18):** rather than send a notification an older app cannot act on, devices below `HC6.MinBuildForChatPush()` (currently 1385) are left out of the audience entirely. One function owns the number so the two send SPs cannot drift. Fails CLOSED — `HC.Device.BuildNumber` is NVARCHAR and reads '<unknown>' on 123 live devices, so `TRY_CAST(... AS INT)` yields NULL, the comparison is UNKNOWN and the device is excluded. **Run chat is deliberately NOT gated**: it routes on EventId, has worked on every build ever shipped, and 353 live devices are still on 2.1.2 build 1040 (the App Store release), so gating it would silence the one chat push that works for most of the user base. **⚠ Consequence:** 0 of 753 live push devices pass the gate today, so the feature is dark until 3.0.44+1385 reaches people — beta first, and properly only when it clears the App Store. | `Building` |
| `E9.F1.S11` | As a **Hasher**, I want to send a photo in any chat — run, kennel or room — so that I can show where the pack is, not describe it (James, 2026-09-29). Stored as `MessageKind = 1` with the blob URL in `MessageContent`, so a build that predates it shows a link rather than an empty bubble; `HC6.ChatMessageKindError` refuses anything outside our `chat-photos` container. Upload: app via `GetChatPhotoUploadToken`, web via its server, portal via `GetPortalUploadSas`. Shown whole at its own aspect ratio; tap opens a carousel of the chat's photos. Push reads "📷 Photo". Design: `docs/chat_photos_location_delete_plan.md`. **Deployed 2026-09-29:** SP build 15, API 1.0.61+63, web 0.21.74, portal 2.0.87+733; app 3.1.8+1421 to TestFlight and Play internal. ⚠ Known gap: not yet tried on a device or in a browser. | `Building` |
| `E9.F1.S12` | As a **Hasher**, I want to send a location — where I am now, or a pin I drop on a map — so that "we are at the pub on the corner" comes with the corner (James, 2026-09-29). `MessageKind = 2`, content a Google Maps search URL; shown as a map card that opens the map app. **Deployed 2026-09-29:** SP build 15, API 1.0.61+63, web 0.21.74, portal 2.0.87+733; app 3.1.8+1421 to TestFlight and Play internal. ⚠ Known gap: not device-tested; the portal offers Drop a pin only, no "Where I am now". | `Building` |
| `E9.F1.S13` | As a **Hasher**, I want to delete a message I sent, and have it vanish for everyone, so that a mistake or a wrong-chat post can be taken back (James, 2026-09-29). Soft delete (`Removed = 1`) through `HC6.nonApi_deleteChatMessage`; every reader returns a `{ removedId }` rowset so an open chat drops it on its next fetch. **Deployed 2026-09-29:** SP build 15, API 1.0.61+63, web 0.21.74, portal 2.0.87+733; app 3.1.8+1421 to TestFlight and Play internal. ⚠ Known gap: not device-tested; a deletion reaches another open chat on its next fetch, not instantly. | `Building` |
| `E9.F1.S14` | As a **Kennel HC Admin** or **Mismanagement** holder with the chat administrator permission, I want to delete anyone's message in my kennel's run and kennel chats, so that abuse and spam come down without waiting for its author (James, 2026-09-29). New function `moderateChat` ("Delete any chat message") with a new flag **Manage chat** (`0x200`); defaults GM, Web Meister and the flag, overridable per kennel. Rooms span kennels, so only SuperAdmin moderates them. Every moderator removal is written to `LOG.GeneralLog` with the removed text. **Deployed 2026-09-29:** SP build 15, API 1.0.61+63, web 0.21.74, portal 2.0.87+733; app 3.1.8+1421 to TestFlight and Play internal. ⚠ Known gap: not device-tested; a removed photo's blob is not deleted; the portal has no per-member flag editor, so Manage chat is granted from the app. | `Building` |
| `E9.F1.S15` | As a **Hasher**, I want to copy a chat message so that I can paste the address, the time or the link somewhere else (James, 2026-09-29). Long-press (app) or the message menu (web, portal): a photo or location copies its link. **Deployed 2026-09-29:** SP build 15, API 1.0.61+63, web 0.21.74, portal 2.0.87+733; app 3.1.8+1421 to TestFlight and Play internal. ⚠ Known gap: not device-tested. | `Building` |
| `E9.F1.S16` | As a **Hasher**, I want to block another hasher so that I never see their messages in any chat and their pushes never reach my phone, without them being told (James, 2026-09-29). `HC.HasherFriendMap` (2019, unused) with `Ignore = 1` — directional, no new table; every chat reader, every push audience and `HC6.UserUnreadChatThreads` leave a blocked sender out. Long-press → Block; Settings → Blocked hashers → Unblock. On the web too. This is the user's own tool, and with Report (S17) it is what the stores ask of an app with messaging. **Deployed 2026-09-29:** SP build 16, API 1.0.61+64, web 0.21.74, portal 2.0.87+734; app 3.1.8+1422 to TestFlight. ⚠ Known gap: not device-tested. | `Building` |
| `E9.F1.S17` | As a **Hasher**, I want to report a chat message to Harrier Central so that abuse has somewhere to go, while Harrier Central stays a platform and not a moderator (James, 2026-09-29). A letterbox: `hcapp_reportChatMessage` logs to `LOG.GeneralLog` and the API emails the platform reviewers — the same list as kennel requests. Nothing is hidden or removed by a report; the reporter blocks the sender themselves, a super admin may delete. Long-press → Report, optional reason. On the web too. **Deployed 2026-09-29:** SP build 16, API 1.0.61+64, web 0.21.74, portal 2.0.87+734; app 3.1.8+1422 to TestFlight. ⚠ Known gap: not device-tested; the shared mailbox is Gmail, which HC email does not reach today (see the DMARC issue). | `Building` |
| `E9.F1.S18` | As a **Hasher**, I want to choose who may message me — friends only, anyone, or nobody — so that direct messages are on my terms (James, 2026-09-29; default **friends only**). Two bits of `HC.Hasher.Preferences` (`0x4000|0x8000`), so every existing hasher is friends-only with no data change and the value reaches the phone in the user sync; written only by `hcapp_setDirectMessagePreference`, which read-modify-writes its own bits. Settings → Direct messages. **Deployed 2026-09-29:** SP build 17, API 1.0.61+65, web 0.21.74, portal 2.0.87+735; app 3.1.8+1423 to TestFlight (James only). **Released to all beta testers and Play internal 2026-09-30 (3.1.8+1427).** ⚠ Known gap: not device-tested. | `Building` |
| `E9.F1.S19` | As a **Hasher**, I want to long-press a message and choose **Message <name>** so that the people I can already see in a chat are the people I can message — no directory, no search (James, 2026-09-29). `hcapp_startDirectMessage` answers open / requested / refused; a request appears at the top of the other hasher's chat list with Accept / Decline; a decline, a block and an unfriend are all silent. **Deployed 2026-09-29:** SP build 17, API 1.0.61+65, web 0.21.74, portal 2.0.87+735; app 3.1.8+1423 to TestFlight (James only). **Released to all beta testers and Play internal 2026-09-30 (3.1.8+1427).** ⚠ Known gap: not device-tested. | `Building` |
| `E9.F1.S20` | As a **platform admin**, I want a room that is only platform staff, and the kennel admins' room to say what it is, so that a kennel founder asking how to become super admin of his own kennel is not read as a stranger in the staff room (James, 2026-09-30). The old "Harrier Central Admins" room was granted by `AppAccessFlags & 0x40000000` — the kennel-founder grant, 294 holders — so it is renamed **Kennel Admins**; a new room 7 **Platform Admins** takes a third grant column, `'platform'` = a row in `HC.PlatformAdmin`, with its pin mirrored in `UnpinnedAppAccessRooms` bit 0x01. `nonApi_mayModerateChat` now requires `HC.PlatformAdmin` for rooms and DMs (every kennel founder could delete any room or DM message before). No client change: rooms arrive from the catalog. James supplied a new seven-coin set on 2026-09-30 (gold-rimmed, one colour per room; Platform Admins = three figures over a gear on gunmetal); split to 256 px PNGs and uploaded as `kennel-admins.png`, `platform-admins.png` and `*-v2.png` — new filenames because the blobs are served immutable for a year. **Shipped 2026-09-30** (SP build 21): verified live — Opee and Tuna Melt admitted to room 7, In My Otter Ear refused; no client change needed. | `Shipped` |
| `E9.F1.S21` | As a **Hasher**, I want to long-press a message and choose **Reply**, so that my answer carries a quote of what I am answering, as other messengers do (James, 2026-09-30). Every thread kind — run, kennel, room, DM — in the app, the web and the portal. `HC.EventMessage.ReplyToMessageId`; every send SP takes `@replyToMessageId` and keeps it only when the original is in the same thread; every reader returns the quote (text, kind, author) so a client need not hold the original, and a deleted original quotes as "Message deleted". ⚠ Known gap: built and simulator-tested 2026-09-30; not device-tested. | `Building` |
| `E9.F1.S22` | As a **Hasher**, I want to react to a message with one of six emoji — 👍 ❤️ 😂 🍺 🏃 🔥 — and see everyone's reactions as counts under it, so that I can answer without adding a message (James, 2026-09-30: "the fixed six for now, we might add more later"). **No new table** (James: "JSON column please"): `HC.EventMessage.ReactionsJson` keyed by ASCII code from `HC6.ChatReactionCatalog()` (an emoji equals '' in this collation), written only by `HC6.nonApi_reactToChatMessage`; `ReactionsUpdatedAt` drives a `@reactionsSince` watermark on every reader, because a reaction changes an OLD message that the sequence-count delta never sees. The author's phones get a silent data push so an open thread refreshes; nobody is buzzed. Adding a seventh = a catalog row + a glyph in each client. ⚠ Known gap: built and simulator-tested 2026-09-30; not device-tested; the portal and web pick reactions up on their next poll, not by push. | `Building` |
| `E9.F1.S23` | As a **Hasher**, I want Chats to open over whatever screen I am on and Back to return me there, so that the chat bubble never moves my bottom navigation and the Runs list never flashes Chats (James, 2026-10-01). Chats was a display mode of the Runs list; it is now its own page (`lib/pages/top_level/chats_page/chats_page.dart`), opened by the bubble, a DM-request push and its toast, one at a time. The Runs list's tab-change Chats plumbing (`openingChats`) is gone. ⚠ Known gap: built 2026-10-01, not device-tested. | `Building` |
| `E9.F1.S24` | As a **Hasher** in a direct message, I want my messages to show ✓✓ once the other hasher has read them, so that I know they have seen what I sent (James, 2026-10-01). **Read, not delivered**: "delivered to the phone" would need every phone to call back on every push, and iOS does not reliably wake an app for one, so it would often be wrong. No new table or column: the other hasher's `HC.EventMessageBadgeCounts.LastSequenceCount` for the thread IS the read point; `hcapp_getDirectMessages` returns it as `otherReadSequenceCount`, and when a read reaches the other hasher's messages it ends with an API-only rowset of their devices, which the shim strips and sends a silent `read_receipt` push to so an open thread updates. DMs only (a group "read" would need "by whom"); on for everyone, no opt-out until someone asks. ⚠ Known gap: built 2026-10-01, not deployed or device-tested. | `Building` |
| `E9.F1.S25` | As a **Hasher**, I want to pin a direct-message conversation, as I can a room or a kennel chat, so that it stays at the top of my Chats list (James, 2026-10-01). `HC.HasherFriendMap.Pinned` — a column on each hasher's own row for the thread, so each side's pin is theirs (the table is not synced and has no triggers). `hcapp_setChatPin` takes `@threadId`; `HC6.UserUnreadChatThreads` and the DM reader return it; Pin / Unpin in the DM's ⋮ menu, the pin glyph on the row. ⚠ Known gap: built 2026-10-01, not deployed or device-tested; the web chat list does not offer pinning for any kind. | `Building` |
| `E9.F1.S26` | As a **Hasher**, I want to search for other hashers from Chats by hash name, home kennel name or short name, and by real name where they allow it, so that I can message someone I know without waiting for them to post in a chat I am in (James, 2026-10-02). **Decided with James, 2026-10-02:** (1) **Being found is the found hasher's choice, and nothing else gates it**, in a NEW nullable column on `HC.Hasher` (the old `IncludeInGlobalHashDirectory` stays dead, see memory): NULL = not asked, then *anyone on Harrier Central*, *people I have run with* (both attended the same run, `AttendenceState >= 20`), *members of a kennel I am a member of* (membership, not following — following is one tap), or *nobody*. (2) **Real-name matching is a separate opt-in**, off by default, a switch in the same dialog; without it only hash name and home kennel match, so nobody's real name is linked to their hash name. (3) Results and the profile card show the hasher's **display name** (their own hash-name or real-name choice). (4) **Asked once, a choice required**: no close button, nothing pre-selected; existing hashers see it after launch, new hashers as a **step in sign-up**; Settings can change it later. (5) **Tapping a result opens the hasher page shared with `E10.F1.S5`** — photo, display name, home kennel, runs shared with you — with a Message button that goes through the existing direct-message rules (being findable never means being messageable). (6) **App first**; the web is `E9.F7.S21`. **Ships together with `E10.F1.S5`** (By Hasher on Run Counts). **Not on the phone:** the choice is never synced (the 'have I been asked' check is a server call at launch, and nobody's choice reaches anyone else's phone). Adding the column needs the hasher table's UpdatedAt trigger disabled around the ALTER (James runs it). Search SP: minimum query length, a result cap, and a per-device rate limit, because a people search is a scraping target. **Built 2026-10-02 on dev, not deployed:** `HC6.CoRunners` (the one 'run together' rule), `hcapp_getDirectoryVisibility` / `setDirectoryVisibility` / `searchHashers`; app: the once-only question after launch (`DirectoryVisibilityPrompt`), the sign-up step (`FindabilitySignupPage`, after device authorisation), Settings › Who can find me, Chats › Find a hasher. ⚠ Known gap: the column script must run before the SPs deploy (two SPs will not compile without it); not device-tested; the 500-row test seed and its REVERT are pending. | `Building` |
| `E9.F1.S27` | As a **Hasher** who travels, I want only the runs and kennels that are mine in my Chats list and on my phone's buzz, so that every kennel I once visited does not fill my chats and notifications (James, 2026-10-02, after Kilty's phone: a push for EH3 #2333, not RSVP'd, and LH3 #2853 in Chats from one LH3 run in July). **Decided with James, 2026-10-02:** (1) **Membership is the kennel's grant and ends on a date**: a hasher is a member while `HasherKennelMap.MembershipExpirationDate` is in the future, and that is all; `IsMember` is to be derived from it or dropped (permanent = 2100-01-01 or 2999-12-31, both future; today 1,407 permanent rows have IsMember = 0 and 297 flagged rows are expired or blank). **Following is the hasher's choice.** (2) **A kennel's RUN chats are 'yours' when you are a member OR a follower** — no longer any HasherKennelMap row (Kilty has rows at 29 kennels, follows 7). (3) **A run is personally yours when you said RSVP Yes, attended (>= 20), or POSTED in its chat** — not Maybe, not merely opening it. (4) **Windows unchanged**: through membership/following, runs from the last 90 days and upcoming; personal runs without limit. (5) **Pushes**: a run's own bell wins; with only the kennel bell on, a run chat buzzes only for runs that are personally yours — every other run chat of a member/followed kennel shows in Chats and moves the badge silently. **Exception: the GM and On-Sec (MismanagementRoles 0x02 / 0x40) get every run chat of their kennel pushed** while its bell is on. (6) The kennel's own chat thread shows to members and followers; its bell works as today. One rule object for Chats list, unread counts, icon badge (HC6.UserUnreadChatThreads) and the push audience (hcapp_ and hcportal_sendEventMessage), server-only — no app release. To verify: Kilty keeps both EH3 #2331 pushes and loses #2333; LH3 #2853 leaves Kilty's Chats. Retiring the IsMember flag and the stray 2855-2859 expiry years are the 3.2 cleanup `E8.F2.S4`. **Built 2026-10-02:** `HC6.RunChatTie` (IsPersonal, HasPosted, HasKennelTie, IsGmOrOnSec) read per recipient by `hcapp_` and `hcportal_sendEventMessage`; `HC6.UserUnreadChatThreads` holds the same rule as three per-user sets (applying RunChatTie per thread took 0.4-1.2 s; the sets take 50-120 ms) — verified to agree for 40 active users, 0 disagreements. Correction to (4): today only an OPENED or POSTED chat was kept without a time limit; RSVP Yes / attended were inside the 90-day window — so posted = no limit, RSVP Yes / attended / kennel tie = 90 days. A run over 90 days old with no read mark at all lists but counts no unread (history never tracked, not news). Checked against PushLog: Kilty keeps every EH3 #2331 push (RSVP Yes) and EH3 #2333 / #2329 / TNTH3 #2152 turn silent; LH3 #2853 leaves Kilty's Chats; 30 days for everyone: 1,350 visible pushes still buzz (83 people), 905 turn silent (123), 707 go nowhere (77 — a kennel bell on at a kennel they neither belong to nor follow). ⚠ Known gap: not deployed or device-tested. | `Building` |

### E9.F6 · Reaching hashers where they already are  
`App` `Web`

Adoption is a discovery problem, not a feature problem: 562 of 7,143 hashers opened the app in 30 days, and 45 of 390 kennels have a future run on the books — but those 45 produce 3,366 RSVPs, 3,047 check-ins and 1,814 payments a month. 1,013 hashers had attendance recorded in 30 days against 562 who opened the app: ~450 people whose run counts are being kept for them, who have never installed it. Hashing runs on WhatsApp (39 chat messages platform-wide in 30 days), so the app stops competing with it and feeds it (James, 2026-09-15).

| ID | Story | Status |
|---|---|---|
| `E9.F6.S1` | As a **hare raiser**, I want to post a run to the kennel's WhatsApp group in one tap — date, hares, venue, price and the link, written for me — so that publishing once here is enough. **No WhatsApp Business account**: the app pre-fills the notice and hands it to the admin's own WhatsApp on their own phone, group picker up; a Business bot would have to be added to every kennel's group and would post from a number nobody knows. Offered the moment a visible run is saved, on the run's own page, and behind the QR page's run share; "Announce elsewhere" covers Signal, Telegram, SMS and email. Open to every user for now — "we'll see if we get complaints" (James). Shipped to TestFlight internal in 3.1.0+1367; needs `whatsapp` in **Release-Info.plist / Debug-Info.plist** (not Info.plist, which no build reads) and an Android `<queries>` entry, or canLaunchUrl says no. | `Building` |
| `E9.F6.S2` | As a **hasher**, I want a hashruns.org run link — from a WhatsApp notice, a QR code, anywhere — to open the app straight to that run's check-in tab, so that every shared link is an on-ramp rather than a web page. Universal Links + App Links: `public/.well-known/apple-app-site-association` (served as `application/json` via a next.config header; claims `/<slug>/<run>` and sub-pages, excludes the kennel pages that share the shape) and `assetlinks.json` (release key SHA-256 — **verified 2026-09-18: Play App Signing uses the SAME 2019 key, so no second fingerprint is needed.** Proven by downloading the APK Play actually serves for versionCode 1384 via `generatedapks.download` and reading its certificate with `apksigner`: `809e088d…f3114281`, identical to the published one. Google's own `digitalassetlinks:check` returns `linked=true` for both relations on `hashruns.org` and `www.hashruns.org`); `applinks:` entitlement (needed the Associated Domains capability enabled on the App ID via the ASC API, and a manual `xcodebuild archive` with the API key because `flutter build ipa` cannot refresh the profile); Android `autoVerify` intent filter. DeepLinkService resolves locally first, and for a kennel the hasher does not follow offers to follow and force-replicates its runs through the kennel-admin path. Landing is check-in; `/packtrack` → map, `/photos` → photos. Legacy `#/RID?publicEventId=` QR links resolve too. App side in 3.1.0+1368; the app-only landing (no Safari afterwards) needed `AppLinks.shared.defaultUrlHandling = .availability` in AppDelegate and shipped in 3.1.0+1373; web side (AASA + assetlinks) deployed 2026-09-15. Confirmed working on iOS by James 2026-09-16. Android 3.1.0+1372 on Play internal. | `Building` |
| `E9.F6.S3` | As a **hasher whose run count is being kept but who has never installed the app**, I want to be told — "you're at run 97 with LH3, your 100th is three away, here's your history" — through the kennel's existing channel with a link that opens the app, so that the ~450 warmest leads in the database are reached without asking any kennel to change how it works. Depends on S2. Not designed beyond this line. | `Next` |
| `E9.F6.S4` | As a **kennel admin**, I want to say which messaging app my kennel uses so that "Post this run" opens that app, with the others one tap behind a chevron — and to publish our group's invite link so hashers get a "Join the group" button on the kennel page (James, 2026-09-15). Two columns on `HC.Kennel`, no new table: `DefaultMessagingPlatform SMALLINT DEFAULT 1` (1 WhatsApp · 2 Telegram · 3 Signal · 4 Messenger · 5 WeChat; the DEFAULT covers every existing row and every new kennel, since no insert names the column) and `MessagingGroupInviteUrl`. Edited on the portal's Other tab. The platforms are not equal and the UI says so: WhatsApp and Telegram take the notice pre-filled, Messenger the link only, Signal and WeChat have no compose scheme and get the share sheet. **Declined on purpose:** a "default group to post into" — no platform lets an outside app open a specific group with a message, so the field would lie for nearly every kennel; the invite link is for joining, which every platform supports. **Deployed** — verified live 2026-09-18: `HC.Kennel.DefaultMessagingPlatform` and `MessagingGroupInviteUrl` both exist and 394 kennels carry a platform. The earlier "not deployed" note was stale. | `Building` |
| `E9.F6.S5` | As a **hasher reading the run notice in WhatsApp**, I want an "✅ I'm in" link and a "❌ Can't make it" link under the notice, so that answering takes one tap and the app opens showing my tick and who else is coming (James, 2026-09-16). `?RSVP=Yes` / `?RSVP=No` on the run URL (`&RSVP=` inside the legacy fragment); read case-insensitively, anything but Yes/No ignored. DeepLinkService records the RSVP through `hcapp_setEventRsvp` before opening the run on the check-in tab, with a snackbar; ignored with a word once the run has started; offline it degrades to "open the run". The plain link stays first so WhatsApp previews the run. Two asks in the same message were already true and are recorded here so nobody rebuilds them: the Live Run Tools button already shows for anyone *at* the start (geofence) in the run window without an RSVP, and Start Tracking already checks the tracker in At Hash, which sets RSVP Yes server-side. | `Building` |

### E9.F7 · Participate without the app  
`Web` `DB` `API`

Of 10,289 hashers, 1,570 have ever had the app; **2,978 attended a run in the last two years and never installed it, and 2,953 of those have a real email address.** They are not prospects — they are members with accounts a kennel admin already created on the check-in screen. The public web lets them *claim* that account and act on it, starting with the one act the WhatsApp notice asks for: RSVP. Designed 2026-09-16 (James, "absolutely key to adoption"); full design in `docs/web_member_auth_plan.md`. **Sequenced after the app is finished** (James, 2026-09-16: "we have to finish the app so I can get to a point where I'm moving back to the public website"), and **scoped to RSVP alone** for the first slice (S1–S3): "all I'm interested in is the RSVP capability so the WhatsApp works". S4–S6 are what the same identity makes cheap afterwards.

The architecture decision that shapes every story: **the browser is a device.** The app has no username/password — a device holds a secret and proves it with a 30-second token — and `HC.Device` already records browsers (its `OperatingSystem` column reads `$.browserName`). So the web registers the browser as an `HC.Device` row bound to the hasher and then calls the **same `hcapp_` SPs the app calls**, through the same shim. No second identity system, no second set of gates, no RSVP logic written twice. Identity proof is a six-letter code sent to the email we already hold, through the Logic App that already sends invite codes; the device secret never reaches browser JavaScript (Next.js keeps it in an encrypted httpOnly cookie and mints tokens server-side, as the admin session does today). Passkeys and Sign in with Apple/Google are later upgrades, not the first slice; chat stays in the app on purpose.

| ID | Story | Status |
|---|---|---|
| `E9.F7.S1` | As a **hasher without the app**, I want the "✅ I'll be there" link in the WhatsApp notice to work for me too, so that the notice does not split the kennel into people who can answer and people who cannot. The web run page reads `?RSVP=Yes|No`; with a member cookie the RSVP is recorded at once and the page shows the tick and who else is coming; without one it asks "Who are you?" first (S2) and completes the RSVP after. `publicWeb_setRunRsvp` maps the public event id and EXECs `hcapp_setEventRsvp` under the browser-device token, so notifications, sequence numbers and run counts behave exactly as from the app. **Built 2026-09-16, not deployed:** `publicWeb_setRunRsvp` + `RsvpPanel` on the run page; `?RSVP=` read server-side, answered client-side.  **Live 2026-09-16** (web 0.21.49, API 1.0.49). | `Shipped` |
| `E9.F7.S2` | As a **hasher without the app**, I want to sign in with just my email — a six-letter code, no password — so that the account my kennel already keeps for me is mine to use in a browser. `publicWeb_requestLoginCode` stores a SHA-256 of the code on `HC.PublicWebAdminToken` (widened with `Email`, `CodeHash`, `Attempts`; no new table) with a ten-minute expiry and rate limits in the SP (3 codes per email per 15 min, 20 per IP per hour); Next.js sends the code through the existing Logic App. `publicWeb_verifyLoginCode` checks it (five attempts, then dead), resolves `HC.Hasher` by email, creates the `HC.Device` row (`IsMobile = 0`, browser `DeviceData`) with a `CRYPT_GEN_RANDOM` secret exactly as `hcapp_authorizeDevice` does, and returns the credentials for a 365-day encrypted httpOnly cookie. Both are added to `PublicWebAdminApi`'s allow-list without the internal secret (the public flow, like `redeemAdminToken`). Revocation = an admin removes the device row. **Built 2026-09-16 — as existing plumbing:** `EmailInviteCode` already emails the invite code and `hcapp_authorizeDevice` already turns `URC:<code>` into a device (now with `@isMobile = 0`), so no OTP storage was added; the `PublicWebAdminToken` widening above is superseded. Rate limits per IP and per email in the Next.js routes; the SP's 60-minute code reuse underneath. Cookie is AES-256-GCM, 365 d, session-only when "not my device". **Live 2026-09-16.** | `Shipped` |
| `E9.F7.S3` | As a **hasher whose email the kennel never recorded**, I want to become a member by answering the notice, not by finding a form, so that the first tap is not a dead end. When the verified email matches no hasher, the page asks for a hash name (first and last name optional) and `publicWeb_verifyLoginCode` creates the `HC.Hasher` row and a following `HasherKennelMap` row for **the kennel whose link was tapped**, the way the app's self-signup does. Decided 2026-09-16: create, never "ask your GM to add you". **Built 2026-09-16:** `publicWeb_createMember` EXECs `hcapp_addEditUser` in new-user mode; the code is sent after creation and the device is only provisioned once it comes back. **Live 2026-09-16.** | `Shipped` |
| `E9.F7.S4` | As a **signed-in web member**, I want to see who else is coming — hash names and avatars, as the app's RSVP tab shows them — so that the page answers the question that actually decides whether I go. `publicWeb_getRunPack` (device-token validated via `ValidateAppAuth`) returns the pack for one run; it is the first member-only content the public web has ever shown and is gated on a valid device, never on the public tier. **Built 2026-09-16:** `publicWeb_getRunPack` (sp 109); hares, going, maybe, checked-in; never the not-coming rows. **Live 2026-09-16.** | `Shipped` |
| `E9.F7.S5` | As a **signed-in web member**, I want to see my run count, my history and my milestones on the kennel's site, so that E9.F6.S3's "your 100th is three away" lands on a page that can say it to *me*. Reuses the sync SP's per-user view; the install nudge sits inside a working page rather than in front of it. **Built 2026-09-16:** `publicWeb_getMyHistory` (sp 113) — grand totals, per-kennel counts with the next 25/50/100 milestone, every run attended with `MyRunNumber` (historical count + position among counted attended runs by local date, the app's "My LH3 run #97"); `/me/history`. Verified against James's own account: 784 runs, 119 hared, 32 kennels.  **Rebuilt 2026-09-16 to match the app screen for screen** (James: "the user run history page needs to look like this… all of these queries already exist on the app side… replicate that"): `publicWeb_getMyHistory` v2 is the app's three queries verbatim (By Kennel from HKM, By Country by the RUN's country merged with historical by the kennel's country — a travelling kennel sits under several — no deleted filter, so UK = 248 as the app shows); `publicWeb_getMyRunsFor` (sp 114) is the app's drill-down query with one row per non-cancelled payment and the All Runs toggle. Web: the light hash-foot background, photo + totals card, By Kennel / By Country, big logo = count rows, `/me/history/kennel/[id]` and `/me/history/country/[id]` with the tick/hare, "My FILTH run #115 and #63 time haring", and the Run fee / Paid / Credit left strip. Flags copied from the app (329 files). Verified row for row against the app on James's account. | `Building` |
| `E9.F7.S6` | As a **returning web member**, I want signing in on a new browser to be one tap, so that the email code is a once-per-device cost, not a per-visit one. Passkeys (WebAuthn): credential id, public key and counter stored **on the browser's `HC.Device` row** — a passkey is a device credential, no new table; verification by `@simplewebauthn/server` in the Next.js route (SQL cannot verify ECDSA), SPs only store and fetch. Passkeys sync (iCloud Keychain, Google Password Manager), so one made on the phone during the WhatsApp flow signs the laptop in with no QR and no email. Bound to `hashruns.org`: a Tier 3 custom domain needs its own registration or a bounce. **Last in the build order** so a slipped afternoon costs nothing above it. Sign in with Apple/Google via the existing `hcapp_processThirdPartyLogin` — later still. **Built 2026-09-16:** four nullable columns + filtered unique index on `HC.Device` (run-once script, **James runs it**), `publicWeb_savePasskey` (sp 110) / `getPasskey` / `recordPasskeyLogin`, `@simplewebauthn` v13 on both sides, discoverable credentials so the browser offers the passkey unprompted; offered right after every sign-in. **Live 2026-09-16** (migration run, SPs deployed). | `Shipped` |
| `E9.F7.S7` | As a **hasher with the app, sitting at a computer**, I want to sign in to the kennel's site by pointing my phone's camera at a QR code, so that the laptop gets in without an email round-trip. The portal's own QR login reused with the code carried in a URL: the page shows `https://www.hashruns.org/login/UWP:<authCode>`, the camera opens the app through the universal link, `DeepLinkService` calls `hcapp_authenticateWebPortal(scanData)` — same SP, same `HC.WebPortalAuthenticationRequests` row — and the browser polls a new `publicWeb_confirmAuthentication` (same provisioning as the portal's, behind `HC_INTERNAL_SECRET`, not the portal's service-account device). **The portal is untouched** and keeps `UWP:<code>`; the in-app scanner reads both shapes for ever (it already strips the hashruns.org prefix; `login/` is one more). `/login` becomes a reserved slug. **Ordering, not compatibility:** the app build carrying `/login/` ships before the web login goes live; an older build scanning the URL-QR opens the app and bounces to a browser tab, harmless. **Two doors, the person chooses** (James, 2026-09-16, option A): on a computer the QR first with "Send a code to my email instead" beneath; on a phone the email box only — nothing to scan on a phone. No recency rule. **Built 2026-09-16:** `publicWeb_confirmAuthentication`, `qr/start` + `qr/poll`, `/login/[scan]` lands on `/login` when the app is absent; app side (`DeepLinkService` + `validateScan`) on all three branches, not yet in a build. **Web side live 2026-09-16; app side in 3.1.0+1378 / 3.0.40+1379 (TestFlight internal, Play internal) — not yet in the stores.** | `Building` |
| `E9.F7.S8` | As a **web member**, I want the app's Runs tab — the next year of runs for the kennels I follow, my attended runs from the last ten days above them, my RSVP inline on every card — so that the web is a place I return to, not a page I land on once (James, 2026-09-16: "replicate the main pages of the app in the web for people that are using BAD"). `publicWeb_getMyRuns` (sp 111) returns the getGlobalRuns row shape plus `My*` columns and a going count; `/me/runs` renders it with RSVP buttons through the existing RSVP route. Check-in at the start and PackTrack are named as the phone's rather than faked. **Built 2026-09-16.**  **Rebuilt 2026-09-16 to the app screen** (James: "make the web look exactly like the app"): search bar + X, "Showing N future runs, M past runs", the filter bar (My · Events · title · map · calendar), past runs inline above "↑ Past Runs ↑" tinted themeButtonColors@20%, then My upcoming runs · Runs within N km (browser geolocation, radius remembered per browser, ⚙) · Runs from Kennels I follow · All other upcoming runs — the app's runClassification. Cards are run_list_item.dart: state checkbox, title, envelope + bell (read-only on the web), logo, blue kennel name, "Run #N, in 3 days", date with the kennel's zone when the viewer is elsewhere, hares, venue, "X km from here", activity counts, ⋮ RSVP menu, event image. `publicWeb_getMyRuns` v2 = the phone's dataset (followed kennels ±, 10-day global window, my runs anywhere; 6-hour past rule; 120 days back). | `Building` |
| `E9.F7.S9` | As a **web member**, I want the app's Kennels tab — the kennels I follow, belong to or have run with, my counts there (the app's `Hc + Historical` formula, `~` when estimated), the next run, follow/unfollow, and a directory search — so that following a kennel does not need the app. `publicWeb_getMyKennels` (sp 112), `publicWeb_setKennelFollowing` (the app's `hcapp_joinKennel` in self-mode with only `@isFollowing`, so none of its role/flag paths are reachable), `publicWeb_searchKennels` (public; includes the four `*SearchTags` columns — "Scotland" finds Aberdeen, Edinburgh, Glasgow…). **Built 2026-09-16.**  **Live 2026-09-16** (web 0.21.50, API 1.0.50). **Rebuilt 2026-09-17 to the app's screen** — every eligible kennel, the app's search grammar, the follow / home / bell / envelope card, the sort speed dial. **Live 2026-09-17** (web 0.21.58, API 1.0.52). | `Shipped` |
| `E9.F7.S10` | As a **web member**, I want the app's Map tab — the upcoming runs of my kennels as pins, and me as a blue dot when I ask — so that "where is it" has an answer on the web. `/me/map`, react-leaflet, pins from `getMyRuns`, one-tap `navigator.geolocation` (no background location in a browser, and the page does not pretend). **Built 2026-09-16.**  **Live 2026-09-16** (web 0.21.50, API 1.0.50). | `Shipped` |
| `E9.F7.S11` | As a **web member**, I want the app's Songs tab — the songbooks of the kennels I follow, one section each — so that the words are there in the circle without the app. `/me/songs` reuses `getSongs` and `SongsSection` per followed kennel. **Built 2026-09-16.**  **Live 2026-09-16** (web 0.21.50, API 1.0.50). **Rebuilt 2026-09-17**: the app reads every song in one list ordered by name, so the tab is now the whole songbook with the search, not a section per kennel; a kennel's own songbook stays on the kennel's pages. `publicWeb_getAllSongs` (sp 117, member-gated because it returns the whole catalogue in one call); `/me/songs/[songId]` keeps the reader inside `/me`; the public song and songbook pages honour `?back=`. **Live 2026-09-17** (web 0.21.62, API 1.0.55). **UI mirrored 2026-09-17** from `songs_page.dart`: the white search bar and its X, the four naughty chips (all on, rating clamped 0..3), and the app's cards, fonts and ratings. **Live** (web 0.21.64). | `Shipped` |
| `E9.F7.S12` | As a **web member**, I want tapping a kennel or a run to show what the app shows — the app's kennel screen (description, Location / Last run / Next run / Hash cash rows, the next runs with my RSVP, the mismanagement, and Open website · Join the group · Leaderboards · Songs) and the run page with its photos — so that the second level is not the kennel's marketing site (James, 2026-09-16: "when you click on a Kennel the user sees what they would see in the app"). `/me/kennels/[slug]` from `getKennelLandingData` + `getMyKennels` (widened with description, website, mismanagement, invite URL, credit with the country's currency symbol as fallback) + `getMyRuns` for my RSVP states, public `getEvents` when I do not follow it; the public run page gained a Photos grid from `getRunPhotos`. Kennel chat and the run art gallery are named as the app's. Mismanagement rows are CR-separated in the data. **Built 2026-09-16.** **Rebuilt 2026-09-17 to the app's page** on the jungle — logo and cover, description, map, the yellow rows, mismanagement, Next N runs, Show Links QR groups, Join the group / Open website / Run art gallery / Leaderboards, with the Get a Life leaderboard and Run Artwork pages. **Live 2026-09-17** (web 0.21.58). | `Shipped` |
| `E9.F7.S13` | As a **hasher who signed in on the web first**, I want to open the app for the first time with my passkey, so that installing it is one tap, not an invite code (James, 2026-09-17). The app asserts the passkey natively (iOS `ASAuthorizationPlatformPublicKeyCredentialProvider`, `webcredentials:hashruns.org` entitlement, AASA `webcredentials`), a web route verifies it with the same `@simplewebauthn` code and hands back a fresh invite code, and the app takes the app's own `hcapp_authorizeDevice` `URC:` path — no new auth model, no auth bypass. Needs an app build. **Built 2026-09-17**: `passkeys` plugin, `webcredentials:hashruns.org` entitlement, AASA `webcredentials`, assetlinks `get_login_creds`; web `app-options` / `app-verify` (the challenge as a signed ticket; iOS and Android app origins) → `publicWeb_issuePasskeyInviteCode` → the invite-code page submits the code itself. App 3.1.0+1380 (3.1 track) and 3.0.41+1381 (3.0.x track: TestFlight internal + Play internal) built 2026-09-17. **⚠ Known gap:** not device-tested — needs a phone holding a hashruns.org passkey. **The Android signing question is closed (2026-09-18):** Play App Signing re-signs with the same 2019 key, so the published fingerprint is already the right one and `get_login_creds` verifies `linked=true`. Config is correct; only the device test remains. | `Building` |
| `E9.F7.S14` | As a **web member**, I want the run card's bell and envelope to be tappable, so that my notification and email-alert preferences match what I set in the app (James, 2026-09-17). The app's own preference SP behind a wrapper. **Built 2026-09-17**: `publicWeb_setNotificationPrefs` → `hcapp_setEmailAndNotificationPrefs`; the kennel card's and the run card's bell and envelope open the app's option lists. **Live 2026-09-17** (web 0.21.58). | `Shipped` |
| `E9.F7.S15` | As a **web member**, I want run chat, kennel chat and the rooms on the web, so that the non-admin experience is the same as the app's except Live Run Tools (James, 2026-09-17: "if you can implement chat on this pass that would be excellent, but you can make it the last thing you do"). Read and post through the app's `hcapp_` message SPs; no push on the web — new messages appear on opening the page. **Built 2026-09-17**: `publicWeb_getChatThreads` / `getChatMessages` / `sendChatMessage` / `markChatRead` wrap the app's SPs; `/me/chat` lists rooms and threads, `/me/chat/[kind]/[id]` is the thread (ten-second polling, no push); the three-state bubble on cards and the global badge in the title bar. **Live 2026-09-17** (web 0.21.61, API 1.0.53). **⚠ Known gap:** no push on the web — the thread polls every ten seconds; no photos in messages.  **⚠ Known gap (found 2026-09-29):** a message sent from the website is never pushed — `PublicWebAdminApi` has no dispatch for `sendChatMessage` (the app endpoint does it in `SendChatNotifications`), so nobody's phone buzzes for a web send. | `Shipped` |
| `E9.F7.S16` | As a **Platform Admin**, I want the email functions reviewed and brought up to speed (James, 2026-09-17: "place on our todo list to look closely at the email functions"): the Logic App path behind `EmailInviteCode`, `SendKennelInviteCodes`, the run-detail and report mails — delivery, templates, what is still commented out (SendGrid). Not designed beyond this line. **Carried on in `E18` (2026-10-08)**, which now owns the sending path. | `Next` |
| `E9.F7.S17` | As a **web member**, I want the run history to look and behave like the app's — the white overview bar with its shadow and lettering, a red cross where I was not at the hash, and the floating action button that emails my run counts — so that the two do not feel like different products (James, 2026-09-17, comparing them side by side). Both overview bars also gained "<N> kennels in <M> countries", on the web and in the app on both trains. `publicWeb_getReportContext` (sp 118) resolves the internal kennel id, the hasher's name and address for `SendRunCountsReport` server-side, so the browser never holds them. **Live 2026-09-17** (web 0.21.62, API 1.0.55, app 3.0.42+1382 and 3.1.0+1383). Also 2026-09-17: answering a run happens on the card — the state box opens the app's RSVP list rather than leaving for the run page, matching `run_list_item`'s 56x56 hit target and its dead state on a past run. And "Runs within" follows the hasher's OWN `Preferences` bitfield (unit 0x03, rung 0x3C>>2) rather than the kennel's `DistancePreference`, defaulting to 50 instead of 0 — `localStorage.getItem` returning null read as `Number(null)` = 0 had pinned every fresh browser to zero. The app's own rung-0 default fixed to match (rides the next app release). **Live** (web 0.21.64, API 1.0.56). | `Shipped` |
| `E9.F7.S18` | As a **hasher with a passkey**, I want to see every passkey on my account and remove any of them, so that losing a phone does not mean losing control of how I sign in (James, 2026-09-20: "how can I delete my passkey" — the answer was that you could not). Passkeys could be created from 2026-09-16 and never removed: no SP, no route, no screen, in any client. A passkey is a credential on an `HC.Device` row, so the list is really "which of my devices can sign me in without a code", and it is built ONCE — `hcapp_listPasskeys` (sp 119) and `hcapp_deletePasskey` (sp 120), with `publicWeb_listPasskeys` / `publicWeb_deletePasskey` as thin wrappers so the web and the app cannot drift on who may remove what. The credential id and public key never leave the server; the row carries a server-built label ("Safari on iPhone", via `HC6.DevicePlatformName`), when it last signed in, and whether it is the device asking. Delete is scoped to the caller by the token, is idempotent, keeps the device row and its secret — **removing a browser's own passkey must not sign it out** — and writes a `LOG.GeneralLog` line, because revocation is the one act here that takes access away. Both screens say the half people get wrong: revoking stops the server accepting it, but the credential stays in the device's own password manager until deleted there too. **Built 2026-09-20**: web `/me/passkeys` + `/api/member/passkeys` (GET, DELETE) linked from the member bar; app section on Settings. Needs an API deploy — `listPasskeys` and `deletePasskey` are new entries on `PublicWebAdminApi`'s allowlist. **⚠ Known gap:** not device-tested, and there is still no way to see or revoke a *device* (as opposed to its passkey) — an admin removing the row remains the only path, as E9.F7.S2 noted. | `Building` |
| `E9.F7.S19` | As a **hasher who has lost a phone**, I want to sign that device out of my account, so that removing its passkey is not the only thing I can do while it stays logged in for a year (James, 2026-09-20). **Today there is no revocation at all:** `ValidateAppAuth` resolves the caller with `WHERE d.id = @deviceId` and no `removed` filter, so flipping `removed` revokes nothing — E9.F7.S2's note that "revocation = an admin removes the device row" is not true for a soft remove. It reads `DeviceSecret` from that row to check the token, so **rotating the secret is the revocation**: immediate, per-device, and the phone cannot re-derive it. Sign out therefore (a) rotates `DeviceSecret` with `CRYPT_GEN_RANDOM` exactly as `hcapp_authorizeDevice` mints it, (b) **clears `FcmToken` / `ApnsToken`** — the push queries filter on the token and not on `removed`, so a lost phone keeps buzzing otherwise — and (c) sets `removed = 1`. **Do NOT add `AND removed = 0` to ValidateAppAuth:** 300 devices already carry `removed = 1` and 46 of them signed in within 90 days, so that filter would sign 13 active people out in a week; `removed` has never meant revoked and this story does not make it mean that for auth, only for the list. The list shows **everything**, no last-N-days rule (James), and a row leaves it only once the device is both signed out and passkey-free — `WHERE removed = 0 OR PasskeyCredentialId IS NOT NULL` — so a signed-out device with a passkey stays visible until that passkey is removed, and then disappears. `hcapp_listDevices` (sp 121) and `hcapp_signOutDevice` (sp 122), with `publicWeb_` wrappers per the wrap-for-writes rule. `hcapp_listPasskeys` (119) stays deployed and working because builds 1390/1391 already call it. **What a cut-off device sees is handled here too** (James, 2026-09-20: "a simple dialog... then show the generic run information as if someone had just downloaded the app... wipe the existing shared preferences and secure keychain"). A rotated secret would otherwise be refused as `errorType 1`, **the same error a phone with a drifting clock produces** — and wiping an install for a clock slip would be a catastrophe dressed as a security feature. So sign-out stamps a new `HC.Device.SignedOutAt` column (run-once ALTER; the table has no triggers and is not synced, so no trigger dance) and `ValidateAppAuth` refuses it BEFORE the token check with its own `errorType 7`. `ServiceCommon.sendHttpPost` routes that one type — and only that one — to `SignedOutHandler`: one dialog however many calls fail together, then `AppBootService.resetAndReboot(keepResetCode: false)`, which is the Log Out button's own path (GetStorage + keychain + local DB wiped, boot lands on guest discovery). `removed` could NOT carry this meaning: 300 devices have it and 46 signed in within 90 days. Wanted for the next public release. | `Next` |
| `E9.F7.S20` | As a **hasher**, I want reinstalling the app to reuse the device I already have rather than stranding the old one, so that my device list stays a list of my devices instead of a history of my installs (James, 2026-09-20, looking at 20+ rows of his own). **The cause:** `hcapp_authorizeDevice` mints a new `HC.Device` row whenever the app has no deviceId, and the deviceId lives in app storage that a reinstall wipes — so every reinstall strands a row, secret and all, which stays valid for ever because nothing expires it. James has duplicates within the SAME build (three on 1378, two on 1383), so it is per install event, not per version. **Measured 2026-09-20 — and it is NOT a platform-wide problem:** of 1,192 hashers with a mobile device, 793 (67%) have exactly one row, 391 have 2–4, only **5** have 5–9 and **3** have 10+ (biggest: 56). A bulk "sign out old installs" button was designed and **rejected on those numbers** (James: "we don't need the button at all since the universe of users affected is so small") — the fix belongs at the source, not in a broom. **The approach to weigh:** iOS `identifierForVendor` survives a plain reinstall (it resets only when every app from the vendor is removed) and Android's `ANDROID_ID` is stable per signing key and user, so `authorizeDevice` could match an existing row instead of minting one. **This needs care before it is built:** it touches the one SP every other call depends on, a matched row means handing an old secret to a new install (so it must re-mint the secret, not reuse it), the identifier is absent on some platforms and must fall back to today's behaviour, and two people sharing a phone must not collide. The existing stale rows are a separate question — they are live credentials, and E9.F7.S19's per-device sign-out is how a hasher clears them by hand today. Scheduled for the **3.2** train. | `Next` |
| `E9.F7.S21` | As a **Hasher** using web chat, I want the same hasher search and the same once-only findability question as the app, so that the web is not a second-class way to reach people (James, 2026-10-02; deferred from `E9.F1.S26`, which the server search already serves — the web needs the screens, the dialog for web-only members, and a `publicWeb_` wrapper for the write). | `Backlog` |

### E9.F2 · Push notifications  
`App` `API`

| ID | Story | Status |
|---|---|---|
| `E9.F2.S1` | As a **Hasher**, I want a push when somebody messages a run I am attending so that I do not have to keep opening the app. | `Shipped` |
| `E9.F2.S2` | As a **Hasher**, I want a push when the RA selects a song so that I can find the words in the circle. | `Shipped` |
| `E9.F2.S3` | As a **Hasher**, I want a reminder before a run I said I would attend so that I do not forget. | `Shipped` |
| `E9.F2.S4` | As a **Platform Admin**, I want silent sync pushes budgeted against the platform's throttle so that iOS does not quietly stop delivering them. | `Shipped` |
| `E9.F2.S5` | As a **Hasher**, I want a chat push only when I asked for one, and only once per device, so that a single message does not arrive forty-three times (James, 2026-09-17: "they are going to way too many people"). The visible-push gate becomes the one `nonApi_checkReminders` always used, `IN (1, 3, 4)`: preference 0 means never touched and is not consent. One push per device, not per device row — `DISTINCT` token, retired rows skipped, nothing to a device idle 180 days. `hcapp_setFcmTokens` retires a device's older rows, scoped to the same physical device (identical token string, or the same hasher's Apple rows sharing `identifierForVendor`); Android and browsers are never matched, so a second phone cannot be silenced. **Live 2026-09-17.** **⚠ Known gap:** the portal mints a fresh web-push token per session, so portal admins still accumulate rows; the app still sends releasability 63. | `Shipped` |
| `E9.F2.S6` | As a **Hasher**, I want the number of unread chat messages on the app icon — even while the app is closed — so that I know a conversation is waiting without opening the app. One definition of unread (`HC6.UserUnreadChatThreads`, moved out of `hcapp_getEventBadgeCount` Mode 3 and verified row-for-row); every chat push carries the recipient's total (`HC6.UserUnreadChatTotal`) in `aps.badge` / `notification_count` / `data.BadgeTotal`, read-sync lowers it on the other devices, and the app sets the icon on every badge refresh (`app_badge_plus`). Server live 2026-09-28 (SP build 10, API 1.0.61+62); app 3.1.8+1418 on TestFlight and Play internal. **⚠ Known gap:** not in the store releases yet; not device-tested; Android shows a number only on launchers that support one (Samsung and others; Pixel shows a dot), and a SILENT push to a closed Android app carries no number (no background handler). | `Building` |

### E9.F3 · Newsflashes  
`Portal` `App` `DB`

| ID | Story | Status |
|---|---|---|
| `E9.F3.S1` | As a **Platform Admin**, I want to publish a newsflash to a targeted audience so that I can reach hashers without shipping a release. | `Shipped` |
| `E9.F3.S2` | As a **Platform Admin**, I want to see who has read a newsflash and how they responded so that I know whether the message landed. | `Shipped` |
| `E9.F3.S3` | As a **Hasher**, I want to respond to a newsflash so that a question to the club is not one-way. | `Shipped` |

### E9.F4 · Teaching sequences  
`App` `DB`

> Two independent mechanisms. `HC.SplashSequence` is data-driven with scheduling, typing and kennel/event scoping — this is the one to build on. The version deck is convention-based (`version_<minor>_<n>` blobs) and fires only on an upgrade.

| ID | Story | Status |
|---|---|---|
| `E9.F4.S1` | As a **Platform Admin**, I want to schedule an image sequence with a valid-from and valid-until so that a lesson appears and retires on its own. | `Shipped` |
| `E9.F4.S2` | As a **Platform Admin**, I want to retire a sequence with a flag rather than by deleting its images so that retiring one is reversible. | `Shipped` |
| `E9.F4.S3` | As a **Hasher** upgrading, I want to be shown what is new so that a release does not arrive unexplained. | `Shipped` |
| `E9.F4.S4` | As a **Hasher** on my very first run of the app, I want not to be shown an upgrade announcement so that my first screen is not about a version I never had. | `Shipped` |
| `E9.F4.S5` | As a **Platform Admin**, I want an agent to author and schedule teaching sequences so that new features are explained without a release or hand-built artwork. | `Next` |
| `E9.F4.S6` | As a **Platform Admin**, I want a sequence targetable by kennel, event or cohort so that a lesson reaches the people it is relevant to. | `Next` |

### E9.F5 · Help & support  
`App`

| ID | Story | Status |
|---|---|---|
| `E9.F5.S1` | As a **Hasher**, I want an FAQ and video tutorials in the app so that I can answer my own question at the trail head. | `Shipped` |
| `E9.F5.S2` | As a **Hasher**, I want a support contact that carries my diagnostic context so that I do not have to describe my setup. | `Shipped` |
| `E9.F5.S3` | As a **Hasher**, I want in-app help I would actually open, because the current FAQ and tutorial pages are barely used. | `Backlog` |

---

## E10 — Stats, Leaderboards & Reporting

Hashers care enormously about their run count. Getting it wrong is the most visible failure the platform has, because everybody knows their own number.

### E10.F1 · Run counts  
`App` `DB`

| ID | Story | Status |
|---|---|---|
| `E10.F1.S1` | As a **Hasher**, I want my total runs per kennel and overall so that I know where I stand. | `Shipped` |
| `E10.F1.S2` | As a **Hasher**, I want my rolling twelve-month count to actually cover twelve months so that recent runs are not silently dropped. | `Shipped` |
| `E10.F1.S3` | As a **Hasher**, I want a count that has fallen to zero to be corrected to zero so that a stale high number is not left standing. | `Shipped` |
| `E10.F1.S4` | As a **Platform Admin**, I want to recompute counts for one user or everybody so that a data fix has an obvious remedy. | `Shipped` |
| `E10.F1.S5` | As a **Hasher**, I want a third Run Counts view, **By Hasher**, listing everyone I have run with, most runs together first and searchable, so that I can see who my hashing life has been spent with and reach them (James, 2026-10-02; for James the top row is Tuna Melt, 493 runs). **Decided with James, 2026-10-02:** run together = both attended the same run (`AttendenceState >= 20`, not RSVP). One server call returns the whole list — display name (each hasher's own display choice), photo, runs together, last run together — and the search filters it on the phone; for James 759 hashers in 63 ms. The list is the hasher's **own history, so a hasher who chose 'nobody' in E9.F1.S26 still appears** (each run's attendee list already shows them); the Message button follows their direct-message setting as everywhere. Tapping a row opens the **hasher page**: photo, display name, home kennel, a summary (runs together · first · last · hared together), a Message button, then the shared runs newest first, each marked when either of them hared. The page asks the server only for the shared run ids and draws the runs from the phone's own database (every run a hasher attended is already synced). **It is the same page as E9.F1.S26's profile card**, built once. The phone keeps the last list for offline. The segmented control takes a third option and wraps at large text. **Ships together with E9.F1.S26** (James). **Built 2026-10-02 on dev, not deployed:** `hcapp_getCoRunners`, `hcapp_getRunsTogether`; Run Counts' third tab, `HasherPage` (shared with search). One deviation from the design: the hasher page's runs come from the server with what each row needs (name, number, date, kennel, who hared), not by id from the phone, so very old runs that have aged out of the phone still show. ⚠ Known gap: not device-tested. | `Building` |

### E10.F2 · Leaderboards  
`App` `Web`

| ID | Story | Status |
|---|---|---|
| `E10.F2.S1` | As a **Hasher**, I want a global leaderboard so that I can see how the wider hash is doing. | `Shipped` |
| `E10.F2.S2` | As a **Hasher**, I want a kennel leaderboard so that the competition is with people I actually run with. | `Shipped` |
| `E10.F2.S3` | As a **Hasher**, I want leaderboards over a chosen period so that a newcomer is not permanently behind a thirty-year veteran. | `Shipped` |

### E10.F3 · Kennel statistics  
`App` `Web` `DB`

| ID | Story | Status |
|---|---|---|
| `E10.F3.S1` | As a **Grand Master**, I want attendance trends over time so that I can see whether the club is growing. | `Shipped` |
| `E10.F3.S2` | As a **Visitor**, I want a kennel's public stats page so that I can judge how active a club is before turning up. | `Shipped` |
| `E10.F3.S3` | As a **Grand Master**, I want a run statistics summary emailed after each run so that the committee sees it without opening anything. | `Shipped` |

### E10.F4 · Platform usage  
`Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E10.F4.S1` | As a **Platform Admin**, I want to see which kennels are active and which have gone quiet so that I know where to help. | `Shipped` |
| `E10.F4.S2` | As a **Platform Admin**, I want login history per user so that I can diagnose a support case. | `Shipped` |
| `E10.F4.S3` | As a **Platform Admin**, I want feature-level adoption figures so that I can tell whether a shipped feature is used. | `Backlog` |
| `E10.F4.S4` | As a **Platform Admin**, I want cost attributed per kennel so that I know what the platform costs to run at scale. | `Backlog` |
| `E10.F4.S5` | As a **Platform Admin**, I want the usage dashboard to count app-side errors beside server-side errors so that a green Error row cannot hide a crashing release. | `Shipped` |
| `E10.F4.S6` | As a **Platform Admin**, I want every server and client error record to name the app build that produced it so that I can see which release an error belongs to and confirm it is gone. | `Shipped` |

**⚠ Known gap:** client session rows written by apps before 3.0.13 (TestFlight and Play internal 2026-09-09, not yet in the stores) carry the device's *current* build, which can be one release too new. Server-side records are exact from 2026-09-09.
| `E10.F4.S7` | As a **Platform Admin**, I want a device health view when I open a user from the dashboard so that I can see that user's memory, CPU, network, GPS and battery per session without reading raw logs. | `Shipped` |

---

## E11 — Public Web Presence

A full website for every registered kennel from one deployment. Most hashers meet Harrier Central here first, through a search result rather than an app store.

### E11.F1 · Multi-tenant hosting  
`Web` `DB`

| ID | Story | Status |
|---|---|---|
| `E11.F1.S1` | As a **Kennel HC Admin**, I want our site at `hashruns.org/<slug>` so that we have a web presence without buying a domain. | `Shipped` |
| `E11.F1.S2` | As a **Kennel HC Admin**, I want to point our own domain at it so that the club keeps its established address. | `Shipped` |
| `E11.F1.S3` | As a **Kennel HC Admin**, I want every page scoped to our kennel so that no other club's data can ever appear on our site. | `Shipped` |
| `E11.F1.S4` | As a **Visitor** following an old hash-based link, I want to land on the right modern page so that years of shared links keep working. | `Shipped` |

### E11.F2 · Public content  
`Web`

| ID | Story | Status |
|---|---|---|
| `E11.F2.S1` | As a **Visitor**, I want a landing page with the next run and the club's identity so that I can tell in five seconds whether this is for me. | `Shipped` |
| `E11.F2.S2` | As a **Visitor**, I want upcoming and past run listings with full detail so that I can plan or catch up. | `Shipped` |
| `E11.F2.S3` | As a **Visitor**, I want an about page explaining the club and hashing so that a newcomer is not baffled. | `Shipped` |
| `E11.F2.S4` | As a **Visitor**, I want the songbook and stats pages so that the site reflects the club, not just its calendar. | `Shipped` |
| `E11.F2.S5` | As a **Visitor**, I want an events page for away weekends and specials so that non-run activity has a home. **⚠ Known gap:** currently a placeholder block | `Next` |
| `E11.F2.S6` | As a **Visitor**, I want to read the notes hashers chose to share on a run's web page so that a trail comes with the pack's own words. Data is ready (E3.F4.S5: `HasherEventMap.Notes` where `NotesVisibility = 1` and neither override bit is set); needs a `publicWeb_getRunNotes` SP and a block on the run page. | `Next` |

### E11.F3 · Page builder  
`Web` `Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E11.F3.S1` | As a **Kennel HC Admin**, I want to rearrange the blocks on any top-level page so that our site says what we want it to. | `Shipped` |
| `E11.F3.S2` | As a **Kennel HC Admin**, I want my layout saved per kennel and applied immediately so that an edit is visible on the next load. | `Shipped` |
| `E11.F3.S3` | As a **Kennel HC Admin**, I want image, rich text and social-link blocks so that I can build a page that is more than run data. | `Next` |

### E11.F4 · Theming  
`Web` `Portal`

| ID | Story | Status |
|---|---|---|
| `E11.F4.S1` | As a **Kennel HC Admin**, I want our colours, logo and light or dark mode applied across the site so that it looks like our club. | `Shipped` |
| `E11.F4.S2` | As a **Kennel HC Admin**, I want a visual theme editor so that changing our colours does not require a developer. | `Next` |
| `E11.F4.S3` | As a **Visitor**, I want text to stay readable whatever colour the club picked so that brand never beats legibility. | `Shipped` |

### E11.F5 · Discovery & SEO  
`Web`

| ID | Story | Status |
|---|---|---|
| `E11.F5.S1` | As a **Visitor**, I want to find a kennel by searching for my town so that Google is a viable front door. | `Shipped` |
| `E11.F5.S2` | As a **Visitor**, I want a global calendar of runs across every kennel so that I can find a hash anywhere. | `Shipped` |
| `E11.F5.S3` | As a **Kennel HC Admin**, I want per-kennel sitemaps, metadata and canonical URLs so that our pages rank for our club. | `Shipped` |
| `E11.F5.S4` | As a **Visitor**, I want fully rendered HTML so that a crawler and a slow phone both get the content. | `Shipped` |

### E11.F6 · Member-only web content  
`Web`

| ID | Story | Status |
|---|---|---|
| `E11.F6.S1` | As a **Hasher**, I want to log into my kennel's website so that I can see member content on a laptop. **⚠ Known gap:** member web auth is not yet designed; only admin OTP auth exists | `Backlog` |
| `E11.F6.S2` | As a **Hasher**, I want the member roster and mismanagement contacts behind that login so that they are not public. | `Backlog` |

---

## E12 — Platform Administration

The things only Opee and Tuna Melt can do — onboarding kennels, holding the permission model, and watching the platform. Gated by `HC.PlatformAdmin`, which is a different mechanism from every kennel-scoped permission.

### E12.F1 · Kennel onboarding  
`Portal` `API` `DB`

| ID | Story | Status |
|---|---|---|
| `E12.F1.S1` | As a **Visitor** starting a kennel, I want to apply to join the platform so that there is a front door. | `Shipped` |
| `E12.F1.S2` | As a **Platform Admin** with `CanEditKennel`, I want to review and approve applications so that the directory stays real. | `Shipped` |
| `E12.F1.S3` | As a **Platform Admin**, I want to set a new kennel's identity, geography and search tags so that it is findable from day one. | `Shipped` |
| `E12.F1.S4` | As a **Platform Admin**, I want to name a kennel's first admin so that the club can run itself immediately. | `Shipped` |
| `E12.F1.S5` | As a **Platform Admin** with `CanEditKennel`, I want kennel requests in the portal — list by status, edit, approve, reject as spam or duplicate — so that approval no longer depends on the deprecated HC3W web app. Keeps `EXT.OfficeForms_KennelImport` (no new table) with review columns added; `hcportal_getKennelRequests` / `updateKennelRequest` / `rejectKennelRequest`. Plan: `docs/kennel_requests_plan.md`. Shipped 2026-09-28 (portal 2.0.87+725, SP build 7): HC Admin Tools › Kennel requests (status chips, bulk spam/reject, detail page with location pickers). **⚠ Known gap:** a city missing from `HC.City` cannot be added from the portal; the reviewer picks the nearest one. | `Shipped` |
| `E12.F1.S6` | As a **Platform Admin**, I want approving a request to create everything the club needs to start — the kennel with a unique short name and a real logo, the requester as its admin (account created if they have none), platform admins as helpers, and a sign-in code emailed — so that a new kennel runs the same day. `hcportal_approveKennelRequest` replaces `HC3W.importKennel`, which set `bundle://C-NNN` logos (62 of today's 63), created `dbo.Users` logins with a fixed password hash and hard-coded Tuna Melt's id. Shipped 2026-09-28 (API 1.0.61+61); the welcome email is a `PortalApiHC6` side effect that strips the code from the reply. | `Shipped` |
| `E12.F1.S7` | As a **Visitor** starting a kennel, I want to register it at hashruns.org/add-kennel, choosing my country, region and city from the list, so that the request arrives clean. `publicWeb_submitKennelRequest` replaces `EXT.ImportNewKennel` (one `NVARCHAR(4000)` for the whole form — silent truncation) and the anonymous GET endpoint `ProcessWpForm`. Shipped 2026-09-28 (web 0.21.74 redeploy) with `publicWeb_getGeography` for the pickers; the global footer links to it. Since 2026-09-28 (SP build 11) it asks the old site's three required opt-in questions and keeps the answers (`TermsAnswers`) for the reviewer. | `Shipped` |
| `E12.F1.S8` | As a **Platform Admin**, I want a request to reach the queue only after the submitter confirms an emailed code, so that bots never do. Honeypot, time-to-submit and per-IP rate limit before any email is sent; `publicWeb_confirmKennelRequest`. Shipped 2026-09-28: signed time-to-submit stamp, honeypot, 5/IP/hour (route) and 5/IP/day (SP); 5 wrong codes ⇒ spam; confirming emails the reviewers. **⚠ Known gap:** 11 of the pending requests since 2026-08 are spam through the old endpoint and still wait in the queue to be marked. | `Shipped` |
| `E12.F1.S9` | As a **Platform Admin**, I want the old intake retired — harriercentral.com's add-kennel page pointing at hashruns.org, `ProcessWpForm` removed, the EXT/HC3W objects archived — and the 63 `bundle://C-NNN` kennel logos replaced with stored images, so that nothing creates or shows a broken kennel. Shipped 2026-09-28: the logos (63 kennels → `generic-logos/C-NNN.png`; the app and portal draw a coin URL with the kennel's short name on it, as they did for `bundle://` — portal 2.0.87+728 live, app from 1419); harriercentral.com is now in the repo (`harriercentral-com/`) and its three old sign-up pages 301 to hashruns.org/add-kennel; `ProcessWpForm` is removed (API 1.0.61+61). **⚠ Known gap:** `EXT.ImportNewKennel`, `EXT.ProcessKennelImports`, `EXT.vwOfficeForms_KennelImport` + trigger and `HC3W.importKennel` are still in the database, unused — dropping them is a separate decision. The public web still shows a coin without the name. | `Shipped` |

### E12.F2 · Portal access  
`Portal` `App`

| ID | Story | Status |
|---|---|---|
| `E12.F2.S1` | As a **Kennel HC Admin**, I want to authorise the web portal from my phone so that the portal needs no password of its own. | `Shipped` |
| `E12.F2.S2` | As a **Kennel HC Admin** on one machine, I want same-device login via a short-lived code so that I can use the portal without a second phone in hand. | `Shipped` |
| `E12.F2.S3` | As a **Kennel HC Admin**, I want a one-time token to open the public web admin so that content editing needs no separate account. | `Shipped` |

### E12.F3 · Permission administration  
`Portal` `DB`

| ID | Story | Status |
|---|---|---|
| `E12.F3.S1` | As a **Platform Admin** with `CanManagePermissions`, I want to edit which grantors allow which functions so that the model is data, not code. | `Shipped` |
| `E12.F3.S2` | As a **Platform Admin**, I want per-kennel overrides visible against the global default so that I can see where a club diverges. | `Shipped` |
| `E12.F3.S3` | As a **Platform Admin**, I want the compiled matrix regenerated after an edit so that the authorizer never reads a stale rule. | `Shipped` |

### E12.F4 · Kennel administration in the portal  
`Portal`

| ID | Story | Status |
|---|---|---|
| `E12.F4.S1` | As a **Kennel HC Admin**, I want to manage runs, members, photos and website content from a desktop so that bulk work is not done on a phone. | `Shipped` |
| `E12.F4.S2` | As a **Hash Cash**, I want a printable check-in sheet so that a run with no signal still has a fallback. | `Shipped` |
| `E12.F4.S3` | As a **Kennel HC Admin**, I want to email our members from the portal so that club communication does not need a separate mailing list. | `Shipped` |

### E12.F5 · Integrations  
`API` `Portal`

| ID | Story | Status |
|---|---|---|
| `E12.F5.S1` | As a **Kennel HC Admin**, I want an external API key so that our own site or tooling can read our run data. | `Shipped` |
| `E12.F5.S2` | As a **Kennel HC Admin**, I want to regenerate that key so that a leak has a remedy. | `Shipped` |
| `E12.F5.S3` | As a **Kennel HC Admin**, I want a form on our old WordPress site to create a hasher here so that migration is gradual. | `Shipped` |


### E12.F6 · Account administration  
`DB` `Portal`

| ID | Story | Status |
|---|---|---|
| `E12.F6.S1` | As a **Platform Admin** with `CanEditKennel`, I want to enter the email (or hasher id) of the account to keep and of the duplicate, and see both side by side — runs, payments, credit, kennels, devices, chat, photos — with where they overlap (runs on both, kennels on both, runs both paid for), so that I know what a merge will do before it happens. `hcportal_previewHasherMerge`; HC Admin Tools › Merge accounts. Shipped 2026-09-28 (portal 2.0.87+727, SP build 9). | `Shipped` |
| `E12.F6.S2` | As a **Platform Admin**, I want the merge to move every run and payment row to the kept account — combining the rows where both had one, never deleting money — along with memberships, chat, photos and the rest, recalculate run counts and credit, and disable the duplicate (signed out everywhere, as a GDPR delete does), so that one person has one history. `hcportal_mergeHashers` replaces `HC3.utilApi_mergeUsers`, which deleted the duplicate's payment where both had paid and every past run either had not attended. Shipped 2026-09-28 (SP build 9), tested in a rolled-back transaction. **⚠ Known gap:** PackTrack points not yet archived (the nightly job) stay under the old id in Table Storage. | `Shipped` |
| `E12.F6.S3` | As a **Platform Admin**, I want to find the accounts to merge by hash name — several names at once, comma-separated — see them in a table (email, kennels followed, last app use, runs, where the last three runs were), mark one Keep and one or more Merge, and merge them all into the Keep, so that I don't need anyone's email and can merge more than two accounts. `hcportal_searchHashersForMerge`; the merge itself reuses `hcportal_previewHasherMerge` / `hcportal_mergeHashers` by id, one account at a time. Shipped 2026-09-28 (portal 2.0.87+729). **⚠ Known gap:** the page has not yet been used on a real merge. | `Shipped` |

### E12.F7 · Platform staff  
`DB` `Portal`

| ID | Story | Status |
|---|---|---|
| `E12.F7.S1` | As a **Platform Admin** with `CanManagePermissions`, I want an HC Admin Tools page that lists the platform admins with their four capabilities as switches, removes one, and mints a new one by finding the person the way Merge accounts does, so that Harrier Central staff are managed in the portal rather than seeded by hand in SQL (James, 2026-09-30). `hcportal_getPlatformAdmins` / `hcportal_setPlatformAdmin` — the one write path for `HC.PlatformAdmin`, upsert on `UserId` (a removed admin is revived, not duplicated), NULL flag = keep. Guards: a caller cannot de-mint themselves or drop their own Permissions & admins; the change cannot leave nobody holding it; every change goes to `LOG.GeneralLog` with before/after flags. A new admin starts with Monitor, Newsflash and Kennels & merges; Permissions & admins is switched on deliberately. **`HC.PlatformAdmin` is the only platform-wide grant** — `AppAccessFlags 0x40000000` is the kennel-founder bit (E9.F1.S20). **Shipped 2026-09-30** (portal 2.0.87+737, SP build 21). ⚠ Known gap: not yet used for a real mint; the search reuses `hcportal_searchHashersForMerge`, which needs `CanEditKennel` as well. | `Shipped` |
---

## E13 · non-functional — Security, Privacy & Data Protection

Constraints rather than stories, so each is stated as a requirement with the mechanism that enforces it. An unenforced requirement is a wish.

### E13.G1 · Authentication & authorisation

| ID | Requirement | Enforced by |
|---|---|---|
| `E13.G1.R1` | No password exists anywhere in the platform; identity is a device-bound shared secret. | `hcapp_authorizeDevice` mints a 75-char secret and a per-device 30–44s window. |
| `E13.G1.R6` | A device secret never leaves the device it was minted for. | **⚠ Not currently enforced on Android:** `allowBackup` defaults to true and `deviceSecret` sits in plain `SharedPreferences`, so a Google backup can restore a working credential onto another device. iOS needs the same review for `NSUserDefaults` and keychain accessibility. See `E1.F1.S6` (3.2). |
| `E13.G1.R2` | Every access token expires within roughly one time window and is not reusable outside it. | `CHECK_ACCESS_TOKEN_V2` accepting offsets −2…+2 only. |
| `E13.G1.R3` | Operations touching money or another user bind the token to that specific operation. | Compound `paramString` of device secret plus target. |
| `E13.G1.R4` | Authorisation is always kennel-scoped; an admin of one kennel has no rights in another. | `CheckKennelPermission` reading grantors from that kennel's `HasherKennelMap` row. |
| `E13.G1.R5` | Frontends never touch the database directly and never build SQL. | The shim routing only to named stored procedures; no dynamic SQL anywhere. |

### E13.G2 · Data exposure

| ID | Requirement | Enforced by |
|---|---|---|
| `E13.G2.R1` | Unauthenticated endpoints never return GPS coordinates for a person or a photo. | `publicWeb_getRunPhotos` omitting latitude and longitude by construction. |
| `E13.G2.R2` | Internal error detail never reaches a client; only a safe envelope and an error id do. | The shim stripping `debugMessage` and `errorProc` before responding. |
| `E13.G2.R3` | Blob access requires a scoped, time-limited SAS URL rather than a guessable path. | The upload-token endpoints; track labels store a photo id, never a URL. |
| `E13.G2.R4` | A kennel's private data is never reachable from another kennel's public site. | Tenant resolution scoping every query to the resolved slug. |

### E13.G3 · Privacy rights

| ID | Requirement | Enforced by |
|---|---|---|
| `E13.G3.R1` | A hasher can have their personal data erased on request. | `hcapp_gdprDelete` and the in-app deletion route. |
| `E13.G3.R2` | Location is captured only while a hasher has explicitly started tracking. | The tracking toggle gating background updates; idle mode is coarse and low-rate. |
| `E13.G3.R3` | Logging out leaves no recoverable trace of the previous user on the device. | Keychain reset code plus the app-restart path, with a wipe guard. |

### E13.G4 · Data retention

| ID | Requirement | Enforced by |
|---|---|---|
| `E13.G4.R1` | Operational logs are retained 90 days and no longer. | A nightly prune deleting by clustered key rather than by filter column. |
| `E13.G4.R2` | Deleting a photo is reversible for review purposes before it becomes permanent. | `DeletedAt` soft deletion on `HC.KennelPhotos`. |

---

## E14 · non-functional — Reliability, Sync & Observability

The app is used in fields with no signal by people who will not try twice. Everything here exists because something failed silently once.

### E14.G1 · Offline & sync

| ID | Requirement | Enforced by |
|---|---|---|
| `E14.G1.R1` | Three isolated local domains — common, kennel, event — with a table's domain fixed by its prefix. | `EnumDataTables` declaring domain membership; a wrong-domain query returns empty, never an error. |
| `E14.G1.R2` | Common tables accumulate deltas indefinitely and are never wiped outside a full boot resync. | The sync lifecycle; kennel and event domains are single-tenant and wiped on switch. |
| `E14.G1.R3` | Overlapping syncs cannot double-insert the same row. | An async serialiser around sync entry points. |
| `E14.G1.R4` | Paged replication is deterministic under concurrent writes. | The `updatedAtBias` tiebreaker on synced tables. |
| `E14.G1.R5` | Every locally cached row is uniquely keyed on the server primary key, so a resync running concurrently with another sync, or with a write procedure that returns the same rows, cannot insert a duplicate. | **3.2 track.** Planned — a UNIQUE constraint on the remote id in every local table, plus a `DB_VERSION` bump of 10 so the reload recreates the tables and clears every device's existing duplicates; the sync writers must switch to insert-or-replace first. The 2026-08-16 async serialiser closed the sync-vs-sync path only; write procedures still return sync rowsets outside it. |
| `E14.G1.R6` | Work done offline is queued and completed later, never silently discarded. | The payment outbox, the photo upload queue and the GPS point buffer. |

### E14.G2 · Error handling

| ID | Requirement | Enforced by |
|---|---|---|
| `E14.G2.R1` | Every stored procedure body is wrapped in TRY/CATCH, reads included. | Review; an unwrapped proc turns any runtime error into an unlogged raw 500. |
| `E14.G2.R2` | Every CATCH writes to `HC.ErrorLog` before returning or rethrowing. | The HC6 standard and the code-smell checklist. |
| `E14.G2.R3` | A rollback never erases the error log row written for that same failure. | Ordering: `ROLLBACK` first, then the insert. Eight sites were corrected 2026-09-06. |
| `E14.G2.R4` | A client-visible error explains the cause and the remedy in the user's terms. | The standard error envelope carrying a user message separate from debug detail. |

### E14.G3 · Diagnostics

| ID | Requirement | Enforced by |
|---|---|---|
| `E14.G3.R1` | A crash or hang on a real device is diagnosable without reproducing it. | Enforced by MetricKit payloads, boot breadcrumbs and memory samples uploaded to `HC.ClientErrorLog`. |
| `E14.G3.R2` | Verbose device logging is opt-in per cohort, not on for everybody. | A preferences bit plus a named beta cohort. |
| `E14.G3.R3` | Log wording states what actually happened — retained data is never reported as lost. | Review after a buffer log implied 16,798 points were dropped when they were retained. |
| `E14.G3.R4` | An error record names the build that produced it, not the build that reported it. | `HC.ErrorLog.HcVersion` is stamped from the calling device via `HC6.DeviceHcVersion`; `HC.ClientErrorLog` stores the version the app recorded when the session started, because the log is uploaded one boot later, possibly after an upgrade. |
| `E14.G3.R5` | Every harvested session log carries the device's memory, network and battery figures over time, so a resource problem is measurable per device without a repro. | `[METRICS]` lines from `DeviceMetricsService`: start, every background/foreground edge, every 15 min; process CPU time and share, RSS/PSS/headroom, app-layer bytes and latency plus (Android) process-level bytes, location-stream minutes per cost tier, database/documents/cache footprint and free disk, battery level and unplugged drain, Low Power Mode and thermal state. Plus a one-row-a-minute ring of the last two hours and a timestamped-peaks record, persisted separately and appended to the next upload, bounded at ~8 KB so they never displace breadcrumbs. Native snapshot channel on both platforms. **Building** — iOS gives no per-app network or battery attribution; the line records the device's condition beside the app's own footprint instead. |
| `E14.G3.R6` | A new error is told apart from a known one without reading the logs, and a fixed error that comes back is flagged as a regression. | `tools/log_triage.py` reduces every `HC.ErrorLog` and `HC.ClientErrorLog` entry to a fingerprint (source, normalised message, first frame in our code without its line number) and checks it against `tools/known_errors.tsv` (`noise` / `open` / `fixed:<build, version or date>`). It prints only what is new, regressed, or a noise burst across five or more devices in an hour, and exits 1 when there is any. Seeded 2026-09-23 from 30 days: 100 fingerprints. Runs daily at 08:00 via launchd and iMessages only when there is something to see; an Azure Monitor alert (>40 5xx in 15 min) covers shim failures that never reach the log. |
| `E14.G3.R7` | What the platform costs to run is measured every day and shown beside its usage, so a rise is seen the day it happens and traced to the service or AI feature that caused it (James, 2026-10-05). | `LOG.AiUsage` (one row per AI model call: tokens, USD, outcome, session) and `LOG.AzureDailyCost` (Cost Management per day per service, read every 6 h by the API's `AzureDailyCost` via the Function App's managed identity with Cost Management Reader); the portal Usage Data grid's **AI Tokens** and **Azure Cost** rows, green when lower, drilling down to calls and to services. Live 2026-10-05 (API 1.0.61+75, portal 2.0.87+741, SP build 34); 60 days of cost backfilled. |

### E14.G4 · Performance

| ID | Requirement | Enforced by |
|---|---|---|
| `E14.G4.R1` | A returning user reaches usable content without waiting for a full sync. | Boot sync deferral; the cached list renders first. |
| `E14.G4.R2` | The app draws no meaningful battery when tracking is off. | Idle-mode location settings and removal of three standing costs, quantified from MetricKit. |
| `E14.G4.R3` | High-frequency reactive state does not rebuild a heavy widget subtree. | Scoping observers narrowly; marker sets are memoised on a change signature. |
| `E14.G4.R4` | A schema change on a synced table does not force every client into a full resync. | Disabling the `updatedAt` trigger around any `ALTER TABLE ADD COLUMN`. |

---

## E15 · non-functional — Delivery & Release Engineering

One developer, nights and weekends, shipping to two app stores and a live production database with no staging environment. The process has to make that safe rather than heroic.

### E15.G1 · Deployment safety

| ID | Requirement | Enforced by |
|---|---|---|
| `E15.G1.R1` | Nothing deploys to production without an explicit human instruction in that conversation. | The standing rule that no agent deploys autonomously. |
| `E15.G1.R2` | There is one production database, so every procedure deploy is live to every user. | Awareness plus `CREATE OR ALTER` and parse-checking before deploy. |
| `E15.G1.R3` | Stored procedures deploy before any client build that depends on them. | Release ordering; the shim forwards unknown parameters straight through and the call fails otherwise. |
| `E15.G1.R4` | Run-once scripts cannot be re-run by a later deploy. | Archiving them; the deploy globs are non-recursive. |

### E15.G2 · Change control

| ID | Requirement | Enforced by |
|---|---|---|
| `E15.G2.R1` | Every procedure has a contract, and a breaking change is deliberate and documented. | Versioned contract JSON with explicit breaking-change rules. |
| `E15.G2.R2` | Work lands on `dev`; `master` moves only at a release. | The branch workflow; the portal auto-deploys on a master push. |
| `E15.G2.R3` | Agents propose; the developer decides. No AI output is committed unreviewed. | The project's guiding principles. |

### E15.G3 · Store releases

| ID | Requirement | Enforced by |
|---|---|---|
| `E15.G3.R1` | A release build is never produced from a tree that has run against a simulator. | A clean before any release build; otherwise the upload is rejected. |
| `E15.G3.R2` | Every shipped component carries a version bump and a changelog entry. | The coordinated release procedure, per component. |
| `E15.G3.R3` | A version already live in a store closes its train; the next release takes a new name. | The version-naming rule. |
| `E15.G3.R4` | iOS and Android ship from the same commit. | The dual-store release flow. |

### E15.G4 · Verification

| ID | Requirement | Enforced by |
|---|---|---|
| `E15.G4.R1` | Algorithms mirrored across two codebases are changed together and pinned by tests. | The GPS filter test suite running against real recorded tracks. |
| `E15.G4.R2` | A tuning change must be demonstrably inert on good data before it ships. | Parameter sweeps asserting clean tracks are unchanged. |
| `E15.G4.R3` | Features that cannot be verified without a device are marked as shipped blind and tested after. | Device-test checklists carried in the component to-do files. |

---

## E16 — Platform Maintenance & Technical Debt

Work that keeps the platform shippable rather than adding to it. It earns a place in the
backlog because it competes for the same nights and weekends as everything above, and
because leaving it invisible is how a solo project ends up unable to build for Android.

### E16.F1 · Dependency currency  
`App` `Portal` `Web` `API`

> Upgrading is not optional — store SDK requirements and Firebase deprecations set the deadlines. But an upgrade that breaks the Android build costs more than the debt: Flutter 3.47.2 was rolled back to 3.41.9 on 2026-09-07 for exactly that reason.

| ID | Story | Status |
|---|---|---|
| `E16.F1.S1` | As a **Platform Admin**, I want the Flutter SDK current so that new store requirements do not arrive as an emergency. | `Building` |
| `E16.F1.S2` | As a **Platform Admin**, I want tier-2 dependency majors taken one at a time so that a failure is attributable to one package. | `Next` |
| `E16.F1.S3` | As a **Platform Admin**, I want `flutter_secure_storage` upgraded on its own so that a keychain change cannot be confused with any other break. | `Next` |
| `E16.F1.S4` | As a **Platform Admin**, I want Firebase moved from CocoaPods to Swift Package Manager before Google drops Pods support. | `Next` |
| `E16.F1.S5` | As a **Platform Admin**, I want an upgrade to be revertible in one step so that a broken toolchain never blocks a release. | `Shipped` |

### E16.F2 · Retiring the legacy  
`App` `Web` `DB`

| ID | Story | Status |
|---|---|---|
| `E16.F2.S1` | As a **Platform Admin**, I want the HC5 stored procedures retired once no shipped client calls them. **⚠ Known gap:** blocked until the 2.1.2 install base drains, roughly Dec 2026 – Mar 2027 | `Backlog` |
| `E16.F2.S2` | As a **Platform Admin**, I want the `get_storage` preferences migration removed once no client boots from it. | `Backlog` |
| `E16.F2.S3` | As a **Platform Admin**, I want historical `PHO::` points migrated out of the position store so that photos are not carried on somebody's track. | `Backlog` |
| `E16.F2.S4` | As a **Platform Admin**, I want the legacy hash-URL shim removed once no inbound links use it. | `Backlog` |

### E16.F3 · Data hygiene  
`DB`

| ID | Story | Status |
|---|---|---|
| `E16.F3.S1` | As a **Hasher**, I want profile photos that point at missing blobs cleaned up so that the roster does not show broken images. Every avatar now loads through `HasherAvatarImageProvider`, which shows the default avatar when a photo will not load; when storage answered 404/410 the phone reports the URL to `ReportBrokenPhoto`, the server HEAD-checks it itself (a bad connection and a hostile client both look the same to us otherwise) and only then swaps it for a bundled avatar via `nonApi_replaceBrokenPhoto`, which re-syncs to everyone. **⚠ Known gap:** client-triggered only — a broken photo nobody has looked at since this shipped stays broken; the one-off sweep over every stored URL is not built. Shipped 2026-09-10 in app 3.0.20 / API 1.0.41; not yet device-tested against a known-missing blob. | `Shipped` |
| `E16.F3.S2` | As a **Hash Cash**, I want historical zero-cash run payments rewritten as free so that free runs stop appearing as income. | `Next` |
| `E16.F3.S3` | As a **Platform Admin**, I want a periodic audit that every API-facing procedure still meets the HC6 standard so that drift is caught by a sweep rather than an outage. | `Next` |
| `E16.F3.S4` | As a **Platform Admin**, I want the public web to report its own failures where every other component reports, so that a web bug is visible in the same sweep rather than dying in a console nobody reads (2026-09-17). `publicWeb_logWebError` writes to `HC.ErrorLog` stamped `web <version>`; deliberately NOT behind ValidateAppAuth, since the most useful reports come from a visitor with no session — the guard is the internal secret on the shim. All 17 swallowed `console.error` calls in the member routes now report, and `app/global-error.tsx` and `app/me/error.tsx` post what the browser cannot survive to a rate-limited endpoint. The logger never throws and never blocks a response. **Live 2026-09-17** (web 0.21.64, API 1.0.56). | `Shipped` |
| `E16.F3.S5` | As a **Platform Admin**, I want the local-database migrations applied in version order so that an upgrade does not depend on the order somebody happened to paste them into the file (2026-09-19). `MigrationsModel.doDatabaseMigrations` walks `migrationList` in FILE order, skipping any whose `dbVersion` is at or below the installed one. It never sorts. The list in `database/tables.dart` currently reads **528, 532, 531, 530, 529**, so a phone upgrading from the App Store build (527) applies them in exactly that jumbled order. **It is harmless today and that is luck, not design:** every statement in those five is an independent `ALTER TABLE ... ADD COLUMN`, so nothing reads a column a later migration adds. The first migration that depends on an earlier one — a backfill `UPDATE`, an index over a new column, a `CREATE TABLE ... SELECT` — breaks silently, and breaks ONLY for people upgrading from an older build. Anyone already near the current version skips the whole list, so no beta tester can ever reproduce it. **Fix is one line** — sort the list by `dbVersion` in the runner, not in the file, so the ordering cannot be undone by the next person appending to `tables.dart`. Worth a test that asserts the list is strictly ascending. **⚠ Do NOT 'fix' this by bumping DB_VERSION by 10 to force a wipe-and-reload** (considered and rejected 2026-09-19): `_handleDbUpgrade` calls `clearPrefs()`, which destroys the payment outbox — `paymentOutboxJson` lives in prefs, nothing flushes it first — so any offline payment a Hash Cash has taken and not yet sent is lost, with no trace. It also needs connectivity at boot or the user lands on the guest page, it hits everyone below DB_VERSION-9 rather than only the old builds, and it halves the deliberate 20-version gap between the 3.1.x (532) and 3.2 (552) trains. | `Next` |

### E16.F5 · Naming the numbers  
`DB` `App` `Web`

Attendance and RSVP are stored as bare integers and compared against bare
integers in 125 places. The two enums do not overlap in meaning but DO overlap
in value, which is how `AttendenceState >= 3` — a threshold borrowed from the
RSVP enum, where 3 is Yes — ended up in four app SPs (2026-09-20).

| ID | Story | Status |
|---|---|---|
| `E16.F5.S1` | As a **Platform Admin**, I want attendance and RSVP states named rather than written as integers, so that a reader can tell which enum a number belongs to and a threshold cannot be borrowed from the wrong one (James, 2026-09-20). The values: attendance `0` nothing recorded · `10` NOT at the hash · `20` at the hash · `30` above at-hash, under the `< 40` bound; RSVP `1` No · `2` Maybe · `3` Yes. **They overlap in value and mean opposite things** — RSVP 3 is Yes, attendance 3 is meaningless, and attendance 10 is a *negative*. Count as of 2026-09-20: **83 SP sites** (attendance 51 app / 6 web / 2 portal; RSVP 20 / 3 / 1), **24 Dart**, **18 TypeScript**. The clients are half done already — Dart has `attendenceNo` / `attendenceAtHash` / `attendenceNoChange`, the web has `AT_HASH` / `RSVP_YES` / `RSVP_MAYBE` — so the bulk of the work, and all of the risk, is in SQL. **SQL has no enums, so the approach is an open decision, not a detail:** (a) `DECLARE @atHash SMALLINT = 20;` at the top of each SP — cheapest, names the value where it is read, still one copy per proc; (b) a view or inline TVF per *rule* (`HC6.AttendedEvents`), which removes the duplication but only for the rules that are shared; (c) a lookup table joined per query — **needs James's decision, since it is a new table**, and it puts a join in hot paths. A scalar UDF in a `WHERE` is explicitly rejected: it is a per-row call over `HC.HasherEventMap` (136,803 rows). **Scheduled for the 3.2 train**, not 3.1 — it touches nearly every app SP and must not ride an imminent store release. Do it after the `>= 3` fix lands, so the rename moves correct code rather than baking a bug into a new name. | `Next` |

### E16.F4 · Verification debt  
`App`

> 149 unverified checks across 20 features shipped without a device pass, carried in `docs/verification-backlog.md`. These are individual work items and belong in the issue tracker, not here — this feature exists so the debt is visible at the backlog level.

| ID | Story | Status |
|---|---|---|
| `E16.F4.S1` | As a **Platform Admin**, I want every feature shipped blind to get a device pass so that the install base is not the test suite. | `Building` |
| `E16.F4.S2` | As a **Platform Admin**, I want the verification backlog tracked as issues so that another developer can pick one up. | `Next` |
| `E16.F4.S3` | As a **Platform Admin**, I want the battery draw re-measured after each release so that a regression is caught by data rather than by a complaint. | `Next` |
| `E16.F4.S4` | As a **Platform Admin**, I want a working test harness in the portal so that a regression there can be pinned by a test rather than found by a kennel. **⚠ Known gap:** `flutter_test` is commented out of the portal's dev_dependencies and `widget_test.dart` has no `main` — the portal has no test coverage at all, and enabling it hits a `web` package incompatibility | `Next` |


### E16.F6 · Photos at their own shape  
`Web` `App` `Portal`

James, 2026-09-28: "I don't want any cropping... images should always display in their native aspect ratio. We need the UI to be able to handle different image sizes and orientations." The rule is in CLAUDE.md (trail photos, point 2): never `object-cover` / `BoxFit.cover` for a photo; a row of photos shares one height and each width follows its aspect ratio; a photo that does not fit drops out whole. NOT photos, and left alone: background textures (the jungle tile), profile photos (portrait circles), map tiles, kennel logos (their own contain rule). Count at capture: web 20 uses in 17 files, app 19 in 16, portal 16 in 13 — each to be judged, not blanket-replaced.

| ID | Story | Status |
|---|---|---|
| `E16.F6.S1` | As a **Hasher** on the website, I want every run and kennel photo shown whole, so that nobody at the edge of a shot is cut off. Run photo strip (square crops), photo-viewer thumbnails, run-card images, My Runs / Hash Runs run images (fixed-height crop), kennel cover and welcome images, the PackTrack photo pop-up, song and content-block images. Trail TV's strip done 2026-09-28 (web 0.21.74). | `Next` |
| `E16.F6.S2` | As a **Hasher** in the app, I want the same: 19 `BoxFit.cover` uses in 16 files — run photo gallery and tabs, map photo page and markers, photo sweep, Hash Flash approval, down-down and check-in pages, songs. | `Next` |
| `E16.F6.S3` | As a **Kennel HC Admin** in the portal, I want the same: 16 `BoxFit.cover` uses in 13 files — photo review, run detail panel, image dialog, song and application-form images. | `Next` |
| `E16.F6.S4` | As a **Platform Admin**, I want a scan that lists every crop of a photo (and skips the allowed backgrounds, avatars and tiles by a marked comment), so that a new one is caught before it ships — like `tools/button_text_scan.py`: it must print nothing. | `Next` |

---

## E17 — Speaking the hasher's language

`App` `Web` `Portal` `DB`

Everything Harrier Central says is in English, in every client. Raised 2026-09-20
(James: "how hard would it be to I18N the interface... for our Kennels in Taiwan,
Barbados, Germany"), measured the same day, and parked **after the 3.2 payments
train** — the measurements are here so the question does not have to be asked twice.

### E17.F1 · One interface, several languages

| ID | Story | Status |
|---|---|---|
| `E17.F1.S1` | As a **hasher whose phone is not in English**, I want Harrier Central in my own language, so that the app does not assume the hash is an English-speaking club. **Measured 2026-09-20 — start with the demand, because it is smaller than the country list suggests.** Active devices by locale over 180 days: `en_GB` 514, `en_US` 488, none recorded 453, **`en_BB` 48 — Barbados is already English**, `de_DE` 36, `en_CA` 31, `en_PT` 25, **`zh_Hant_TW` 21**, `en_AU` 19, `nl_NL` 16, `en_BE` 15, `en_DE` 14. So the genuinely non-English populations are ~36 German and ~21 Taiwanese devices, about 3% of the fleet, and half the "foreign" kennels are English-speaking. **Ask the Taiwanese kennel whether they want a translated UI before building one** — at 21 devices that conversation is cheaper than the work. **The surface, counted:** 321 `Text()` literals in the app (249 distinct), 153 `showAlert`/`Get.snackbar` sites (~300 more strings), **96 `errorUserMessage` and 60 `errorTitle` strings inside stored procedures**, 56 push/notification composition sites in SPs, ~59 hardcoded strings in the public web. Roughly 700–900 strings. No scaffolding exists: `intl` is a dependency for date formatting only — no `flutter_localizations`, no `.arb`, no `generate: true`. **The extraction is the easy part. The four that are not:** (1) **a third of the user-facing text lives in the database** — errors, titles and push bodies are composed server-side and arrive rendered, so localising them means either returning a key plus parameters from every SP (a contract change across every client) or storing translations keyed by locale (a new table, which is James's call). `HC.Device.Locale` already exists and is populated, so the server can know who it is speaking to. (2) **Chinese breaks the typography** — the app is set in Avenir Next, which has no CJK glyphs, so Traditional Chinese needs a bundled or fallback font and different line-breaking. (3) **German expands text by about 30%**, and this codebase has already shipped Row-overflow bugs twice — hence claude.md's "two controls side by side want a Wrap, not a Row". Every screen needs re-checking at longer strings, and this cost is larger than the translating. (4) **Hash jargon probably should not be translated** — hare, down-down, on-on, mismanagement, hash cash. What stays in English is a hasher's judgement, not a translator's. **Rough shape:** 2–4 weeks of development for two languages, plus someone to produce ~800 strings per language, plus a permanent tax on every new string (enforceable with a lint banning raw literals in `Text()`). **The cheap first slice, if it is ever wanted:** the app chrome only, one language, driven by the device locale, leaving server errors in English — about a third of the work, proves the pipeline, and serves the German devices without committing to the SP contract change. | `Backlog` |

## E18 — Email that arrives

`API` `DB` `Portal` `Web`

Harrier Central sends email in at least eight places: invite codes, web sign-in codes,
kennel requests, abuse reports, run statistics, payment reports, the portal's member
mail-out and the per-run alerts. Those stories live in the epics they serve and keep
their IDs (`E1.F3.S3`, `E9.F7.S2`, `E12.F1.S8`, `E9.F1.S17`, `E10.F3.S3`, `E8.F6.S3`,
`E12.F4.S3`, `E1.F4.S2`). This epic owns what they all share and nobody owned: **the
sending itself**. Raised 2026-10-08 (James) after CERN H3 could not sign in; it carries
on from `E9.F7.S16`, the 2026-09-17 ask to review the email functions.

### E18.F1 · Getting through

| ID | Story | Status |
|---|---|---|
| `E18.F1.S1` | As a **hasher with a Gmail address**, I want my invite code to reach my inbox, so that I can sign in at all. **Found 2026-10-08:** every email went out through an Outlook.com connector as `gd@jamesawhite.com`, whose domain publishes DMARC `p=reject` with SPF `include:icloud.com` only, so Gmail, Proton and GMX/web.de dropped it silently while the Logic App recorded "Succeeded". That morning CERN H3 members asked for their codes up to seven times and never got in; BT and iCloud addresses got theirs within minutes. **The fix:** send from a Microsoft 365 mailbox on harriercentral.com, DKIM-signed, through the Office 365 Outlook connector. **Route chosen 2026-10-08: the API sends through Microsoft Graph** (`api/Endpoints/HcEmail.cs`, app-only `Mail.Send`) instead of the Logic App, falling back to the Logic App until the Graph settings exist. **⚠ Known gap:** domain verified, MX/SPF/autodiscover/DKIM CNAMEs live (2026-10-08); not done — DKIM switched on in Defender (Microsoft had not yet seen the CNAMEs), the Entra app registration + admin consent + an access policy limiting it to the one mailbox, `SendFromAliasEnabled`, the five Function App settings, the API deploy, and a test to a Gmail address. Rollback: `tools/email_sender_smtp.sh rollback` restores the saved Outlook definition. | `Building` |
| `E18.F1.S2` | As a **Platform Admin**, I want a failed send to be a failure, so that "the email never arrived" shows up in the logs before a hasher has to tell me. The `SendEmail` Logic App answers **HTTP 200 with the body `"Failed"`** when its send action fails, and `Utilities.SendEmailAsync` only checks the status code, so every caller counts a failure as sent. The Logic App should return a 5xx on failure, `SendEmailAsync` should check, and a failure should land in `HC.ErrorLog` with the recipient's domain (not the address) and the caller. **⚠ Known gap:** built on `dev` 2026-10-08 in `HcEmail` (every send logs to `HC.ErrorLog` as `Email send failed (<caller>)` and throws `EmailSendException`; the Logic App's 200 `"Failed"` is now read as a failure), not deployed. | `Building` |
| `E18.F1.S3` | As a **Platform Admin**, I want harriercentral.com to publish a DMARC policy, starting with `p=none` and aggregate reports and moving to `quarantine` once the reports are clean, so that a forged "Harrier Central" email is rejected and I can see who is sending as us. Only after `E18.F1.S1` has signed every send with DKIM for a week. | `Backlog` |
| `E18.F1.S4` | As a **Platform Admin**, I want the email trigger's signed URL to be a secret again: it is a literal in `api/Endpoints/Utilities.cs` and therefore public in the repo, so anyone can send mail as Harrier Central through it. Rotate the trigger key, set `HC_EMAIL_LOGIC_APP_URL` on the Function App, delete the fallback (noted 2026-09-28). **Superseded by sending through Microsoft Graph** (`HcEmail`, 2026-10-08): once the Graph settings are live the trigger is unused, and the Logic App and its URL can be deleted outright. **⚠ Known gap:** the literal still lives in `HcEmail.LogicAppUrl` as the fallback until then. | `Building` |

### E18.F2 · One voice

| ID | Story | Status |
|---|---|---|
| `E18.F2.S1` | As a **hasher**, I want every Harrier Central email to come from one recognisable sender, `noreply@harriercentral.com`, with replies going somewhere a person reads (`connect@`, or the kennel's own contact where the email is about a kennel), so that I trust it and it does not land in spam. Today `Utilities.EmailFrom` names `james@defenceinnovation.eu`, which the connector ignores anyway. | `Next` |
| `E18.F2.S2` | As a **hasher**, I want Harrier Central emails to share one template — the logo, a readable layout on a phone, a plain-text part, and a line saying why I received it and how to stop — so that a code email does not look like phishing. Today each endpoint builds its own HTML and the Logic App wraps it in a bare `<p>`. | `Backlog` |
| `E18.F2.S3` | As a **Hash Cash**, I want an attachment to carry its own name, so that a payment report does not arrive as `run_stats_report.xlsx` — the name `SendEmailAsync` gave every attachment. **⚠ Known gap:** built on `dev` 2026-10-08 (`EmailAttachment.Excel("Payment report - <run>")`, `Run stats - <kennel>`, `Run counts - <kennel>`), not deployed. | `Building` |


Status reflects the working tree at `dev` on 2026-09-12. Epic and story IDs are stable — quote them when assigning work. Where a story is marked **Building** with a known gap, the gap names what is actually missing rather than what remains to polish.

Bugs and individual work items live in GitHub Issues; this document is the map above them.

