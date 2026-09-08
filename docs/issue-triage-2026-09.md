# Issue triage — working list

**Baseline: 120 → 55 open** (2026-09-08).

The tracker was baselined on 2026-09-08: **65 of the 120 open issues were closed** — 46 that had shipped, each with a comment naming the backlog story that covers it, and 19 describing subsystems that no longer exist. Facebook integration appears nowhere in the current app or API, and HcWeb (HC3W) was replaced by the Flutter portal, so those reports cannot be reproduced.

**55 remain.** 24 are real unbuilt work; 31 need a decision only you can make. This file
is the working list for those 55 — the 65 that were closed are recorded at the bottom
so the baseline is auditable.

| | Count | What to do with them |
|---|---|---|
| Still valid | 24 | Label with epic and component, put on a board |
| Needs your call | 31 | Answer the question; most take one line |


---

## Still valid — real unbuilt work — 24

Nothing here is built. Where a backlog story already covers it, that story is the home and the issue is the work item; where the Backlog column shows a dash, the backlog has a gap worth filling.

| Issue | Title | Why it stands | Backlog |
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

I could not decide these from the code alone. Most are behaviour reported in 2022 that has changed enough since that I cannot tell whether it still reproduces; a few were never engineering questions. Each has a specific question — most take one line to answer.

| Issue | Title | Question | Backlog |
|---|---|---|---|
| [#14](https://github.com/James-A-White/HarrierCentral/issues/14) | Add ability to track runs even if kennel is not on the app | Does this mean PackTrack for a kennel that is not on the platform, or logging runs for one? | — |
| [#21](https://github.com/James-A-White/HarrierCentral/issues/21) | Profile image change -> cut a step | Open Profile and change the photo — is there still a redundant Next step? | `E1.F4.S1` |
| [#36](https://github.com/James-A-White/HarrierCentral/issues/36) | HcWeb -> Push/edit events to/in google calendar | Do you still want per-user Google auth so a hasher writes to their own calendar, or is kennel-level push enough? | `E3.F6.S1` |
| [#37](https://github.com/James-A-White/HarrierCentral/issues/37) | Calendar -> Tokens to control run counts/other event parameters | Is the calendar-token idea dead? It depended on integration you no longer run. | — |
| [#53](https://github.com/James-A-White/HarrierCentral/issues/53) | Website: Create two sections for Kennels to show free features and paid features | Is there a commercial model to build to yet, or is this still an idea? | — |
| [#65](https://github.com/James-A-White/HarrierCentral/issues/65) | Email templating improvement suggestions | Which of these template ideas still apply to the portal's email screen? | `E12.F4.S3` |
| [#75](https://github.com/James-A-White/HarrierCentral/issues/75) | Enhancement, HC-App: Remove digital payment prompt when user has been marked "paid" | Does the payment prompt still appear after a hasher is marked paid? | — |
| [#89](https://github.com/James-A-White/HarrierCentral/issues/89) | Hash cash pricing | Wontfix? Current tiers are member / visitor / virgin. | `E8.F1.S1` |
| [#97](https://github.com/James-A-White/HarrierCentral/issues/97) | Set HC App Access screen | Does the App Access screen still cut off at the top? | — |
| [#109](https://github.com/James-A-White/HarrierCentral/issues/109) | Enhancement: Make adding members quicker when on-site at the hash | Is adding a member on-site still too slow, and is the email address still required? | `E2.F2.S2` |
| [#116](https://github.com/James-A-White/HarrierCentral/issues/116) | Ability for admins to set past run attendance by Hasher not by run | Can an admin already set attendance per hasher across several runs, or only per run? | `E4.F4` |
| [#164](https://github.com/James-A-White/HarrierCentral/issues/164) | Kennel admin able to edit Hasher names | Should a kennel admin be able to change another hasher's name? This is a policy call, not a bug. | `E2.F2` |
| [#200](https://github.com/James-A-White/HarrierCentral/issues/200) | Add "tearline" feature to Kennel description | What should a tearline in the kennel description actually do? | — |
| [#208](https://github.com/James-A-White/HarrierCentral/issues/208) | Kennel submitted two different default hash cash prices, but system used same for both | Can a kennel still submit two default prices and have one used for both? | `E8.F1.S1` |
| [#210](https://github.com/James-A-White/HarrierCentral/issues/210) | After logging about 45 past runs, information from newly entered past event overwrites some of the data (map, hares) of the upcoming event | Does entering many past runs still corrupt an upcoming run's map and hares? | `E3.F5` |
| [#227](https://github.com/James-A-White/HarrierCentral/issues/227) | HC-App, Enhancement: "paid" status is perpetual for paypal/credit prompt uses | Is paid status still perpetual for the PayPal and credit prompt? | — |
| [#234](https://github.com/James-A-White/HarrierCentral/issues/234) | Bug, HC-App: Some members do not see "check-in" or "use credit" prompts | Do mismanagement members still miss the check-in and use-credit prompts? Permissions V2 may have cured it. | `E2.F4` |
| [#239](https://github.com/James-A-White/HarrierCentral/issues/239) | Last run date in the app does not respect the "hidden" flag | Does the last-run date still ignore the hidden flag? | — |
| [#248](https://github.com/James-A-White/HarrierCentral/issues/248) | Expand description field beyond 4000 characters | What should the description limit be? Duplicate of #304 — close one. | — |
| [#259](https://github.com/James-A-White/HarrierCentral/issues/259) | Add dirty confirmation on run edit screens in the app | Does the run editor still lose changes on navigate-away, after the single-save refactor? | — |
| [#261](https://github.com/James-A-White/HarrierCentral/issues/261) | "North Lock" map on Kennel info page | Do you want true-north lock on the kennel info map too, or is PackTrack enough? | `E5.F4` |
| [#264](https://github.com/James-A-White/HarrierCentral/issues/264) | Written by Hashers for Hashers | Is this a marketing tagline? If so it is not an engineering issue. | — |
| [#267](https://github.com/James-A-White/HarrierCentral/issues/267) | HC-App: Name sorting in Hash Cash view inconsistent with other screens | Is name sorting in the Hash Cash view still inconsistent with other screens? | — |
| [#272](https://github.com/James-A-White/HarrierCentral/issues/272) | Bug, HC-App: User displays Nerd Name, but sorts with Hash Name | Should display and sort both use the hash name? | — |
| [#278](https://github.com/James-A-White/HarrierCentral/issues/278) | Empower Hares? | Do you want volunteer-to-hare with an approval step? Hares can already edit their own run. | `E2.F4.S4` |
| [#292](https://github.com/James-A-White/HarrierCentral/issues/292) | Add global leaderboard for hashed and hared in the app | Do you want a hared leaderboard alongside the run one? | `E10.F2.S1` |
| [#304](https://github.com/James-A-White/HarrierCentral/issues/304) | Add extra space for run descriptions (e.g. for Taiwan). | Duplicate of #248 — close one and set the limit. | — |
| [#312](https://github.com/James-A-White/HarrierCentral/issues/312) | No buttons/access to add/manage runs on portal if there are none  | Does the portal still show a blank page when a kennel has no runs? | — |
| [#314](https://github.com/James-A-White/HarrierCentral/issues/314) | Admin Portal not sorting correctly... | Does the sorting problem still occur in the Flutter portal, or only the retired one? | — |
| [#329](https://github.com/James-A-White/HarrierCentral/issues/329) | Adjusting visitor RSVP actually adjusts my own RSVP | Does adjusting a visitor's RSVP still change your own? | `E4.F1` |
| [#335](https://github.com/James-A-White/HarrierCentral/issues/335) | Trying to install the hashing app | Still reproducible? The boot work since may have cured it — the reporter could confirm. | `E14.G4.R1` |

---

## Closed at baseline — 65

Each received a comment before closing. Shipped issues were closed as completed with a pointer to their backlog story ([docs/backlog.md](https://github.com/James-A-White/HarrierCentral/blob/dev/docs/backlog.md)); obsolete ones as not planned, inviting a fresh issue if the reporter can still reproduce something similar.

| Issue | Title | Disposition |
|---|---|---|
| [#5](https://github.com/James-A-White/HarrierCentral/issues/5) | Allow kennel owner to manage admin accounts | Delivered |
| [#12](https://github.com/James-A-White/HarrierCentral/issues/12) | Add Haberdashery support | Delivered |
| [#16](https://github.com/James-A-White/HarrierCentral/issues/16) | Implement "transfer from other phone" option on setup | Delivered |
| [#24](https://github.com/James-A-White/HarrierCentral/issues/24) | Menu structure | Delivered |
| [#25](https://github.com/James-A-White/HarrierCentral/issues/25) | App -> Hash Cash option (unlockable by admin) | Delivered |
| [#26](https://github.com/James-A-White/HarrierCentral/issues/26) | Pay from within the app | Delivered |
| [#33](https://github.com/James-A-White/HarrierCentral/issues/33) | Adding a member | Obsolete |
| [#34](https://github.com/James-A-White/HarrierCentral/issues/34) | HcWeb App -> entering (saving) event | Obsolete |
| [#38](https://github.com/James-A-White/HarrierCentral/issues/38) | Things to look into (from the Dev team) | Obsolete |
| [#40](https://github.com/James-A-White/HarrierCentral/issues/40) | Debug offline mode | Delivered |
| [#41](https://github.com/James-A-White/HarrierCentral/issues/41) | Map options | Delivered |
| [#42](https://github.com/James-A-White/HarrierCentral/issues/42) | Logout function does not work with Facebook OAuth enabled | Obsolete |
| [#44](https://github.com/James-A-White/HarrierCentral/issues/44) | Hare RSVP note still showing, despite hare assigned in HCWeb | Obsolete |
| [#47](https://github.com/James-A-White/HarrierCentral/issues/47) | HC-Web: Runs List > Date sort based on displayed value, not datestamp | Obsolete |
| [#48](https://github.com/James-A-White/HarrierCentral/issues/48) | HC-Web: Unable to delete past runs | Obsolete |
| [#55](https://github.com/James-A-White/HarrierCentral/issues/55) | Question: What does the end user see when an admin manually creates a hasher? | Delivered |
| [#57](https://github.com/James-A-White/HarrierCentral/issues/57) | Add dynamic loading of Hashers | Delivered |
| [#61](https://github.com/James-A-White/HarrierCentral/issues/61) | ERROR: Cannot delete duplicate user - "modification affects multiple base tables" | Obsolete |
| [#74](https://github.com/James-A-White/HarrierCentral/issues/74) | Data mismatch: FB-created event details & email blast to members | Obsolete |
| [#78](https://github.com/James-A-White/HarrierCentral/issues/78) | Finish "Log out" feature | Delivered |
| [#82](https://github.com/James-A-White/HarrierCentral/issues/82) | Add tutorial videos | Delivered |
| [#85](https://github.com/James-A-White/HarrierCentral/issues/85) | Ability to delete user with no runs and payments. | Delivered |
| [#86](https://github.com/James-A-White/HarrierCentral/issues/86) | Super user who are the admins for a Kennel | Delivered |
| [#92](https://github.com/James-A-White/HarrierCentral/issues/92) | Documentation! | Delivered |
| [#93](https://github.com/James-A-White/HarrierCentral/issues/93) | Trail chat | Delivered |
| [#95](https://github.com/James-A-White/HarrierCentral/issues/95) | How to transfer admins? | Delivered |
| [#96](https://github.com/James-A-White/HarrierCentral/issues/96) | Make sure only one Kennel can be added per FB ID and website and name. | Obsolete |
| [#103](https://github.com/James-A-White/HarrierCentral/issues/103) | How to update Kennel Logo? | Delivered |
| [#106](https://github.com/James-A-White/HarrierCentral/issues/106) | Problem with overwriting placeholder | Obsolete |
| [#111](https://github.com/James-A-White/HarrierCentral/issues/111) | Migrate to NULL Safety | Delivered |
| [#125](https://github.com/James-A-White/HarrierCentral/issues/125) | Make hash name a required field when setting up the app even if just "Just + Name" | Delivered |
| [#144](https://github.com/James-A-White/HarrierCentral/issues/144) | Turn permissions on option | Delivered |
| [#153](https://github.com/James-A-White/HarrierCentral/issues/153) | Add pins for next runs for a kennel to the user-facing map for that Kennel plus Explore runs button | Delivered |
| [#173](https://github.com/James-A-White/HarrierCentral/issues/173) | Add publicly available web page to display Hash runs | Delivered |
| [#176](https://github.com/James-A-White/HarrierCentral/issues/176) | Open source code and can I contribute? | Delivered |
| [#194](https://github.com/James-A-White/HarrierCentral/issues/194) | HC-Web: Kennel information mismatched between different admin portals | Obsolete |
| [#204](https://github.com/James-A-White/HarrierCentral/issues/204) | Ensure deleted FB events are hidden | Obsolete |
| [#215](https://github.com/James-A-White/HarrierCentral/issues/215) | HC-App, Enhancement - Add address/POI search into Run Details map view | Delivered |
| [#216](https://github.com/James-A-White/HarrierCentral/issues/216) | HC-App, Enhancement - "Edit Run Details" -> auto-complete hare name list | Delivered |
| [#217](https://github.com/James-A-White/HarrierCentral/issues/217) | HC-App, Enhancement - Push and Automatic Email Notifications | Delivered |
| [#220](https://github.com/James-A-White/HarrierCentral/issues/220) | Fix run number calculation for cases when a past run has been marked as "not counted" | Delivered |
| [#221](https://github.com/James-A-White/HarrierCentral/issues/221) | Implement a web-portal for adding / updating runs and events | Delivered |
| [#236](https://github.com/James-A-White/HarrierCentral/issues/236) | Enhance security of Facebook and external integration component | Obsolete |
| [#240](https://github.com/James-A-White/HarrierCentral/issues/240) | Blank user image tile in next Brussels run | Delivered |
| [#254](https://github.com/James-A-White/HarrierCentral/issues/254) | Create "add run" button on portal | Delivered |
| [#256](https://github.com/James-A-White/HarrierCentral/issues/256) | Fix portal for updating run info so it say Use Update from FB instead of San Diego | Obsolete |
| [#257](https://github.com/James-A-White/HarrierCentral/issues/257) | Ensure that when someone has checked in to a run, they see that run in the run history view | Delivered |
| [#258](https://github.com/James-A-White/HarrierCentral/issues/258) | Add new mismanagement role for Harrier Central Admin | Delivered |
| [#260](https://github.com/James-A-White/HarrierCentral/issues/260) | Add ability to edit location from the app (and not just the pin point) | Delivered |
| [#262](https://github.com/James-A-White/HarrierCentral/issues/262) | Add Kennel editing features to the portal | Delivered |
| [#274](https://github.com/James-A-White/HarrierCentral/issues/274) | Add Kennel Song Book support | Delivered |
| [#275](https://github.com/James-A-White/HarrierCentral/issues/275) | Implement permissions on HC portal to match HC Admin Roles | Delivered |
| [#279](https://github.com/James-A-White/HarrierCentral/issues/279) | New hasher added on portal, appeared on Membership, but not on Non-app Hasher | Obsolete |
| [#283](https://github.com/James-A-White/HarrierCentral/issues/283) | Update Display Name on Super Admin Portal -- there's a disconnect between the Admin Portal | Obsolete |
| [#285](https://github.com/James-A-White/HarrierCentral/issues/285) | BUG: Facebook feed creating numbered runs for non-numbered events | Obsolete |
| [#288](https://github.com/James-A-White/HarrierCentral/issues/288) | Improve how users are replicated to the mobile app. | Delivered |
| [#290](https://github.com/James-A-White/HarrierCentral/issues/290) | Deleting off FB doesn't delete a hash--neither does hiding and not counting | Obsolete |
| [#291](https://github.com/James-A-White/HarrierCentral/issues/291) | Ability of super admins to see email addresses for members | Delivered |
| [#297](https://github.com/James-A-White/HarrierCentral/issues/297) | Add notification to open the app for Hashers that RSVP for runs so they can check in | Delivered |
| [#298](https://github.com/James-A-White/HarrierCentral/issues/298) | Interactive song book...  | Delivered |
| [#301](https://github.com/James-A-White/HarrierCentral/issues/301) | Add another payment button for Haberdashery | Delivered |
| [#302](https://github.com/James-A-White/HarrierCentral/issues/302) | Add RSVP for Runs plus extras for events with extras | Delivered |
| [#306](https://github.com/James-A-White/HarrierCentral/issues/306) | Add delete me permanently button to be GDPR compliant | Delivered |
| [#307](https://github.com/James-A-White/HarrierCentral/issues/307) | Allow Kennels to be able to edit their own info (especially Hash Cash) | Delivered |
| [#311](https://github.com/James-A-White/HarrierCentral/issues/311) | Need to add "other payment" button for visitors / virgins | Delivered |
