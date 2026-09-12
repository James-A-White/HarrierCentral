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

### E5.F6 · Track administration  
`App` `API`

| ID | Story | Status |
|---|---|---|
| `E5.F6.S1` | As a **Kennel HC Admin**, I want to trim the start and end of a recorded track so that the drive to the pub is not part of the trail. | `Shipped` |
| `E5.F6.S2` | As a **Kennel HC Admin**, I want to delete a track entirely so that a mis-recorded trail can be removed. | `Shipped` |
| `E5.F6.S3` | As a **Platform Admin**, I want to know from SQL which runs have tracks so that reporting does not require walking partition keys in Table Storage. `HC.EventTrack`, one row per tracked run, written by StorePositions per batch and backfilled from Table Storage; the per-hasher record is E3.F3.S7's `Track*` columns on `HC.HasherEventMap`. | `Shipped` |
| `E5.F6.S4` | As a **Hasher**, I want my own PackTrack trail stored as gzipped content on my `HC.HasherEventMap` row — one runner, one run, one compressed blob — so that my trail survives independently of the position store and a past run replays from the database alone. Written once when tracking ends, never per batch, beside the `Track*` summary columns E3.F3.S7 put on the same row. The phone is not involved (James, 2026-09-10): a nightly Azure Function (`ArchiveTracksNightly`, 03:30 UTC) archives every finished track that has no archive — rows StorePositions counted, plus runners on recently tracked runs whose row was never counted — delta-encoded varint + gzip at ~5.5 bytes a point. A later point (`StorePositions`) or a deleted one (`DeletePositions`) drops the archive so the next night rebuilds it. A runner found in a run's partition with no attendance row gets one (`nonApi_ensureTrackAttendance`, the same At Hash row a real check-in writes, run counts recomputed): every runner who has a track has an attendance row. `tools/archive_all_tracks.sh` runs the same sweep on demand over every tracked run. `GetPositions` serves a finished run from the archive on a full fetch once every counted runner on it has one (response carries `source: archive`; incremental polls stay on Table Storage so a resumed run still streams), so every client replays past runs from the database without a client change. Shipped 2026-09-10: writer in API 1.0.41, reader in API 1.0.42; first pass archived 309 tracks on 156 runs (1.5 MB) and created 2 missing attendance rows. | `Shipped` |
| `E5.F6.S5` | As a **Platform Admin**, I want the 709 legacy `PHO::` photo points removed from the position store once no shipped client reads pins from them, so that a photo lives only on its own row. **Due 2026-12-09**, after app ≤3.0.15 and web ≤0.21.44 are out of production — issue #336 has the check and the deletion path. | `Next` |
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
| `E6.F2.S5` | As a **Hasher**, I want a button on a past run that finds the photos of it still sitting in my camera roll so that the club's gallery gets the pictures I never got round to filing. Designed 2026-09-12 (James). Scan is **per run and on demand** — never a background sweep of the roll. Candidates are photos captured from 30 minutes before the run's start to six hours after it, **that carry a location**: a photo with a time but no coordinate is discarded rather than offered, because a roll full of unrelated pictures is worse than a missed one. Location is read from the media store as well as the EXIF, since a forwarded or permission-stripped photo often keeps one and not the other. A candidate must fall near the hasher's **own trail for that run** (any point, not just the start — the On-Inn and the far end of trail are both a long way from the circle), falling back to a radius around the start where they have no track. Only runs they attended are offered. The matched photos appear in a **selector the hasher ticks**, carrying the notice that what they send may become publicly viewable; nothing uploads on its own. Uploads take the existing path, so capture time, coordinate, asset id and the Hash Flash review queue all apply, and a photo already uploaded is skipped on its asset id. **Needs:** full camera-roll permission (the app deliberately bypasses the check today because it only touches its own assets) and a privacy-declaration update in both stores. | `Next` |

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

### E9.F2 · Push notifications  
`App` `API`

| ID | Story | Status |
|---|---|---|
| `E9.F2.S1` | As a **Hasher**, I want a push when somebody messages a run I am attending so that I do not have to keep opening the app. | `Shipped` |
| `E9.F2.S2` | As a **Hasher**, I want a push when the RA selects a song so that I can find the words in the circle. | `Shipped` |
| `E9.F2.S3` | As a **Hasher**, I want a reminder before a run I said I would attend so that I do not forget. | `Shipped` |
| `E9.F2.S4` | As a **Platform Admin**, I want silent sync pushes budgeted against the platform's throttle so that iOS does not quietly stop delivering them. | `Shipped` |

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

---

## E13 · non-functional — Security, Privacy & Data Protection

Constraints rather than stories, so each is stated as a requirement with the mechanism that enforces it. An unenforced requirement is a wish.

### E13.G1 · Authentication & authorisation

| ID | Requirement | Enforced by |
|---|---|---|
| `E13.G1.R1` | No password exists anywhere in the platform; identity is a device-bound shared secret. | `hcapp_authorizeDevice` mints a 75-char secret and a per-device 30–44s window. |
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
| `E14.G1.R5` | Every locally cached row is uniquely keyed on the server primary key, so a resync running concurrently with another sync, or with a write procedure that returns the same rows, cannot insert a duplicate. | **3.1 track.** Planned — a UNIQUE constraint on the remote id in every local table, plus a `DB_VERSION` bump of 10 so the reload recreates the tables and clears every device's existing duplicates; the sync writers must switch to insert-or-replace first. The 2026-08-16 async serialiser closed the sync-vs-sync path only; write procedures still return sync rowsets outside it. |
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

### E16.F4 · Verification debt  
`App`

> 149 unverified checks across 20 features shipped without a device pass, carried in `docs/verification-backlog.md`. These are individual work items and belong in the issue tracker, not here — this feature exists so the debt is visible at the backlog level.

| ID | Story | Status |
|---|---|---|
| `E16.F4.S1` | As a **Platform Admin**, I want every feature shipped blind to get a device pass so that the install base is not the test suite. | `Building` |
| `E16.F4.S2` | As a **Platform Admin**, I want the verification backlog tracked as issues so that another developer can pick one up. | `Next` |
| `E16.F4.S3` | As a **Platform Admin**, I want the battery draw re-measured after each release so that a regression is caught by data rather than by a complaint. | `Next` |
| `E16.F4.S4` | As a **Platform Admin**, I want a working test harness in the portal so that a regression there can be pinned by a test rather than found by a kennel. **⚠ Known gap:** `flutter_test` is commented out of the portal's dev_dependencies and `widget_test.dart` has no `main` — the portal has no test coverage at all, and enabling it hits a `web` package incompatibility | `Next` |

---

Status reflects the working tree at `dev` on 2026-09-12. Epic and story IDs are stable — quote them when assigning work. Where a story is marked **Building** with a known gap, the gap names what is actually missing rather than what remains to polish.

Bugs and individual work items live in GitHub Issues; this document is the map above them.

