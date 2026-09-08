# Issue triage — the 120 open issues, September 2026

Every open issue on `James-A-White/HarrierCentral`, classified. All 120 are here;
none were skipped.

**Why this exists.** The tracker holds 120 open issues, every one from 2020–2022
apart from a single 2024 report, and nothing since. Several describe work that
shipped years ago. Before inviting outside contributors that is worse than an
empty tracker: someone picks up an issue and builds what already exists.

**Nothing has been actioned.** This is a proposal. No issue has been closed,
commented on or relabelled.

| Disposition | Count | Meaning |
|---|---|---|
| Close — delivered | 46 | The feature exists; close with a pointer to the backlog story |
| Close — obsolete | 19 | Describes a retired subsystem (Facebook, HcWeb) |
| Keep — still valid | 24 | Real unbuilt work |
| Needs your call | 31 | I could not decide from the code alone |

Closing the first two groups takes the tracker from 120 to **55 open**, of which
24 are known work and 31 need a decision.

**Confidence.** `Close — delivered` and `Close — obsolete` I am confident about;
each was checked against the current code or against a subsystem that verifiably
no longer exists. `Needs your call` is where I stopped rather than guess.

---

## Close — delivered — 46

The feature exists today. Each names the backlog story that covers it, so the close comment can point at something concrete.

| Issue | Title | Why | Backlog |
|---|---|---|---|
| [#5](https://github.com/James-A-White/HarrierCentral/issues/5) | Allow kennel owner to manage admin accounts | Owner/admin separation exists as AppAccessFlags plus the permission matrix. | `E2.F4` |
| [#12](https://github.com/James-A-White/HarrierCentral/issues/12) | Add Haberdashery support | Haberdashery sells through the payment flow as productType 3. | `E8.F3` |
| [#16](https://github.com/James-A-White/HarrierCentral/issues/16) | Implement "transfer from other phone" option on setup | Invite-code recovery plus approve-from-trusted-device covers phone transfer. | `E1.F3` |
| [#24](https://github.com/James-A-White/HarrierCentral/issues/24) | Menu structure | Menu now groups legal, privacy, imprint, FAQ and support. | `E9.F5` |
| [#25](https://github.com/James-A-White/HarrierCentral/issues/25) | App -> Hash Cash option (unlockable by admin) | Hash Cash check-in with RSVP-vs-paid visibility is the run admin screen. | `E4.F2` |
| [#26](https://github.com/James-A-White/HarrierCentral/issues/26) | Pay from within the app | Self-service payment from the app. | `E8.F1.S3` |
| [#40](https://github.com/James-A-White/HarrierCentral/issues/40) | Debug offline mode | Offline is now queues with retry across payments, photos and GPS. | `E14.G1.R6` |
| [#41](https://github.com/James-A-White/HarrierCentral/issues/41) | Map options | Map controls were harmonised into one column per canvas. | `E5.F4.S4` |
| [#55](https://github.com/James-A-White/HarrierCentral/issues/55) | Question: What does the end user see when an admin manually creates a hasher? | Answered by the invite-code flow: admin adds, hasher gets a code. | `E1.F3.S5` |
| [#57](https://github.com/James-A-White/HarrierCentral/issues/57) | Add dynamic loading of Hashers | Replaced by domain sync with paged, deterministic replication. | `E14.G1` |
| [#78](https://github.com/James-A-White/HarrierCentral/issues/78) | Finish "Log out" feature | Logout ships, with a keychain reset and restart path. | `E1.F6.S2` |
| [#82](https://github.com/James-A-White/HarrierCentral/issues/82) | Add tutorial videos | Video tutorial page exists. | `E9.F5.S1` |
| [#85](https://github.com/James-A-White/HarrierCentral/issues/85) | Ability to delete user with no runs and payments. | Self-service GDPR delete, plus admin removal from the roster. | `E1.F6.S1` |
| [#86](https://github.com/James-A-White/HarrierCentral/issues/86) | Super user who are the admins for a Kennel | Exactly the Kennel HC Admin persona — AppAccessFlags on HasherKennelMap. | `E2.F3.S3` |
| [#92](https://github.com/James-A-White/HarrierCentral/issues/92) | Documentation! | Superseded by CLAUDE.md, docs/ and the backlog. | — |
| [#93](https://github.com/James-A-White/HarrierCentral/issues/93) | Trail chat | Run chat and kennel chat both ship. | `E9.F1` |
| [#95](https://github.com/James-A-White/HarrierCentral/issues/95) | How to transfer admins? | Role assignment from the roster. | `E2.F3.S1` |
| [#103](https://github.com/James-A-White/HarrierCentral/issues/103) | How to update Kennel Logo? | Kennel logo is editable in the portal. | `E11.F4.S1` |
| [#111](https://github.com/James-A-White/HarrierCentral/issues/111) | Migrate to NULL Safety | Null safety landed in the 3.x rewrite. | — |
| [#125](https://github.com/James-A-White/HarrierCentral/issues/125) | Make hash name a required field when setting up the app even if just "Just + Name" | Hash name is collected at signup. | `E1.F2.S1` |
| [#144](https://github.com/James-A-White/HarrierCentral/issues/144) | Turn permissions on option | Permissions V2 is data-driven with per-kennel tri-state overrides. | `E2.F4.S2` |
| [#153](https://github.com/James-A-White/HarrierCentral/issues/153) | Add pins for next runs for a kennel to the user-facing map for that Kennel plus Explore runs button | Guest discovery and the run locations map cover this. | `E1.F5.S1` |
| [#173](https://github.com/James-A-White/HarrierCentral/issues/173) | Add publicly available web page to display Hash runs | The entire public web. | `E11` |
| [#176](https://github.com/James-A-White/HarrierCentral/issues/176) | Open source code and can I contribute? | Answered: CONTRIBUTING.md now exists and the repo takes contributions. | — |
| [#215](https://github.com/James-A-White/HarrierCentral/issues/215) | HC-App, Enhancement - Add address/POI search into Run Details map view | Address search and pin drop both ship in the run editor. | `E3.F2.S2` |
| [#216](https://github.com/James-A-White/HarrierCentral/issues/216) | HC-App, Enhancement - "Edit Run Details" -> auto-complete hare name list | Hare selection autocompletes from the roster. | `E3.F1.S1` |
| [#217](https://github.com/James-A-White/HarrierCentral/issues/217) | HC-App, Enhancement - Push and Automatic Email Notifications | Push notifications and scheduled emails both ship. | `E9.F2` |
| [#220](https://github.com/James-A-White/HarrierCentral/issues/220) | Fix run number calculation for cases when a past run has been marked as "not counted" | Run numbering is recalculated in-transaction; the count churn bug was fixed. | `E3.F5.S2` |
| [#221](https://github.com/James-A-White/HarrierCentral/issues/221) | Implement a web-portal for adding / updating runs and events | The Flutter portal. | `E12.F4.S1` |
| [#240](https://github.com/James-A-White/HarrierCentral/issues/240) | Blank user image tile in next Brussels run | This is the bundle:// avatar bug — fixed by the canonical resolver, 2026-07-18. | `E1.F4.S1` |
| [#254](https://github.com/James-A-White/HarrierCentral/issues/254) | Create "add run" button on portal | Runs are added from the portal. | `E12.F4.S1` |
| [#257](https://github.com/James-A-White/HarrierCentral/issues/257) | Ensure that when someone has checked in to a run, they see that run in the run history view | Attended past runs now sit inline above the next run. | `E3.F3.S2` |
| [#258](https://github.com/James-A-White/HarrierCentral/issues/258) | Add new mismanagement role for Harrier Central Admin | This is the Kennel HC Admin role, independent of mismanagement. | `E2.F3.S3` |
| [#260](https://github.com/James-A-White/HarrierCentral/issues/260) | Add ability to edit location from the app (and not just the pin point) | Cascading country/region/city selection plus the pin. | `E3.F2.S1` |
| [#262](https://github.com/James-A-White/HarrierCentral/issues/262) | Add Kennel editing features to the portal | Kennel editing in the portal. | `E12.F4.S1` |
| [#274](https://github.com/James-A-White/HarrierCentral/issues/274) | Add Kennel Song Book support | Songbook with per-kennel selection and pushed song sync. | `E7.F2` |
| [#275](https://github.com/James-A-White/HarrierCentral/issues/275) | Implement permissions on HC portal to match HC Admin Roles | Portal permissions match the kennel model. | `E12.F3` |
| [#288](https://github.com/James-A-White/HarrierCentral/issues/288) | Improve how users are replicated to the mobile app. | Three-domain sync with deterministic paged replication. | `E14.G1` |
| [#291](https://github.com/James-A-White/HarrierCentral/issues/291) | Ability of super admins to see email addresses for members | The roster shows contact details to those permitted. | `E2.F2.S1` |
| [#297](https://github.com/James-A-White/HarrierCentral/issues/297) | Add notification to open the app for Hashers that RSVP for runs so they can check in | Run reminders plus the arrival check-in prompt. | `E9.F2.S3` |
| [#298](https://github.com/James-A-White/HarrierCentral/issues/298) | Interactive song book...  | Song selection pushes to everyone at the run. | `E7.F2.S2` |
| [#301](https://github.com/James-A-White/HarrierCentral/issues/301) | Add another payment button for Haberdashery | Haberdashery payments. | `E8.F3.S1` |
| [#302](https://github.com/James-A-White/HarrierCentral/issues/302) | Add RSVP for Runs plus extras for events with extras | RSVP ships. The extras part may not — check before closing. | `E4.F1` |
| [#306](https://github.com/James-A-White/HarrierCentral/issues/306) | Add delete me permanently button to be GDPR compliant | GDPR delete. | `E1.F6.S1` |
| [#307](https://github.com/James-A-White/HarrierCentral/issues/307) | Allow Kennels to be able to edit their own info (especially Hash Cash) | Kennels edit their own details in the portal. | `E12.F4.S1` |
| [#311](https://github.com/James-A-White/HarrierCentral/issues/311) | Need to add "other payment" button for visitors / virgins | Other-payment button for visitors and virgins. | `E8.F1.S2` |

---

## Close — obsolete — 19

The subsystem these describe is gone. Facebook integration appears nowhere in the current app or API, and HcWeb (HC3W) was replaced by the Flutter portal. Nothing here can be reproduced because the thing it describes no longer runs.

| Issue | Title | Why | Backlog |
|---|---|---|---|
| [#33](https://github.com/James-A-White/HarrierCentral/issues/33) | Adding a member | HcWeb (HC3W) is retired. | — |
| [#34](https://github.com/James-A-White/HarrierCentral/issues/34) | HcWeb App -> entering (saving) event | HcWeb (HC3W) is retired. | — |
| [#38](https://github.com/James-A-White/HarrierCentral/issues/38) | Things to look into (from the Dev team) | 2020 Flutter code notes, predating the null-safety rewrite. | — |
| [#42](https://github.com/James-A-White/HarrierCentral/issues/42) | Logout function does not work with Facebook OAuth enabled | Facebook OAuth no longer exists; sign-in is Apple and Google. | `E1.F2.S6` |
| [#44](https://github.com/James-A-White/HarrierCentral/issues/44) | Hare RSVP note still showing, despite hare assigned in HCWeb | HcWeb (HC3W) is retired. | — |
| [#47](https://github.com/James-A-White/HarrierCentral/issues/47) | HC-Web: Runs List > Date sort based on displayed value, not datestamp | HcWeb (HC3W) is retired. | — |
| [#48](https://github.com/James-A-White/HarrierCentral/issues/48) | HC-Web: Unable to delete past runs | HcWeb (HC3W) is retired. | — |
| [#61](https://github.com/James-A-White/HarrierCentral/issues/61) | ERROR: Cannot delete duplicate user - "modification affects multiple base tables" | HcWeb error. The underlying need is account merging — see #129. | — |
| [#74](https://github.com/James-A-White/HarrierCentral/issues/74) | Data mismatch: FB-created event details & email blast to members | Facebook integration is gone. | — |
| [#96](https://github.com/James-A-White/HarrierCentral/issues/96) | Make sure only one Kennel can be added per FB ID and website and name. | Facebook-ID uniqueness; Facebook integration is gone. | — |
| [#106](https://github.com/James-A-White/HarrierCentral/issues/106) | Problem with overwriting placeholder | Facebook placeholder overwrite; Facebook integration is gone. | — |
| [#194](https://github.com/James-A-White/HarrierCentral/issues/194) | HC-Web: Kennel information mismatched between different admin portals | Comparison between two retired admin portals. | — |
| [#204](https://github.com/James-A-White/HarrierCentral/issues/204) | Ensure deleted FB events are hidden | Facebook integration is gone. | — |
| [#236](https://github.com/James-A-White/HarrierCentral/issues/236) | Enhance security of Facebook and external integration component | Facebook integration is gone. | — |
| [#256](https://github.com/James-A-White/HarrierCentral/issues/256) | Fix portal for updating run info so it say Use Update from FB instead of San Diego | Facebook integration is gone. | — |
| [#279](https://github.com/James-A-White/HarrierCentral/issues/279) | New hasher added on portal, appeared on Membership, but not on Non-app Hasher | Depends on the retired Non-app Hasher concept. | — |
| [#283](https://github.com/James-A-White/HarrierCentral/issues/283) | Update Display Name on Super Admin Portal -- there's a disconnect between the Admin Portal | Retired super admin portal. | — |
| [#285](https://github.com/James-A-White/HarrierCentral/issues/285) | BUG: Facebook feed creating numbered runs for non-numbered events | Facebook integration is gone. | — |
| [#290](https://github.com/James-A-White/HarrierCentral/issues/290) | Deleting off FB doesn't delete a hash--neither does hiding and not counting | Facebook integration is gone. | — |

---

## Keep — still valid — 24

Real, unbuilt work. Where a backlog story already covers it, that story is the home and the issue is the work item; where none is named, the backlog has a gap worth filling.

| Issue | Title | Why | Backlog |
|---|---|---|---|
| [#28](https://github.com/James-A-White/HarrierCentral/issues/28) | Desktop (web) version for Hashers | Member web login is genuinely not built and not designed. | `E11.F6.S1` |
| [#39](https://github.com/James-A-White/HarrierCentral/issues/39) | Add range ring to map to indicate which runs will automatically display | Range ring on the map is small and still valid. No story yet. | — |
| [#59](https://github.com/James-A-White/HarrierCentral/issues/59) | Ability to group events so people can only RSVP as going to one at a time (for Hash weekends) | Run grouping for hash weekends is real and unbuilt. Duplicate of #122. | — |
| [#63](https://github.com/James-A-White/HarrierCentral/issues/63) | Auto repair when Hasher image not available | Missing-blob profile photos still need a cleanup pass. | `E16.F3.S1` |
| [#71](https://github.com/James-A-White/HarrierCentral/issues/71) | Turn Run QR codes into full URLs to enable virgins and visitors to self-report in at runs | QR scanning ships, but a public self-report URL for virgins and visitors does not. | `E4.F2.S2` |
| [#90](https://github.com/James-A-White/HarrierCentral/issues/90) | Add question when a virgin is added | Virgin intake questions were never built. | — |
| [#122](https://github.com/James-A-White/HarrierCentral/issues/122) | Properly implement run grouping | Run grouping. Duplicate of #59 — keep one. | — |
| [#129](https://github.com/James-A-White/HarrierCentral/issues/129) | Ability to merge user accounts | Account merging is a real, unbuilt need and duplicates keep appearing. | — |
| [#130](https://github.com/James-A-White/HarrierCentral/issues/130) | Ability to archive user accounts for home kennel hashers | Archiving members overlaps the richer standing model. | `E2.F5.S3` |
| [#167](https://github.com/James-A-White/HarrierCentral/issues/167) | Enhancement: Include hare reimbursements in Hash Cash report | Receipts are recorded but hare reimbursement is not in the Hash Cash report. | `E8.F6` |
| [#249](https://github.com/James-A-White/HarrierCentral/issues/249) | HC-App, Enhancement: Hash Cash report looks weird for users spending kennel credit | Credit in the Hash Cash report is exactly the ledger work in flight. | `E8.F4.S4` |
| [#250](https://github.com/James-A-White/HarrierCentral/issues/250) | HC-App: Make underpayments easier to manage | Underpayments still have no first-class handling. | `E8.F1` |
| [#265](https://github.com/James-A-White/HarrierCentral/issues/265) | Add optional run end location with time | A scheduled end location with a time was never built. | — |
| [#266](https://github.com/James-A-White/HarrierCentral/issues/266) | Need to add a checkbox acknowledging image ownership to Portal | Image copyright acknowledgement is a real legal gap. Portal side. | — |
| [#268](https://github.com/James-A-White/HarrierCentral/issues/268) | HC-App, Enhancement: Too easy to reject/ignore receipt data | Receipt swipe is still easy to get wrong. | `E8.F6.S1` |
| [#273](https://github.com/James-A-White/HarrierCentral/issues/273) | Need to add a checkbox acknowledging image ownership to app | Image copyright acknowledgement, app side. Pair with #266. | — |
| [#276](https://github.com/James-A-White/HarrierCentral/issues/276) | Add Awards roles | Awards and naming ceremony are backlog. | `E7.F4` |
| [#295](https://github.com/James-A-White/HarrierCentral/issues/295) | Copy run link should create shorter link (tiny url or similar) | Share links work but are long; short links were never built. | `E3.F4.S3` |
| [#300](https://github.com/James-A-White/HarrierCentral/issues/300) | Add a flag for a pin versus a designated general area for hashes with no specific location | A general-area flag versus an exact pin was never built. | — |
| [#309](https://github.com/James-A-White/HarrierCentral/issues/309) | Investigate adding recurring events | Recurring runs remain unbuilt and are already a backlog story. | `E3.F1.S2` |
| [#310](https://github.com/James-A-White/HarrierCentral/issues/310) | Add email contact link  | A kennel contact email list was never built. | — |
| [#317](https://github.com/James-A-White/HarrierCentral/issues/317) | Phantom email address being sent messages by HC-App | Real bug: mail going to removed_ addresses. Pair with #331. | — |
| [#326](https://github.com/James-A-White/HarrierCentral/issues/326) | HC-App, Enhancement: Store email template text from one version/install to another | Email template persistence across installs was never built. | `E12.F4.S3` |
| [#331](https://github.com/James-A-White/HarrierCentral/issues/331) | Fix email parser to respect deleted hash accounts--stop sending emails to deleted hashers | Same defect as #317 — keep one. | — |

---

## Needs your call — 31

I could not decide these from the code alone. Most are behaviour that has changed enough since 2022 that the original report may or may not still reproduce; a few are product or commercial decisions that were never mine to make.

| Issue | Title | Why | Backlog |
|---|---|---|---|
| [#14](https://github.com/James-A-White/HarrierCentral/issues/14) | Add ability to track runs even if kennel is not on the app | Unclear whether this means PackTrack for a kennel not on the platform, or guest run entry. | — |
| [#21](https://github.com/James-A-White/HarrierCentral/issues/21) | Profile image change -> cut a step | UX detail on the avatar flow — needs a look at the current screen before closing. | `E1.F4.S1` |
| [#36](https://github.com/James-A-White/HarrierCentral/issues/36) | HcWeb -> Push/edit events to/in google calendar | Calendar push ships; per-user Google auth to write their own calendar never did. | `E3.F6.S1` |
| [#37](https://github.com/James-A-White/HarrierCentral/issues/37) | Calendar -> Tokens to control run counts/other event parameters | Depends on the Google Calendar token idea, which was never adopted. | — |
| [#53](https://github.com/James-A-White/HarrierCentral/issues/53) | Website: Create two sections for Kennels to show free features and paid features | A commercial decision about free vs paid tiers, not an engineering task. | — |
| [#65](https://github.com/James-A-White/HarrierCentral/issues/65) | Email templating improvement suggestions | Portal email ships; whether these template ideas still apply needs your read. | `E12.F4.S3` |
| [#75](https://github.com/James-A-White/HarrierCentral/issues/75) | Enhancement, HC-App: Remove digital payment prompt when user has been marked "paid" | Payment prompt behaviour has changed a lot; needs checking against the current screen. | — |
| [#89](https://github.com/James-A-White/HarrierCentral/issues/89) | Hash cash pricing | Member/visitor/virgin tiers ship. Men/women pricing looks like a wontfix. | `E8.F1.S1` |
| [#97](https://github.com/James-A-White/HarrierCentral/issues/97) | Set HC App Access screen | App access screen may have been fixed in the 3.0 layout work — needs a look. | — |
| [#109](https://github.com/James-A-White/HarrierCentral/issues/109) | Enhancement: Make adding members quicker when on-site at the hash | Roster add ships, but whether it is fast enough on-site is your call. | `E2.F2.S2` |
| [#116](https://github.com/James-A-White/HarrierCentral/issues/116) | Ability for admins to set past run attendance by Hasher not by run | Bulk attendance by event ships; setting it per-hasher across runs may not. | `E4.F4` |
| [#164](https://github.com/James-A-White/HarrierCentral/issues/164) | Kennel admin able to edit Hasher names | A real question: should an admin be able to change a hasher's name? Needs your ruling. | `E2.F2` |
| [#200](https://github.com/James-A-White/HarrierCentral/issues/200) | Add "tearline" feature to Kennel description | Unclear what a tearline should do here. | — |
| [#208](https://github.com/James-A-White/HarrierCentral/issues/208) | Kennel submitted two different default hash cash prices, but system used same for both | Two default prices resolving to one may still be live — worth a check. | `E8.F1.S1` |
| [#210](https://github.com/James-A-White/HarrierCentral/issues/210) | After logging about 45 past runs, information from newly entered past event overwrites some of the data (map, hares) of the upcoming event | Sounds like a genuine data-corruption bug. May be cured by the run-numbering fixes. | `E3.F5` |
| [#227](https://github.com/James-A-White/HarrierCentral/issues/227) | HC-App, Enhancement: "paid" status is perpetual for paypal/credit prompt uses | Payment status behaviour has changed substantially since 2022. | — |
| [#234](https://github.com/James-A-White/HarrierCentral/issues/234) | Bug, HC-App: Some members do not see "check-in" or "use credit" prompts | May have been cured by Permissions V2, which removed IsAdmin as a bypass. | `E2.F4` |
| [#239](https://github.com/James-A-White/HarrierCentral/issues/239) | Last run date in the app does not respect the "hidden" flag | Whether the hidden flag is respected in last-run-date needs checking. | — |
| [#248](https://github.com/James-A-White/HarrierCentral/issues/248) | Expand description field beyond 4000 characters | Description length. Duplicate of #304 — keep one and decide the limit. | — |
| [#259](https://github.com/James-A-White/HarrierCentral/issues/259) | Add dirty confirmation on run edit screens in the app | The single-save run editor refactor may already cover this. | — |
| [#261](https://github.com/James-A-White/HarrierCentral/issues/261) | "North Lock" map on Kennel info page | True-north lock exists on the PackTrack map but not the kennel info map. | `E5.F4` |
| [#264](https://github.com/James-A-White/HarrierCentral/issues/264) | Written by Hashers for Hashers | Marketing copy, not an engineering task. | — |
| [#267](https://github.com/James-A-White/HarrierCentral/issues/267) | HC-App: Name sorting in Hash Cash view inconsistent with other screens | Sorting inconsistency may persist — worth a look at the Hash Cash list. | — |
| [#272](https://github.com/James-A-White/HarrierCentral/issues/272) | Bug, HC-App: User displays Nerd Name, but sorts with Hash Name | Nerd name vs hash name sorting — needs checking against current display rules. | — |
| [#278](https://github.com/James-A-White/HarrierCentral/issues/278) | Empower Hares? | Hares can edit their own run. Volunteer-to-hare with approval was never built. | `E2.F4.S4` |
| [#292](https://github.com/James-A-White/HarrierCentral/issues/292) | Add global leaderboard for hashed and hared in the app | Global leaderboard ships. A hared leaderboard does not. | `E10.F2.S1` |
| [#304](https://github.com/James-A-White/HarrierCentral/issues/304) | Add extra space for run descriptions (e.g. for Taiwan). | Description length. Duplicate of #248. | — |
| [#312](https://github.com/James-A-White/HarrierCentral/issues/312) | No buttons/access to add/manage runs on portal if there are none  | Empty-state on the portal run list may be fixed — needs a look. | — |
| [#314](https://github.com/James-A-White/HarrierCentral/issues/314) | Admin Portal not sorting correctly... | Sorting on the retired portal, but may still apply to the Flutter one. | — |
| [#329](https://github.com/James-A-White/HarrierCentral/issues/329) | Adjusting visitor RSVP actually adjusts my own RSVP | Visitor RSVP writing the wrong record — needs reproducing on the current build. | `E4.F1` |
| [#335](https://github.com/James-A-White/HarrierCentral/issues/335) | Trying to install the hashing app | Boot hang at kennel batch. Boot work since may have cured it; the reporter can confirm. | `E14.G4.R1` |

---

## Suggested order

1. **Close the 19 obsolete ones first.** They are unambiguous and need no judgement.
2. **Close the 46 delivered ones**, each with a one-line comment naming the backlog
   story. Several reporters are still active hashers and will appreciate knowing the
   thing they asked for in 2021 exists.
3. **Label the 24 keepers** with their epic and component, and put them on a board.
4. **Work the 31 questions** at whatever pace suits — that list is the only part
   that needs you specifically.

Three deserve attention beyond a status change:

- **#164** — whether a kennel admin should be able to change another hasher's name is
  a policy question, not a bug. It has been open since 2021.
- **#317 / #331** — mail going to `removed_` addresses is a live defect a real kennel
  reported twice. It is the strongest candidate for a first fix.
- **#176** — someone asked in 2021 whether they could contribute and never got an
  answer. `CONTRIBUTING.md` now answers it.
