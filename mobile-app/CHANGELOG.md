# Harrier Central Mobile App — Changelog

## 2.13.4+1205 (2026-07-18)

### Fixes
- **Clearing a run search returns you to "now"**: hitting the search X (or deleting the text) used to leave you stranded deep in past runs; the list now jumps back to the boundary between past and upcoming runs.
- **Chat badge clears when you read a chat**: the unread chat count on the top chat bubble (and the Unseen Chats list) now updates the instant you open a chat, instead of sometimes staying stuck on an old count.
- **"Clear all chats" no longer errors**: marking every chat read could fail with a connection error when you had kennel-level chat threads; it now clears cleanly.

### Improvements
- **Mark-all-read feedback**: the "clear all chats" button now flashes and shows a spinner while it works, so the tap is clearly acknowledged.
- **Events filter icon**: the Events filter chip now uses a party-popper 🎉 instead of a star, to better signal "special events."

## 2.13.3+1204 (2026-07-17)

### Fixes
- **"No runs available" no longer flashes**: a background refresh that briefly returned nothing could blank your cached runs list; it now keeps your runs and only shows the empty message when you genuinely have none.

### Improvements
- **PackTrack map controls**: the timeline scrubber is now a full-width bar along the bottom, the buttons are spread out with more room, and the readout shows elapsed run time (h:mm:ss) instead of the absolute clock time.
- **Runner avatars** on the map carousel are now rounded squares to match the pins.

## 2.13.2+1203 (2026-07-16)

### Fixes
- **Run photos no longer cropped**: photos in the map showcase now show the full image (rounded corners kept), instead of being cropped to a square.
- **Avatars for photo-less runners**: a runner with no uploaded photo now shows their bundled avatar on the map and in the runner carousel, instead of a blank pin (or being missing).

### Improvements
- **Tilt playback — easier to pause**: a wider "hold to pause" zone makes it easier to freeze playback.
- **Speed indicator colours**: the playback speed shows blue for forward and orange for reverse (and red when paused).

## 2.13.1+1202 (2026-07-15)

### New Features
- **Full-screen map**: a full-screen button on the run map (both the live-tracking map and a run's Map tab) opens the PackTrack map edge-to-edge, with a close button to return.

### Improvements
- **Trim a run after it finishes**: the official start/end (trim) tools now live in the full-screen map, so you can trim a run any time from its Map tab — not just during the live tracking window. Set start / set end / clear are spread along the bottom in full-screen. (Admins only.)

## 2.13.0+1201 (2026-07-15)

### New Features
- **PackTrack map refreshed to match the website**: the live-run map now shares the website's look and controls — a swipeable **runner carousel**, a tap-to-cycle **playback speed button** (0.5×–4×), a location dot with a **compass direction wedge**, a **"my location"** button, and a GPS-accuracy halo.
- **Photos pop out on the map**: turn on the camera toggle and, as playback reaches one of your photos, it grows out of its pin to centre-screen and back.
- **Official run start & end (admins)**: set the official start/end of a PackTrack recording so anything tracked before the start or after the end is ignored — for when someone starts early or forgets to stop. *(Requires the matching server update to take full effect.)*

### Improvements
- **Tilt playback — easier to pause**: holding the phone near neutral now reliably freezes playback across a comfortable range (wider hold-to-pause zone) with a red paused indicator.
- **Playback speed re-tuned** to match the website (slower and more watchable when zoomed in).
- **Consistent runner colours** between the app and the website.

### Fixes
- **Resuming a run keeps your distance & time**: if the app closed or stopped mid-run, tapping Start again now continues your tracked distance and elapsed time instead of restarting at zero, and stitches the resumed track back into one continuous line.
- **Past runs no longer disappear** from the Runs list after opening the map and coming back.

## 2.12.4+1200 (2026-07-12)

### Fixes
- **Run-count awards (Drink chug-a-lug) fixed**: milestone counts were dropping every hasher's HC-era runs on the day of a run — the current run isn't stamped with its cumulative count until an overnight job, so counts collapsed to the historical-only baseline and the wrong people (and wrong numbers) got badges. Counts are now inclusive of today's run whether or not the overnight job has run, so run/haring milestones are correct live at the circle.

## 2.12.3+1199 (2026-07-11)

### New Features
- **Follow runner toggle**: on the run tracking map, the new follow button (next to tilt) lets you turn off camera tracking and pan the map freely — tap it again to snap back to the selected runner.

## 2.12.2+1198 (2026-07-11)

### Fixes
- **Runs no longer show twice**: runs starting within a few hours of now could appear in both "My past Runs" and "My upcoming runs". A run now stays upcoming until 3 hours after its start time, then moves to past — never both.

## 2.12.1+1197 (2026-07-10)

### New Features
- **Tilt to control playback**: on the run tracking map, enable the tilt toggle next to play — tilt your phone away to speed the replay up (to x4), toward you to slow it down and even reverse. A live speed indicator shows the current rate.

## 2.12.0+1196 (2026-07-10)

### Improvements
- **Past runs at a glance**: past-run cards in the runs list now carry a purple tint so it's obvious when you've scrolled into history.

### Fixes
- **Trail marks**: symbols on the live run map no longer show a spurious integer tag (leftover diagnostics removed; existing marks render clean).

## 2.12.0+1195 (2026-07-06)

### New Features
- **Kennel chat**: every kennel you follow now has its own chat, not tied to any run — open it from the chat icon on the kennel list, and unread kennel chats appear in Unseen Chats.
- **Photo audiences**: photo review now uses audiences — **Private / Members / Public** — plus a **Featured** flag for the kennel home page and a one-per-run **Cover**. Members-only photos are visible only to current members and alumni.
- **Alumni access**: kennel admins can grant (or revoke) alumni access from the member menu — alumni keep members-only content access even after paid membership lapses.

## 2.11.14+1194 (2026-07-06)

### Fixes
- **New runs get the right start time**: creating a run in the app now uses the kennel's default run start time on the day you picked (previously new runs were created at midnight).
- **Unseen Chats**: the list refreshes from the server when you open it via the chat badge, and runs that were deleted or hidden no longer appear.

## 2.11.13+1193 (2026-07-02)

### Fixes
- **Hash Flash grid**: selection check marks now toggle when tapping photos; the bulk action buttons stay visible (greyed) when nothing is selected; and the jungle background extends to the bottom of the page.

## 2.11.12+1192 (2026-07-02)

### Improvements
- **Hash Flash grid polish**: tap now selects a photo (green check, photo stays fully visible); long-press opens it for detailed review. The bulk action buttons are always visible in grid view, the grid/carousel toggle moved next to the Pending/Reviewed pills, and leaving the grid with photos still selected warns you first.

### Fixes
- **Hash Flash**: switching between Pending and Reviewed no longer carries a hidden photo selection across tabs.

## 2.11.11+1191 (2026-07-02)

### New Features / Improvements
- **Hash Flash — grid & bulk review**: the photo reviewer now has a grid/carousel toggle. In grid view you see thumbnails (with a status tag on each); tap one to open it, or long-press to multi-select and bulk **Delete / Keep Private / Share / Add to Gallery / Home Gallery** many photos at once.

### Fixes
- **"My" filter**: past runs you RSVP'd No/Maybe to but didn't attend no longer appear under "My" (the "attended" check was too loose).

## 2.11.10+1190 (2026-07-01)

### Fixes
- **Chat opened from Unseen Chats**: added a back button and fixed the message box being hidden behind the keyboard (the chat now has its own screen with an app bar and resizes for the keyboard).

## 2.11.9+1189 (2026-07-01)

### Fixes
- **Unseen Chats now always shows the runs behind the badge**: if the chat badge has a number, the run appears in the Unseen Chats list — even for a run you don't follow and haven't attended (previously the list could be empty while the badge showed unread messages). These rows come straight from the server and tap directly into the chat.

## 2.11.8+1188 (2026-07-01)

### Fixes
- **New members appear immediately**: adding a member (or a new person on a run) now syncs the Hasher record into the local database right away, so they show up in member/user lists without needing a full resync.
- **Reload Data**: fixed the false "No Connection" dialog (and skewed online/offline detection) — the connection ping response wasn't being parsed correctly.
- **Past runs**: runs you RSVP'd No or Maybe to (and didn't attend) are no longer shown in your past runs.

## 2.11.7+1187 (2026-07-01)

### Improvements
- **Filter bar polish**: all filter buttons are now one uniform size; the Map filter uses a map icon (word removed); the heading no longer includes "past"/"future" wording (more room). The date-filter button keeps its calendar icon and just highlights while a range is active. The "View Map" button moved out of the bar to float over the top-right of the list when the Map filter is on.

## 2.11.6+1186 (2026-07-01)

### New Features / Improvements
- **Filter chips**: the runs list view-switcher is replaced by three stackable filter buttons — **My**, **Events** (★), and **Map** — that can be combined in any way. The heading describes the current selection (e.g. "My Events on Map"); tap it for help.
- **Past runs**: the list now shows all past runs for kennels you follow; turning on **My** narrows both past (attended) and upcoming (RSVP'd) to your own runs.
- Switching filters re-anchors the list on the "My past runs" divider.

## 2.11.5+1185 (2026-07-01)

### New Features / Improvements
- **Runs list — inline past runs everywhere**: the Events and Runs-on-Map views now show your attended past runs above a "My past runs" divider with upcoming runs below, matching the main Runs list. The page title tracks which section you're scrolled into.
- **Map opens on all runs**: the Explore map now opens showing every run — including runs you've attended in the past — instead of only the recent/upcoming window.
- **Unseen Chats across all your runs**: the Unseen Chats view now surfaces unread chats for your full run history (past and future), not just recent/upcoming.
- **Simpler view switcher**: removed the separate "My Runs" view (now covered by the main list + inline past runs).

### Fixes
- **Runs list**: fixed a false "N new runs" indicator that was counting your past runs each time the app came to the foreground.

## 2.11.4+1184 (2026-06-30)

### Fixes
- **Runs list**: fixed the future runs below the "My past runs" divider rendering as a blank grey area. The run-list header cells were indexing the wrong list after the past/future merge and threw while building (which paints blank in a release build); all rows now render correctly.

## 2.11.3+1183 (2026-06-30)

### Fixes
- **Runs list**: fixed the future runs below the "My past runs" divider showing as an empty grey area — the list now fills the screen and renders all runs.

## 2.11.2+1182 (2026-06-30)

### New Features
- **Runs list — My past runs**: the runs list now opens at your next run with a "My past runs" divider just above it; scroll up to browse the runs you've attended. The old future/past toggle is replaced by an always-available date-range filter.

## 2.11.1+1181 (2026-06-28)

### Improvements
- **Admin Portal**: moved to the bottom of the side menu.

### Security
- **Same-device portal login**: the one-time login code is now passed in the URL fragment (never sent to or logged by a server) instead of the query string.

## 2.11.0+1180 (2026-06-27)

### New Features
- **Admin Portal**: admins get an "Admin Portal" item in the menu that opens the web portal already logged in (no QR scan needed).

## 2.11.0+1179 (2026-06-27)

### New Features
- **PackTrack trail types**: pick which trail you're running (Walkers / Short / Normal / Long / Ballbreaker, or your kennel's own) when you start tracking, and filter the run-map playback by trail type.

### Improvements
- Run-map playback speed now scales with the trail's length — 1 s/km zoomed out (a 28 km run plays in 28 s), slowing toward 8 s/km as you zoom in.

## 2.11.0+1178 (2026-06-21)

### Security & Reliability

- **Sensitive credentials moved to secure storage**: the device **reset code** and
  **qrSecretCode** now live in the iOS Keychain / Android encrypted storage instead
  of plain app storage. Existing installs are promoted automatically on first boot
  (the imprint "Storage" line now reads *encrypted*). _Non-sensitive configuration
  stays in standard storage for speed; the device secret follows in a 2.11.x update._
- **Self-healing recovery**: a reset keeps only the reset code (the recovery key)
  in the keychain; on reboot the app re-authorises itself automatically — fresh
  device registration and a clean data reload — with no user input. A full reload
  is now a reliable way to recover from data corruption.
- **One unified reset flow**: *Reload data*, *Log out* and the major-DB-upgrade path
  now share a single wipe-and-reboot routine.
- **Wipe guard**: a full reload is blocked unless the backend is reachable all the
  way to the database, so the app can never wipe itself into an unrecoverable state.
  Re-authorisation failures always fall back to a manual login — the app can't brick.

## 2.10.7+1177 (2026-06-20)

### Improvements

- **Live run map — overlapping check markers merged**: when several runners mark
  the same point (e.g. a check), the duplicate markers now collapse into one
  instead of stacking.
- **Live run map — tap a mark to see who reached it**: tapping a trail mark lists
  every runner whose track passed within range of that point and when they got
  there. Runners who "checked" — ran ≥50 m out from the mark and back — are
  flagged with a 🔍 badge and sorted to the top.

## 2.10.6+1176 (2026-06-20)

### Fixes

- **Offline pull-to-refresh no longer empties the runs list**: refreshing with no
  connection now shows a "No Connection" message and keeps your runs. A refresh
  that reaches the network but fails partway also rolls the list back, so it is
  never left empty.
- **Runs-list jitter on update**: stable list keys plus a per-run controller
  cache stop rows rebuilding/flickering each time the data refreshes.
- **"Run changed" flash on background updates**: a run whose data changes via a
  notification or the cold-start background sync now flashes its card, not just
  on a tab switch.

## 2.10.5+1175 (2026-06-20)

### Improvements

- **Faster cold launch**: Returning users go straight to the runs list on app
  start — the "Filling Your Mug" loading screen is now skipped entirely when
  cached runs exist, with the full data sync running in the background. (First
  launch with no cached data still shows the loading screen during initial sync.)
- **Live-run GPS tiers retuned**: Power Saver is now 20 m / 15-min updates (was
  30 m), Balanced is 10 m / 1-min updates (was 15 m / 15 s) — a clearer
  battery-vs-accuracy progression across Best, Balanced and Power Saver on Android.

### Fixes

- **TestFlight export compliance**: Set `ITSAppUsesNonExemptEncryption` so new
  builds skip the manual encryption-compliance prompt on upload.

## 2.10.4+1174 (2026-06-19)

### New Features

- **Background sync UX**: Runs list now shows cached data immediately on launch (no loading screen if data exists). A banner slides in from the top when a background sync is in progress and slides away when complete. If new runs arrived above the current scroll position, a pill appears ("↑ N new runs") to scroll back to the top. Cards that change while on screen flash briefly with a tint overlay. Syncs trigger automatically when switching to the runs tab (1-min debounce) or when the app returns from the background.

## 2.10.3+1173 (2026-06-18)

### New Features

- **Location lookup in edit run screen**: Search button on the location description field opens a gazetteer (place search) bottom sheet. Pick a result to auto-fill street, city, region, postcode, and country fields, and re-centre the map.

### Fixes / Improvements

- **Multi-run check-in dialog**: Added save/cancel buttons; RSVP-No responses no longer shown in the list
- **Service registrations**: Guarded against duplicate GetX service registrations on hot-restart
- **Cleanup**: Removed dead Facebook visit-event asset

---

## 2.10.2+1172 (2026-06-11)

### Improvements

- **Connectivity**: Complete rewrite of offline/server detection. The app now
  polls the HC backend at boot to wake the server; a 30-second background
  watchdog detects mid-session outages (e.g. entering a tunnel); a fast
  recovery watcher (~5s) detects when connectivity is restored without
  polling the backend; API failures trigger an immediate backend check with
  appropriate ribbon feedback (Offline vs Server Unavailable).
- **Run Admin**: Buttons arranged in rows of 3 with category headings
  (On the Day, Before On Out, The Write-Up); partial rows and icons centred.

## 2.10.1+1171 (2026-06-10)

### Fixes

- **Startup crash on iOS 26.2 beta**: Fixed crash caused by an `objective_c`
  package path-join bug (9.3.0 → 9.4.1 via dependency_overrides).
- **Notifications not working after fresh install**: Firebase was never
  initialised before `initServices()` ran, so `NotificationService` never
  registered. Firebase is now initialised in `main()` before any services start.
- **PackTrack: distance underestimated on Low Power Mode**: GPS accuracy
  threshold raised from 15m to 50m. iOS Low Power Mode reports 30–50m accuracy
  — the old threshold filtered out those points and replaced them with straight
  lines, causing the track to miss turns and undercount distance by ~50%.
  The velocity filter (5 m/s) still catches genuine GPS jumps.
- **Song sync: most users silently throttled**: iOS throttles silent (data-only)
  pushes to ~3/hour. Users with default notification settings were getting
  data-only pushes and missing most song selections. All song notifications are
  now visible pushes (banner suppressed while the app is in the foreground).
  Muted users are excluded unless physically checked in at the run
  (attendanceState 20–39).
- **Song sync: tapping notification didn't enter listening mode**: Tapping a
  "🎵 Song Time!" banner while the app was backgrounded opened the songbook
  but didn't highlight the song or enter interactive mode. Fixed.
- **Song sync: reliability improvements**: Prevented double-registration of
  NotificationService at boot; fixed subscription leak across logout/login cycles.

### Improvements

- **Edit Charge: photo support**: Charges can now have a photo attached.
  Photo capture UI added to the charge editor; label and layout fixes.

---

## 2.9.8+1163 (2026-06-07)

### New Features

- **Full-screen photo viewer**: Tapping a photo in the Photos tab now opens a swipeable full-screen viewer. Swipe left/right to move between photos. The page title shows the run name and photo position (e.g. "Away Weekend Hash Olympics (3 of 21)"). Long captions can be dragged upward over the photo; the image darkens progressively with a 50% black overlay as the caption expands. Photographer name and avatar appear in the top-right corner for photos taken by other members.
- **Photographer credit**: When viewing a photo taken by another member, their display name and avatar appear in a rounded chip (8px corner radius) at the top-right of the full-screen viewer.

### Improvements

- **Run tracker: combined runner + timeline panel**: The two-tab carousel on the run tracking map has been replaced with a single panel. A slot-machine scroll picker (runner's colour dot, avatar, and name) sits above the timeline controls, so you can select a runner and see their stats in one view without switching tabs.
- **Photo separation**: Photos in the full-screen viewer are visually separated — a gap is visible between pages when swiping.
- **Tab bar**: The run detail tab bar (Details / RSVP / Map / Stats / Chat / Photos) is now evenly distributed across the full width of the screen instead of left-aligned.
- **Removed duplicate Songbook shortcut**: The music note icon in the Hash Runs app bar has been removed — the Songbook is accessible via the bottom navigation bar.

### Fixes

- **Photo caption Clear button**: The Clear button in the Hash Flash approval caption editor now correctly shows white text on a red background.

---

## 2.9.7+1162 (2026-06-06)

### New Features

- **Run photo gallery**: A new "Photos" tab appears on the run detail screen
  (both the guest view and the authenticated user view). Approved photos appear
  as a 3-column grid. Pull down to refresh for the latest photos. Guests see
  Hash-Flash-approved photos; authenticated users also see their own private
  photos with a lock badge.
- **Photos tab on guest run detail**: The guest run detail screen now has three
  tabs — Details, Map, and Photos.

---

## 2.9.6+1161 (2026-06-06)

### Fixes

- **RSVP state lost on scroll**: After RSVPing for a run, scrolling it off
  screen and back again no longer reverts the RSVP icon to unselected. The
  underlying model is now kept in sync with the controller so the widget
  re-initialises correctly when recycled by the list.
- **Guest filter chips**: Removed purple background behind the pinned filter
  chips on the Hashes Around the World screen.

### Improvements

- **Guest filter chips 30% larger**: Chip padding, icon sizes, and font size
  all scaled up for easier readability and tapping.

---

## 2.9.5+1160 (2026-06-05)

### Fixes

- **Stats tab no longer hangs on empty kennel**: When a kennel has no run
  history the Stats tab now shows "No history" instead of an infinite spinner.
- **Find My Account keyboard**: The keyboard no longer opens automatically
  when the page loads, so all buttons are visible on arrival.
- **Find My Account — removed redundant text**: "Already have an invite code?"
  label removed; the button label is self-explanatory.

### Improvements

- **Guest action bar — single button**: The two-button "Create account / Log In"
  layout is replaced with one green "Create your free account or Log In" button
  that takes guests straight to the account search screen.
- **Guest discovery title**: Renamed "Runs Around the World" to "Hashes Around
  the World".
- **Multiple pinned guest filters (up to 5)**: Guests can pin multiple search
  terms; each appears as its own chip with an individual × to remove it.
- **Larger pin icon and chip text**: Pin icon in the search bar is now 28px;
  chip labels are 15px.

---

## 2.9.4+1159 (2026-06-05)

### Improvements

- **Multiple pinned filters (up to 5)**: Guests can now pin multiple search
  terms (e.g. "London" and "Paris", or "BMPH3" and "CityH3"). Each pinned
  term appears as its own chip with an individual × to remove it. A run is
  promoted to the top section if it matches any saved term. The pin icon in
  the search bar dims when all 5 slots are used.
- **Larger chip text**: The pinned-filter chips now use 15px text for easier
  readability.

---

## 2.9.3+1158 (2026-06-05)

### New features

- **Guest saved home search**: Guests can pin a search term (e.g. "London") from the
  search bar. Pinned runs appear first in the list under the active kennel; a divider
  and "Other runs" section follow. The saved term persists across app restarts and can
  be cleared with the × chip in the header.

### Improvements

- **Guest run detail — Details / Map tab bar**: The run detail screen for guests now
  has two tabs. "Details" shows the existing label/value layout; "Map" shows the run
  location on an interactive map with a "Get Directions" button that opens the device's
  preferred maps app.
- **Guest action bar — "Log In" text now visible**: The "Already have an account? Log
  In" row was nearly invisible on some devices because the container was transparent
  against the system background. The bar now uses a solid app-bar colour.
- **Use Invite Code layout**: The "Get Started!" button has moved inside the yellow
  invite-code box. The "Email me a new invite code" and "I didn't receive an email"
  actions have moved below the box as full-width elevated buttons, matching the overall
  button style.
- **Event images on guest run cards**: Reverted the previous cap — event images now
  render at their natural height as intended.

---

## 2.9.2+1156 (2026-06-05)

### Fixes

- **Guest run cards — event images now constrained**: Event images on the discovery
  screen were rendering at full native height, causing some cards (especially those with
  map or photo images) to take up the entire screen. Images are now capped at 160px tall
  and cropped to fill the width.

---

## 2.9.1+1155 (2026-06-05)

### Improvements

- **Guest run cards match the main app**: Run cards on the "Runs Around the World"
  discovery screen now use the same white card style as the main app — kennel logo,
  dark-blue kennel name, run number and day offset, date/time, hares, and location,
  all with identical typography and layout.
- **Guest run detail page redesigned**: The run detail screen for unregistered users
  now matches the main app's layout exactly — large event image (or kennel logo
  fallback), centred event name, two-column label/value rows with golden labels and
  white values, FancyDivider section separators, and a "Share Runs" button at the
  bottom.
- **Guest action bar redesigned**: The two-button "Log In / Create Account" bar is
  replaced with a single full-width green promotional button ("Create your free account
  now") with an "or" / "Log In" text link underneath, making the primary CTA more
  prominent.
- **Find My Account button polish**: The secondary action buttons ("I have an invite
  code", "I definitely don't have an account") are now solid elevated buttons using the
  app-bar colour rather than transparent outlined buttons.
- **Use Invite Code button polish**: The "Email me a new invite code" and "I didn't
  receive an email" actions are now elevated buttons (red primary, grey secondary)
  replacing the previous flat text buttons.

---

## 2.8.2+1153 (2026-06-05)

### New Features

- **Find My Account — new onboarding flow for users who don't have (or aren't sure
  if they have) an account**: Both the "No" and "I don't know" paths on the account
  question screen now lead to a dedicated search page. The user enters their hash name
  or last name; the server searches for matching hashers within 500 miles (using GPS
  first, IP geolocation as fallback, or no filter if neither is available). Matches are
  grouped by hasher and shown as cards displaying name, photo, and kennel run history so
  the user can identify themselves. Selecting their card sends their invite code to the
  email address on file — no email address is ever returned to the client.
- **Find My Account — single result auto-selected**: When the search returns exactly one
  matching account the card is pre-selected automatically so the user can proceed without
  an extra tap.
- **"I didn't receive an email" help page**: A new link on the Enter Invite Code screen
  takes users who never received their code to a guidance page covering spam-folder
  checks, the wrong-email-on-file scenario, and a pre-filled Contact Us email.

### Improvements

- **Song share recipient count**: The "Song shared" snackbar now shows the number of
  pack members who will receive the notification (e.g. "Song shared with 14 pack
  members") instead of generic text.
- **Find My Account UI polish**: The success snackbar is now teal to distinguish it from
  the green confirm button. The "None of these are me" escape hatch is now a full-width
  outlined button matching the styling of other secondary actions.

---

## 2.8.1+1152 (2026-06-03)

### Fixes

- **Interactive Songbook — re-selecting the same song now triggers a live update**: The
  `SongSessionNotifier` persists across songbook sessions within an app run. GetX only
  fires `ever()` when a value changes, so selecting the same song twice in a row left
  `pendingSongId` unchanged and the update was silently swallowed. A null-bounce before
  assigning the new song ID forces the worker to fire every time, regardless of history.
- **Foreground notification banner suppression**: Added
  `setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false)`
  so that when visible song pushes are re-enabled (currently disabled in the API during
  development), iOS will not show a system banner while the user is already in the app.
  `onMessage` still fires and the songbook updates via the in-app listening mode banner.

---

## 2.8.0+1151 (2026-06-03)

### Fixes

- **Interactive Songbook — real-time update now works**: Five bugs identified
  and fixed that were preventing the song from switching live when the
  songmeister taps Share Now:
  - The notification handler was awaiting an unnecessary badge-count HTTP
    round-trip before dispatching song messages, delaying or blocking the
    update entirely. Song notifications now bypass this and dispatch
    immediately.
  - The FCM listener worker (`ever()`) was registered asynchronously after an
    `await`, leaving a brief window where a push could be missed. It is now
    registered synchronously in `onInit` and properly stored and disposed.
  - The controller tag was using the raw (possibly uppercase) event ID from
    the database; the notification service always uses lowercase. The mismatch
    caused a spurious "Go to song" toast to appear even when the user was
    already on the correct Songbook page, and tapping it pushed a duplicate
    page. Tag is now always normalised to lowercase.
  - The songmeister's display name was being read before it was written,
    showing "Someone" instead of their hash name. Assignment order corrected.
  - Stale FCM tokens were not being cleaned up when Firebase returned
    `UNREGISTERED` or `NOT_FOUND` errors (the FCM v1 API codes). These are
    now caught alongside the existing checks.

---

## 2.7.9+1150 (2026-06-02)

### Improvements

- **Interactive Songbook — real-time fix**: Song now switches immediately when
  the songmeister taps Share Now. The previous build was missing the EventId
  and SongId from the FCM payload, so the live update never fired. Fixed
  server-side; no app code change required, but this build picks up the
  companion Flutter changes below.

- **Interactive Songbook — in-app toast**: When a song is shared and you are
  not currently on the Songbook screen, a green banner appears at the top of
  the screen: "X is leading Y — Go to song". Tapping Go to song opens the
  Songbook directly for that event.

- **Interactive Songbook — notification tap**: Tapping a visible song push
  notification opens the app directly to the Songbook for the relevant event.

- **Interactive Songbook — proximity on boot**: If you open the app within
  500m of a run where a song has been shared in the last 5 minutes, the app
  navigates directly to the Songbook on first load — even if you haven't
  RSVP'd to the event.

- **Interactive Songbook — checked-in users**: Hashers who are checked in to
  a run (not just RSVP'd) now receive song push notifications.

---

## 2.7.8+1149 (2026-06-02)

### Features

- **Interactive Songbook**: Any RSVP'd attendee can share the current song
  with the whole pack in real time. Tap the music note icon on the Future Runs
  page (or use the new Songs tab in Live Run Tools) to open the songbook in
  event mode. Select a song, tap **Share Now**, and all other RSVP'd devices
  receive a silent push that instantly switches them to that song in listening
  mode. Devices that open the songbook within 2 minutes of a share
  automatically jump to the active song (pull-on-open). A green listening
  banner shows who is leading, with a **Stop** button to return to free browse.

- **Onboarding: "Do you already have an account?" screen**: New first-run
  screen after permissions asks whether the user has an existing Harrier
  Central account. **Yes** goes straight to the invite code page, **No** goes
  straight to create account, and **I don't know** opens a guidance page
  explaining how to find out and providing both forward paths.

---

## 2.7.7+1148 (2026-06-02)

### Fixes

- **Kennel page: "not authorised to access kennel" for non-admin members**:
  `KennelAdminController` was unconditionally calling the kennel admin sync SP
  and the auto-follow guard on every kennel page open, regardless of whether
  the user held admin rights. Non-admin users now skip the admin sync entirely.
  The upcoming runs list is read from the common domain for non-admins, and
  from the kennel domain for admins — the displayed content is the same either
  way.

---

## 2.7.6+1147 (2026-06-02)

### Improvements

- **RSVP tab offline behaviour**: The RSVP pack list is now visible when the
  device is offline, showing the last-synced attendee data from the local
  cache. The RSVP action buttons (Going / Maybe / Not going) and the speed
  dial FAB desaturate when offline to signal they require a connection, but
  the list of who else is going remains readable at all times.

- **RSVP table cleanup on navigate-away**: The local event RSVP table is now
  cleared when leaving a run's detail page, preventing stale attendee data
  from a previous run from briefly appearing when opening a different run.

---

## 2.7.5+1146 (2026-06-02)

### Fixes

- **RSVP tab: "not authorised to sync admin data" for non-admin members**: The RSVP
  tab was unconditionally calling the admin event sync SP, which requires kennel
  admin rights. Non-admin members now use a new dedicated SP (`hcapp_getEventRsvps`)
  that returns the full RSVP pack list without requiring admin access. Contact
  information (email, phone) and admin-only data (payments, kennel roles, receipts)
  are not included in this response. Admin users continue to use the full admin sync
  as before.

---

## 2.7.4+1145 (2026-06-01)

### Fixes

- **Boot crash: `DeviceInfo not found`** (`[ERROR][ASYNC]`): `AppLifecycleController`
  is registered before `DeviceInfo` in `initServices()`. Its `onResumed()` callback
  can fire between `await` points and register `LocationService` before `DeviceInfo`
  is ready. Added a `Get.isRegistered<DeviceInfo>()` guard in
  `LocationService.subscribeToGeoLocationStream` and a duplicate-registration guard
  in `AppBootService._prepareDeviceContext`.

- **`approveLogin` errorType:11 cascade** (7 × errorType:3 sync failures on boot):
  `checkHttpPostResponse` checked HTTP status before checking for `"errorId"` in the
  body. `AppApiHC6` returns 400 for all SP errors, so the status check short-circuited
  before `errorCallback` was called. `_isReauthorizationError` was never reached,
  `_handleDeviceNoLongerRegistered` was never triggered, and the boot fell through to
  `_handleNoConnection` — navigating to `MainNavigationPage` with stale credentials,
  which immediately fired all sync calls. Fixed by checking `"errorId"` first; also
  handles the flat JSON error shape that `AppApiHC6` returns for detected SP errors.

- **Device re-registration dialog**: replaced `Utilities.showAlert` with a custom
  dialog that includes a "Copy device credentials" button (copies `deviceId` +
  `deviceSecret` to clipboard) to aid server-side diagnosis when the error recurs.

- **Device-not-registered telemetry**: `_handleDeviceNoLongerRegistered` now fires
  an immediate `recordClientErrorLog` before clearing prefs, capturing the stale
  `deviceId`, `userId`, and `hcVersion` in `HC.ClientErrorLog` for pattern analysis.
  `hcapp_logClientErrors` updated to accept unregistered devices (previously rejected
  them, making it useless for exactly this failure mode).

---

## 2.7.3+1144 (2026-06-01)

### Features

- **Configurable trail marking symbols**: The 12 trail map buttons in the live
  run screen are now configured per kennel, editable by admins via the new Trail
  Symbols tab in the portal Edit Kennel page. Each slot can have any of the
  available symbol images, a kennel-specific name (shown in the confirmation
  flash), and an optional action (Add Text, End Run). Empty slots are not
  rendered. Kennels with no saved configuration use the existing 12 defaults.

- **Symbol image library**: Trail marker PNGs are now published under a numbered
  scheme (`I-001.png` through `I-012.png`) to allow future expansion up to 999
  symbols without app updates.

### Fixes

- **Kennel admin sync crash** (`type 'Null' is not a subtype of type 'num'`):
  `hcapp_syncKennelAdminData` was missing `disseminateAllowWebLinks` from its
  kennel rowset. The field was always absent; the crash only surfaced now because
  editing trail symbols via the portal updated the kennel's `updatedAt`, causing
  the admin sync to re-fetch that record for the first time.

- **Sync `FormatException: Unterminated string`**: The base sync library used a
  regex (`\[(\{(.*?)\})\]`) to split multi-result-set API responses. The
  non-greedy `.*?` stopped at the first `}]` sequence — which appears literally
  inside JSON-typed column values like `trailSymbolsConfigJson`. Replaced with
  `jsonDecode` on the full `[[...]]` response; handles embedded JSON arrays
  correctly. Fixed in `ive_flutter_core_mobile`.

### Internal

- SQLite migration 522: `ADD COLUMN trailSymbolsConfigJson TEXT` on `common_kennels`
- `DB_VERSION` bumped to 522
- `ive_flutter_core_mobile` bumped to `eefbbc1` (JSON result-set parser fix)
- `hcapp_syncUserData` and `hcapp_syncKennelAdminData` kennel rowsets include `trailSymbolsConfigJson` and `disseminateAllowWebLinks`

## 2.7.2+1143 (2026-05-31)

### Fixes

- **Logout now reliably restarts the app**: Replaced `Get.offAll()` with
  `restartKey.currentState?.restartApp()` in the logout handler.
  `Get.offAll()` ran a route transition animation during which
  `MainNavigationPage.build()` fired and recreated a permanent
  `MainNavigationController` — causing `onInitAsync()` to run with cleared
  credentials and then be reused by the next session, skipping the initial
  data sync. `restartApp()` tears down the widget tree via `dispose()` (no
  build pass) so no stale controller is ever created.

- **`database_closed` after logout**: `setupDatabase()` called
  `Get.delete<Database>()` to evict the old DB handle before opening a fresh
  one, but the handle was registered as `permanent: true`, so GetX silently
  ignored the deletion and `Get.putAsync<Database>()` returned the existing
  closed handle. Changed the call to `Get.delete<Database>(force: true)` so
  the permanent flag is bypassed and a genuinely fresh connection is always
  opened.

## 2.7.1+1142 (2026-05-30)

### Fixes

- **Logout now clears keychain**: "Log out of Harrier Central" and "Delete
  Account" now wipe the device reset code from the iOS keychain in addition to
  GetStorage. Previously the reset code survived logout; on the next boot
  `_handleDbUpgrade` found the old user's code in the keychain and silently
  re-authorised as them, causing the previous profile to reappear after restart.

- **Run tabs — badge null-guard and tab indicator**: Replaced the
  `TextScaleFactorClamper`/`GetBuilder` wrapper on the chat tab with a plain
  `Container`. The unread-message badge now guards against `NotificationService`
  not being registered (was a potential crash) and simplifies the count check.
  Added `indicatorPadding` to the tab bar for tighter visual fit.

### Internal

- **Session A test infrastructure**: Added `mockito`, `sqflite_common_ffi`, and
  `fake_async` dev dependencies. Added `parseBitField()` utility
  (`lib/util/bit_utils.dart`). Added `test/helpers/mock_http_client.dart` and
  `test/helpers/sqflite_ffi_setup.dart` as scaffolding for Session B widget
  tests. Fixed `setupTestEnvironment()` to initialise the default GetStorage
  container and the Flutter test binding for plain `test()` functions.
  Added 27 unit tests: UUID normalisation (13), BIT field parsing (7),
  `currentUserId` safe fallback (5), `isAtRunStart` throttle (2).

## 2.7.0+1141 (2026-05-30)

### Features

- **Hash Flash caption editing**: The photo review screen now lets the Hash
  Flash add, edit, or clear captions on any photo — not just those the uploader
  already captioned. A pencil icon and tap target are always visible at the
  bottom of each photo. Tapping opens an editor with a live 200-word counter
  and a Clear button. Any queued status decisions are flushed before the caption
  is saved so no review work is lost.

- **Caption on map photo view**: Tapping a photo marker on the run map now
  shows the caption (if one exists) below the full-screen image. Long captions
  scroll within a capped area; safe-area padding ensures the text clears the
  home indicator on all devices.

- **Photo review — smart tab**: The review screen now opens directly on the
  Reviewed tab when all photos for a run have already been actioned, so the
  Hash Flash lands on useful content rather than an empty pending state. The
  same logic applies on every refresh.

- **Status badge always colored**: The per-photo badge in the review screen
  now shows the current status in its action color at all times — grey for Keep
  Private, red for Deleted, green for Share/Gallery, teal for Home/Cover. The
  previous grey styling for already-committed statuses was confusing because
  it looked unsaved; the color now matches the action buttons directly below.

### Fixes

- **PackTrack live positions**: GetPositions requests now include the required
  `X-Api-Key` header. The live position feed was silently failing for all
  viewers since the API was secured, making PackTrack appear broken even when
  running correctly.

- **Map FAB restored**: The floating action button on the global map (Explore
  tab) had gone missing after a navigation refactor. Restored.

- **DB version mismatch**: A version mismatch between the local database and
  the expected schema now shows an explanatory dialog and triggers a clean warm
  reload rather than leaving the app in a silent inconsistent state.

- **Notification guard**: Notification handlers now check whether their target
  controllers are registered before calling `Get.find`. Previously a
  notification arriving on a cold launch could throw if the destination screen
  had never been opened.

---

## 2.6.8+1140 (2026-05-29)

### Security

- **Secure storage migration**: Device reset code is now stored in the iOS
  Keychain / Android Keystore (hardware-backed encrypted storage) instead of
  plain local storage. All existing users are migrated automatically on first
  launch — the app re-stages itself from the server with no manual action
  required.

- **API key protection**: IP geolocation lookup now proxied through the HC
  API — the IPInfo token no longer appears in the app binary.

- **Token redaction**: Device tokens and IDs are now redacted from any
  diagnostic logs before they are persisted or sent to the server.

- **HTTPS enforcement**: Payment provider links now require HTTPS — plain HTTP
  payment URLs are rejected.

- **GPS log guard**: Last-known device coordinates are no longer written to the
  on-device debug log in release builds.

## 2.6.7+1139 (2026-05-28)

### Improvements

- **Permissions — Manage Songs**: The "Manage Songs" permission (`authCanManageSongs`)
  is now available in the HC permissions popup, allowing it to be granted or
  revoked per member.

### Fixes

- **UUID comparisons**: Three kennel/event UUID comparisons now normalise both
  sides to lowercase before comparing. SQL Server returns UUIDs in uppercase;
  comparing without normalisation silently returned false, causing kennel
  matching and event lookups to fail intermittently.

- **Photo upload — domain validation**: The SAS token URL returned by the API
  is now validated against `harriercentral.blob.core.windows.net` before any
  upload is attempted. An invalid or tampered URL shows an error instead of
  uploading to an unintended destination.

- **Auth — device secret guard**: The device secret is now checked for null/empty
  before building an auth token in the login approval flow. Previously a missing
  secret would silently produce a token built from the sentinel value `'<none>'`.

---

## 2.6.6+1138 (2026-05-28)

### Features

- **Photo captions**: Users can now add an optional caption (up to 200 words)
  when capturing a run photo. The caption is stored in the DB and displayed as
  an overlay at the bottom of the photo in the Hash Flash review screen. A live
  word counter is shown beneath the caption field; text is trimmed to 200 words
  on save if the limit is exceeded.

---

## 2.6.5+1137 (2026-05-27)

### Features

- **Kennel screen — status filter**: Defunct and Inactive-Hidden kennels are
  now hidden from the Kennel list. Run history is unaffected — all runs remain
  visible regardless of kennel status.

### Improvements

- **PackTrack — spiderfy overlapping markers**: Co-located trail markers on the
  live run map are now fanned out so each is individually tappable.

- **PackTrack — background flush timer restored**: The GPS point upload buffer
  now correctly flushes on a 60-second background timer. HTTP timeout and
  Android position interval were also corrected.

### Bug fixes

- **Chat — fix double-tick race**: `chatController.updateMessage` in
  `handleSendPressed` is now awaited, so the message reaches `sent` status
  before any FCM echo arrives and tries to upgrade it to `delivered`.

- **Boot — device no longer registered**: When `hcapp_approveLogin` returns
  an auth error for a deleted device, the app now shows a friendly dialog
  and silently re-registers using the stored reset code rather than
  displaying a toast and freezing on the splash screen.

- **Run details — stale controller reuse**: `RunDetailsController` is now
  tagged by `eventId`, preventing a cached instance for a previous run from
  being served when navigating to a different run.

## 2.6.4+1136 (2026-05-26)

### Improvements

- **Chat — FCM-only delivery**: Chat updates are driven exclusively by FCM
  triggers. Removed the background polling timer that was previously running
  while the chat page was open.

- **Chat — pending fetch queue**: If an FCM arrives while a delta-fetch is
  already in flight, a follow-up fetch is queued rather than dropped.

## 2.6.3+1135 (2026-05-26)

### Improvements

- **Chat — FCM-only delta-fetch**: Polling timer disabled; chat message updates
  are now triggered exclusively by incoming FCM pushes, reducing unnecessary
  background network activity.

- **Chat — pending fetch queue**: If a delta-fetch is already in flight when an
  FCM message arrives, the request is queued rather than dropped, ensuring no
  update is missed during rapid message sequences.

### Bug fixes

- **Profile — camera behavior switch**: Fixed UX issues with the camera behavior
  toggle control.

## 2.6.2+1134 (2026-05-24)

### Features

- **Chat — unread tracking**: Opening event chat now marks all messages as read
  server-side and fans out a silent `read_sync` FCM push to the user's other
  devices, zeroing badge counts immediately.

### Improvements

- **Chat — 2.x UI framework**: Migrated from `flutter_chat_ui` 1.x to 2.x
  (`flutter_chat_ui ^2.11.1` + `flutter_chat_core ^2.9.0`). Chat messages are
  now managed via `InMemoryChatController`; group avatars and sender names are
  rendered using the 2.x custom builder API matching the portal's chat UI.

- **Chat — FCM subscription moved to controller**: Incoming FCM chat messages
  are now handled directly by `ChatPageController` via its own subscription
  rather than being routed through `NotificationService`.

- **Chat — UUID normalisation**: Author and message IDs are now normalised to
  lowercase via `.asUuid` (was `.toUpperCase()`), consistent with project
  conventions.

- **Chat — named constant for releasability flags**: `messageReleasabilityFlags`
  value replaced with `kChatReleasabilityAll` constant.

- **Chat strip — decoupled from chat package**: `ChatStripWidget` no longer
  depends on `flutter_chat_types`; uses a lightweight internal model for the
  summary display.

- **Dead code removed**: `LiveRunChatController` stub class removed (was an
  empty wrapper around `LiveRunChatPage`). `visibility_detector` dependency
  removed.

## 2.6.1+1133 (2026-05-24)

### Bug fixes

- **Chat — message load crash**: `ChatPageController.onInit` no longer
  force-unwraps `publicHasherId` and `profilePhotoUrl`. If `publicHasherId`
  is absent the chat screen exits cleanly instead of crashing.

- **Chat — permanent loading spinner on server error**: An `HC_ERROR_` response
  no longer reaches `jsonDecode`, which would throw and leave `messagesLoading`
  stuck at true permanently.

- **Chat strip — permanent loading spinner on exception**: `ChatStripController`
  now wraps the load path in try/catch/finally, ensuring `isLoading` clears
  on any error path.

- **Chat — message status stuck at sending**: Sent messages now correctly
  update to `sent` (or `error` on failure) after the API call completes.

- **Chat — soft-deleted messages excluded**: Messages and authors marked as
  removed are now filtered from event chat results (HC6 SP).

- **Chat — send atomicity**: The message INSERT and badge-count MERGE are now
  wrapped in an explicit transaction; a partial-write state on badge failure is
  no longer possible (HC6 SP).

- **Chat — data-only push notifications now silent on iOS**: In-app chat
  messages no longer play a notification sound. APNS priority was incorrectly
  set to 10 for all FCM messages; data-only messages now use priority 5 with
  content-available (HC6 API).

- **Chat — releasability flags value in push**: `MessageReleasabilityFlags` was
  silently deserialising to 0 in the HC6 send path due to an HC5/HC6 column
  name mismatch; push notifications now carry the correct value (HC6 API).

- **Chat — SP errors now surfaced to caller**: HC6 error envelopes are detected
  before notification side-effects run; previously swallowed silently (HC6 API).

- **Chat — stale FCM token cleanup**: Removing a stale token no longer calls an
  HC5 internal SP; replaced with a direct UPDATE HC.Device (HC6 API).

## 2.6.0+1132 (2026-05-24)

### New features

- **QR codes — kennel website tab**: The QR code sheet now includes a dedicated
  "Website" tab when the kennel has a website URL configured. Scan to open the
  kennel's hashruns.org page directly. Available from both the run admin QR
  sheet and the kennel admin QR sheet.

### Improvements

- **Live run page — "Share Runs" button promoted**: The QR code button is now
  permanently visible in the right-hand column alongside "Take Photo", replacing
  the previous smaller outlined button below the marker grid. Makes the action
  easier to reach mid-run.

- **Live run page — consistent corner radii**: All interactive elements on the
  live run general tab (buttons, stat cards, photo button, chat strip) now share
  a uniform 12px corner radius.

- **Live run page — chat strip alignment**: The chat strip card now aligns its
  left and right edges with the rest of the page content, matching the Auto Pause
  and End Run buttons above it.

- **My Profile — "Camera Behavior" section**: The camera roll setting is now
  presented under a clear "Camera Behavior" heading with a descriptive subtitle,
  and the Switch has been restyled to match the page's existing layout pattern
  rather than using a highlighted SwitchListTile.

- **Error logging — BootLogger rollout**: `BootLogger.logError` now covers 25+
  previously silent catch blocks across services, database queries, admin pages,
  and the live run flow. Errors from these paths will appear in the diagnostic
  harvest log. Includes Apple sign-in exceptions, kennel photo upload failures,
  common query errors, and notification dispatch failures.

- **Boot logger — session start marker**: Each new session writes a `[STARTUP]`
  timestamp into the error log at the moment persistence begins, making it easy
  to identify session boundaries in harvested logs.

- **Boot logger — await previous session flush**: The previous session's error
  log is now awaited before starting the new session, ensuring clean hand-off
  between session logs.

- **Boot logger — global export**: `boot_logger.dart` is now re-exported from
  `imports.dart`, removing the need for individual imports across files.

## 2.5.4+1131 (2026-05-24)

### Bug fixes

- **Hash Flash — review flow rework**: Tapping an action button now records
  the decision and highlights the button without navigating away from the
  current photo. Swipe left/right (or the auto-advance after a tap) is now
  the only mechanism that moves between photos. This fixes two bugs: an
  instant photo-jump followed by a slide animation on the pending tab, and
  no-advance on the reviewed tab. Both were caused by the optimistic status
  update mutating the `allPhotos` list mid-flight, which rebuilt the
  `PageView` before `nextPage()` fired.

- **Hash Flash — save on exit only**: Removed the 5-second debounce
  auto-save. All decisions are now written as a single batch when the user
  leaves the page. Eliminates mid-session saves that were disrupting the
  `PageView` with a full reload at unpredictable moments.

- **Hash Flash — reviewed tab re-tag highlighting**: Tapping a different
  action on an already-reviewed photo now immediately highlights the new
  button. Previously the panel derived `selected` from the committed status
  only; it now checks the queued decision first.

- **UUID case fix — boot log flag**: The developer-only boot log flag in
  the drawer menu now compares against a lowercase UUID, consistent with the
  project-wide UUID normalisation convention. Fixes the flag never activating
  after `UuidValue` normalisation was rolled out.

### Improvements

- **Geocoding — "Pin location needed" dialog**: When auto-locate cannot
  find a specific enough location for an address, a dialog now appears
  explaining why and offering a direct "Go to Map" button to jump to the
  Map tab for manual pinning. Previously the flow failed silently.

- **Run admin button spacing**: Added horizontal spacing between action
  buttons in the run admin Wrap layout to prevent them from touching on
  narrow screens.

- **Migration archived**: `add_AssetId_to_KennelPhotos.sql` moved to
  `db/hc6/app/archive/` after having been run against the database.

## 2.5.2+1129 (2026-05-24)

### Bug fixes

- **Run admin button layout**: Restored the run admin menu to its correct
  appearance — buttons are fixed 110×110 tiles spaced evenly across the row,
  rather than expanding to fill the full column width.

- **Boot hang — isAtRunStart deferred**: `isAtRunStart` (which performs a GPS
  poll on run day) is now initialised after the app content is rendered,
  preventing it from blocking the boot sequence. GPS wait is also capped at
  30 seconds to avoid an indefinite hang on devices where location is slow
  to resolve.

### Improvements

- **Geocoding country fallback**: When the country field is blank in the run
  address form, the geocoder now looks up the kennel's registered country from
  the local database and uses it automatically. Prevents geocoding failures for
  kennels where no country has been typed in.

- **Auto-locate dialog after address save**: After saving an address in the run
  editor, a dialog now prompts "Would you like me to try to automatically find
  the map pin for the new address?" with "Not now" and "Auto-locate" options,
  replacing the previous snackbar action. Only shown when there is enough
  address data to attempt geocoding (postcode, or street + city).

- **Styled confirm dialogs**: The "Delete image" and address-save confirmation
  dialogs now use ElevatedButton widgets (teal for cancel/not-now, red for
  destructive actions) for clearer visual affordance.

- **[BOOT] instrumentation extended**: Boot timing markers now extend through
  to the point where app content is visible, giving a complete picture of the
  full startup sequence in the diagnostic log.

## 2.5.1+1128 (2026-05-24)

### New features

- **Copy boot log from My Profile**: A "Diagnostic Logs" section is now shown at
  the bottom of the My Profile page (accessible via the drawer menu). It contains
  a "Copy log to clipboard" button that captures the same `BootLogger` startup
  output as the boot-screen overlay, allowing the log to be retrieved after the
  app has fully loaded without needing to reproduce the boot sequence. The button
  is disabled if no log lines have been captured yet, and shows "Copied!" for two
  seconds after a successful copy.

## 2.5.0+1127 (2026-05-24)

### New features

- **Address-to-pin geocoding in run editor**: Addresses and map pins can now be
  kept in sync with one tap. In edit-run mode the address-saved confirmation
  snackbar includes a "Locate pin" action — tapping it calls the Nominatim
  (OpenStreetMap) geocoding API with the saved address fields and, if a match is
  found, jumps to the Map tab with the pin pre-positioned at the geocoded
  location. In new-run mode an "Auto-locate" button has been added to the Map
  tab's button row, so the user can position the pin from the address they just
  entered before confirming with "Set Location". A loading spinner shows during
  the geocoding call; a fallback snackbar is shown if the address cannot be
  located. No API key required.

- **Live run tracking — timing gate**: The "Start Run Tracking" button is now
  disabled until five minutes before the run's scheduled start time. When
  outside this window the button displays "Tracking opens at [time]" and is
  greyed out. A background timer polls every 30 seconds and enables the button
  automatically when the window opens, without requiring the user to leave and
  re-enter the screen.

- **Boot hang diagnostic — BootLogger overlay**: Added a temporary `BootLogger`
  utility that intercepts all `debugPrint` output from the moment `main()`
  starts. A scrolling overlay panel is shown on the splash screen and on the
  "Filling Your Mug" loading screen during boot, with a "Copy log to clipboard"
  button for capturing the sequence of startup events. This tool will be removed
  once the reported boot hang is diagnosed.

### Bug fixes

- **Delete event image — SP + service layer**: The "Delete image" button in the
  run image editor previously sent no instruction to the server, leaving the
  existing image URL in place. `hcapp_addEditEvent` now accepts a
  `@deleteEventImage BIT` parameter; when set, `EventImage` is explicitly
  cleared to `NULL` rather than left unchanged by the `COALESCE` fallback. The
  Flutter service layer passes `deleteEventImage: '1'` in the request body when
  the user confirms deletion.

## 2.5.0+1126 (2026-05-24)

### Bug fixes

- **Edit mismanagement roles / HC App permissions — silent failure**: Saving
  either of these fields called `hcapp_joinKennel`, which (when editing another
  user) delegates to `hcapp_syncKennelAdminData`. That SP updates `HC.Kennel`
  when roles change, which bumps the kennel's `updatedAt`. The subsequent sync
  returned a kennel row, and the ingestion engine matched it to
  `KennelsTableHelper` — but `KennelsTableHelper.getTableName(AppDomainType.kennel)`
  threw an exception because it only handled `AppDomainType.user`. The exception
  was caught in `_setUserProperties`, so the app didn't crash, but the save
  appeared to fail ("Could not save — check your connection") and kennel data
  was not written to the local DB. Fixed by making `KennelsTableHelper.getTableName`
  return `commonTableName` for all domain types — kennels are stored in a single
  shared table regardless of which sync domain is writing to them.

- **Success envelope printed as unrecognised data**: Write SPs (including
  `hcapp_joinKennel`) return a `[{"success":1,...}]` envelope at rowset 0
  before the sync data. The base ingestion engine (`updateSqlTablesFromJsonWithAdHocData`)
  did not recognise this as a known pattern, so it printed debug warnings for
  every write operation and the `adHocData` return value was lost (causing the
  wrong snackbar message even when the save succeeded). Fixed by adding
  `ServiceCommon.stripSuccessEnvelope()`, which removes rowset 0 when it is a
  success envelope before handing the response to the ingestion engine. Applied
  in all three sync service adapters: `SyncKennelAdminService`,
  `SyncUserDataService`, and `SyncEventAdminService`.

## 2.5.0+1125 (2026-05-23)

### Bug fixes

- **Future runs list — pull-to-refresh clears all runs**: Pulling to refresh
  called `refreshFromBackend(clearLocalTables: true)`, which wiped the local
  SQLite events/HEM/payments tables before fetching fresh data. The subsequent
  `syncUserDataService.updateFromBackend` call had a debounce guard that
  silently returned early when a sync had run recently — leaving the DB empty.
  `refreshFromTable` then queried that empty DB and rendered a "no runs" state.
  Fixed by making the debounce respect the `forceRefresh` flag. Additionally,
  the debounce has been removed entirely for now while the right threshold is
  determined.

- **Sync debounce — `forceRefresh` parameter ignored**: `forceRefresh: true`
  was accepted by `SyncUserDataService.updateFromBackend` but never consulted
  in the debounce check. All callers passing `true` (kennel admin, kennel list,
  hasher profile, future run list) were silently hitting the debounce anyway.
  The debounce now gates on `!forceRefresh`.

- **Sync debounce — reduced from 120 s to 30 s**: The 120-second guard was
  too aggressive; a normal user interaction can easily trigger a sync within
  that window. Reduced to 30 seconds to match actual quick-restart scenarios.

- **Manual check-in — stale hasher data on exit**: Navigating away from the
  manual check-in page now fires a background `syncUserData` against the
  hashers table, picking up any member profile changes (hash names, photos,
  membership state) that occurred during the check-in session.

---

## 2.5.0+1124 (2026-05-23)

### Bug fixes

- **Check-in popup — silent failure**: `setEventAttendence` returning an empty
  list (connectivity guard triggered, or SP error) was silently swallowed. The
  caller now shows a "Check-in failed" snackbar when the response is empty and
  a "Checked in!" confirmation when it succeeds, so the user always gets
  actionable feedback.

- **Mismanagement roles — no confirmation and silent save**: `updateHasherKennelStatus`
  was a mutation without `noRetries: true`, risking duplicate writes on retry.
  Added `noRetries: true`. After saving a mismanagement role or app-access
  change, a snackbar now confirms success or reports failure so the user knows
  the outcome without guessing.

- **Photo review — batch save error**: `updates` was sent as a JSON array in
  the HTTP body (`"updates":[...]`). The API shim passes this directly to the
  SP's `@updates NVARCHAR(MAX)` parameter, which expects a JSON *string*. Fixed
  by serialising to `jsonEncode(updates)` before including in the body so the
  SP receives a parseable JSON string.

- **Photo review — immediate save on last pending photo**: Previously the 5-second
  debounce always fired after every action. When the last pending photo is
  actioned and no pending photos remain, the queue now flushes immediately
  without waiting for the debounce. Actions are also blocked while a save is
  in progress.

- **KennelPhotos map — empty camera icon shown for private/unapproved photos**:
  Returning an empty camera-frame marker for photos that have no resolved URL
  (not yet approved for this viewer, or private) was confusing. The marker is
  now completely hidden (`SizedBox.shrink()`) when the URL cannot be resolved,
  so only photos the user is permitted to see appear on the map.

- **KennelPhotos map — zoomable photo page has black background**: Tapping a
  photo marker opened `ZoomableImagePage2` without a background, so
  `photo_view` defaulted to black. Now passes `Backgrounds.defaultHcBackground()`
  so the jungle theme is shown consistently.

---

## 2.5.0+1123 (2026-05-23)

### Stability

- **Boot hang — infinite sync paging loop**: `SyncUserDataService` uses a
  `while (tablesToSync != 0)` paging loop. If the base-service bitmask logic
  fails to clear a table bit when the SP returns 0 updated rows, the loop
  retries the same request forever, leaving the app stuck on the "Filling Your
  Mug" loading screen. Added a 100-iteration guard with a diagnostic log; the
  break covers both this scenario and any future edge case where the paging
  token is not correctly zeroed.

### Memory leaks — StatefulWidget disposal

Added `dispose()` to 12 State classes that were creating `TextEditingController`
and `FocusNode` instances without ever calling `.dispose()`. Each popup or page
shown and dismissed leaks one or more native text engine objects. Fixed:

- `widgets/multiple_choice_popup.dart` — FocusNode + TextEditingController
- `widgets/add_virgin_visitor_popup.dart` — FocusNode + 3× TextEditingController
- `widgets/email_popup.dart` — FocusNode + TextEditingController
- `widgets/confirm_auto_checkin_popup.dart` — FocusNode + TextEditingController
- `pages/init/third_party_login.dart` — 2× FocusNode + 2× TextEditingController
- `pages/init/create_new_account.dart` — FocusNode
- `pages/run_admin/create_new_event_popup.dart` — FocusNode + TextEditingController
- `pages/kennel_admin/run_number_popup.dart` — FocusNode + TextEditingController
- `pages/kennel_admin/kennel_members.dart` — AnimationController + FocusNode + TextEditingController
- `pages/run_admin/find_hasher_page.dart` — FocusNode + TextEditingController
- `pages/menu_pages/hasher_profile_page.dart` — 6× TextEditingController
- `pages/menu_pages/get_reset_code_popup.dart` — FocusNode + TextEditingController

All 25 GetX controllers were audited and confirmed clean.

---

## 2.5.0+1122 (2026-05-23)

### Security

- **KennelPhotos — photo URLs no longer stored in GPS track**: Previously the
  full Azure Blob Storage URL was embedded in every PHO GPS marker label,
  meaning anyone who could read the GPS track data could access photos directly
  and bypass status-based access control (private, deleted). The label now
  stores only the photoId UUID. The map controller fetches authorised URLs via
  `hcapp_getRunPhotos` on load and every 15-second auto-update tick, so only
  photos the caller is permitted to see resolve to a URL — private and
  soft-deleted photos show as empty camera frames.

### Bug fixes

- **KennelPhotos — map photos not loading after security fix**: The photo URL
  cache was reading rowsets at the wrong indices (`[1, 2]` instead of `[0, 1]`)
  because `hcapp_getRunPhotos` returns data as rowset 0 on success with no
  envelope. All six photos now load correctly.

- **KennelPhotos — map photo cache never populated**: `KennelPhotoService` is
  instantiated directly throughout the app and is not registered with GetX.
  `Get.find<KennelPhotoService>()` was throwing silently, leaving the cache
  empty. Fixed to use `KennelPhotoService()` directly, consistent with all
  other call sites.

- **KennelPhotos — soft-deleted photos visible on others' maps**: Photos with
  `Status ≥ 2` but a non-null `DeletedAt` were still returned to other users
  by `hcapp_getRunPhotos`. Added `DeletedAt IS NULL` filter to the others'
  public photos rowset.

---

## 2.5.0+1121 (2026-05-23)

### Improvements

- **KennelPhotos — instant review with queued batch upload**: Actions in the
  photo review screen now apply immediately to the UI with no network wait.
  Changes are queued locally and flushed to the server in a single batch call
  after a 5-second pause in activity. Navigating away triggers an immediate
  flush with a "Saving…" progress indicator in the app bar.

- **KennelPhotos — batch failure handling**: If the batch upload fails, all
  optimistically-applied changes are reverted to their previous statuses and a
  dismissable error dialog is shown. If a partial failure occurs (some photos
  not found or from a different kennel), the successful updates are kept and a
  warning is shown with the failure count.

- **KennelPhotos — delete confirmation pauses debounce timer**: The 5-second
  debounce timer is paused while the delete confirmation dialog is visible so
  the batch does not flush mid-dialog.

---

## 2.5.0+1120 (2026-05-23)

### New features

- **KennelPhotos — full photo review redesign**: Review Photos is now
  event-scoped (run admin only; removed from kennel admin). The screen
  shows a persistent header with the kennel logo, event name, and a
  colour-coded count chip for every status (Pending, Private, Shared,
  Run Gallery, Home Gallery, Event Cover, Deleted). Pending and Reviewed
  tabs let the Hash Flash switch between unactioned and already-actioned
  photos. The same action buttons work on both tabs — any action
  overwrites the existing status.

- **KennelPhotos — soft delete**: Deleting a photo now sets a `DeletedAt`
  timestamp instead of removing the row. Deleted photos appear in the
  Reviewed tab with a dimmed overlay. Any other action (Keep Private,
  Share, etc.) restores the photo and applies the new status.

- **KennelPhotos — re-review**: Previously approved photos can be
  re-actioned at any time from the Reviewed tab, overwriting the
  existing status in the database.

---

## 2.5.0+1119 (2026-05-22)

### Bug fixes

- **Run History — empty list when viewing another member's history**: Tapping
  "View Run History" on a kennel member's profile showed no runs. The sync
  wrote the selected user's HEM data to the kennel-domain table, but the page
  was querying the user-domain table. Fixed by deriving `AppDomainType` from
  `dataContext` so the query always hits the same table the sync wrote to.

---

## 2.5.0+1118 (2026-05-22)

### Improvements

- **KennelPhotos — photo fills camera frame**: The thumbnail now bleeds
  slightly beyond the transparent cutout so no background pixel is visible
  between the photo and the camera frame edge.

- **KennelPhotos — marker size scaling**: Minimum photo marker size raised
  from 25 px to 50 px. Markers now shrink on a quadratic curve as you zoom
  out, so they reduce in size faster while still reaching full screen width
  at maximum zoom.

- **KennelPhotos — tap to view full image**: Tapping a photo marker on the
  map opens the photo full-screen in the zoomable image viewer, with the
  event name shown in the app bar.

---

## 2.5.0+1117 (2026-05-22)

### New features

- **KennelPhotos — photo markers on the live run map**: PHO track points
  now render as camera-shaped map pin markers with the actual photo
  thumbnail displayed inside the camera LCD frame. Landscape photos use
  a wide camera frame; portrait photos use a tall frame — orientation is
  detected automatically from the image dimensions.

- **KennelPhotos — count-up loading indicator**: While a photo marker is
  loading its thumbnail (0–9 seconds), a counter is shown inside the
  camera frame so it is clear the image is in progress rather than
  broken.

- **KennelPhotos — zoom-responsive marker size**: Photo markers scale from
  a minimal 25 px at full-run view to approximately screen width at
  maximum zoom, making them easy to spot at a distance and large enough
  to inspect up close.

### Bug fixes

- **KennelPhotos — photo markers silently dropped by GPS filter**: Typed
  track points (PHO and all other marker types) were being removed by the
  GPS accuracy and velocity filter if their GPS fix was poor or their
  timestamp was within 1 second of the preceding point. Typed points now
  bypass all quality checks — they are intentional user actions and must
  always survive the filter.

- **KennelPhotos — PHO GPS label truncated at 54 characters**: The
  `StorePositions` API endpoint was silently dropping any `Type` field
  longer than 54 characters. PHO labels (which embed the full blob URL)
  are up to ~165 characters. Limit raised to 200.

- **KennelPhotos — photo URL correctly sourced from API response**: The
  full blob URL returned by `GetPhotoUploadToken` is now stored verbatim
  in the GPS track label, eliminating a storage-account-name assumption
  that could have broken thumbnail loading after an infrastructure change.

### Stability (pre-3.0 hardening — Session 1)

- **`isAtRunStart` throttle re-enabled**: The 2-minute rate-limit was
  accidentally left disabled by a `TODO: Re-enable before next release`
  comment. Without it, every screen unlock, boot, and 5 other call sites
  fired an unthrottled network + DB call.

- **GetX resource leaks — 8 controllers**: Added or completed `onClose()`
  in `OtherPaymentPopupController`, `CheckInPackController`,
  `KennelsListPageController`, `FutureRunListPageController`,
  `LiveRunGeneralController`, `LocationService`, `KennelAdminController`,
  and `MainNavigationPageController`. Resources leaked: `Worker` objects
  from `debounce()`/`ever()`, `TextEditingController`, `FocusNode`,
  `ScrollController`, `AnimationController`, `MapController`.

- **Sync service crash on first install**: All three sync services called
  `table.first['maxDate']` without an `isEmpty` guard. On a fresh install
  the table is empty, causing a `RangeError` that could hang the boot.

- **Email report HTTP calls had no timeout**: Four fire-and-forget email
  endpoints (`SendKennelRunStatsReport`, `SendRunCountsReport`,
  `SendPaymentReport`, `EmailInviteCode`) could hang indefinitely. Each
  now has a 30-second timeout.

### Stability (pre-3.0 hardening — Session 2)

- **59× `userId` force-unwraps replaced**: All `getStringPref(userId)!`
  force-unwraps across services, pages, and widgets have been replaced
  with a new `currentUserId` getter that returns `''` instead of throwing.
  This eliminates a class of crashes on first boot and after a credential
  wipe.

- **Mutations now use `noRetries: true`**: Payment, RSVP, attendance,
  event, receipt, and user-edit calls were retrying up to 6 times on
  network failure. This risked creating duplicate records in the database.
  All 10 mutation call sites now pass `noRetries: true`.

- **3× empty catch blocks**: Silent `catch (_) {}` blocks in
  `KennelsListPageController`, `HashFlashApprovalPage`, and
  `MainNavigationPageController` now log the error with `debugPrint`.

- **4× `DateTime.parse()` crash risk**: Unguarded parses on DB-sourced
  strings in `HashRunArtGalleryPage`, `RunLocationsController`,
  `RunTabs`, and `RunListItem` replaced with `DateTime.tryParse()` +
  safe fallbacks.

- **Unguarded array access hardened**: COUNT query results in
  `common_queries.dart`, double-nested JSON decode in
  `utilities_null_safe.dart`, `result[1][0]` in
  `authorize_device_service.dart`, and barcode scan `.barcodes.first`
  in three scanner pages now all have proper guards.

- **Photo upload token fields null-checked**: `sasUrl` and `blobUrl` are
  now validated before use in `kennel_photo_service.dart`; a clear
  snackbar is shown if either field is missing.

- **`recordError()` timeout added**: The error-logging HTTP call had no
  timeout and could block the app if the reporting endpoint was slow.
  Now capped at 30 seconds.

## 2.4.10+1116 (2026-05-21)

### Enhancements

- **KennelPhotos — post-crop sharing sheet**: After cropping a photo,
  a bottom sheet now asks what to do with it:
  - **Discard** — removes the photo, nothing is uploaded
  - **Save privately** — uploads and stores for the taker only
  - **Save and share** — uploads and forwards to the Hash Flash for review

  Previously the sharing preference was inherited from the user's saved
  setting. It is now always an explicit per-photo decision.

## 2.4.9+1115 (2026-05-21)

### Enhancements

- **KennelPhotos — run-scoped storage path**: Photos are now stored under
  `trail-photos/{kennelSlug}/{kennelSlug}-{runNumber}/{filename}` for
  numbered runs (e.g. `shhh/shhh-456/…`), or `trail-photos/{kennelSlug}/other/{filename}`
  when the run has no number. All photos from the same run land in the same
  Azure Blob Storage subfolder, making manual browsing and future bulk
  operations straightforward.

- **KennelPhotos — enriched PHO GPS marker**: The PHO track-point label now
  encodes the run folder and full blob filename
  (`<runFolder>/<userId>-<photoGuid>.jpg`) so the map renderer can locate
  the photo directly without a separate cache lookup.

## 2.4.8+1114 (2026-05-21)

### Developer experience

- **KennelPhotos — simulator support**: Running on the iOS or Android
  simulator no longer blocks at the camera step. When `isPhysicalDevice`
  is false the app loads the bundled splash-screen JPEG as a placeholder,
  then runs the full token → blob upload → database record flow as normal.
  No user-visible change on physical devices.

## 2.4.7+1113 (2026-05-21)

### Code quality

- **Sync services — dead code removal**: Removed a long-standing `if (true)`
  dead-code wrapper from all three sync services (`SyncUserDataService`,
  `SyncKennelAdminService`, `SyncEventAdminService`). The original cache-expiry
  condition was commented out years ago and replaced with an unconditional
  `if (true)` placeholder, leaving the entire method body unnecessarily
  nested. No behaviour change.

## 2.4.6+1112 (2026-05-21)

### Bug fixes

- **Boot hang — permanent loading screen**: Added try/catch to `onInitAsync()`
  and `setupDatabase()`. Previously, any unhandled exception inside the boot
  sync chain (malformed server data, SQLite error, network failure) was silently
  swallowed by `unawaited()`, leaving the loading screen displayed permanently
  until the app was force-killed. The app now falls through to offline mode
  with cached data instead.

- **Boot hang — `Ipify.ipv4()` timeout**: The IP-lookup call at login had no
  timeout. A slow or unreachable `api.ipify.org` response could block the
  entire login request indefinitely. Now capped at 4 seconds with a `0.0.0.0`
  fallback.

- **Photo upload — follower-only restriction removed**: Any authenticated
  Harrier Central user on a live run can now take and upload photos. The
  previous `Following = 1` check in `hcapp_getPhotoUploadToken` and
  `hcapp_addKennelPhoto` has been removed.

### Performance

- **Boot sync — O(N) SQLite reads eliminated**: The sync engine previously
  issued one `SELECT` per incoming record to check local existence (up to 2 500
  reads for the Hashers table). This has been replaced with a single batched
  `SELECT … IN (…)` query, chunked at 900 PKs per call. On a physical device
  with NAND flash storage, Hashers sync time drops from ~30–60 s to ~1–2 s.
  (Change is in the `ive_flutter_core_mobile` helper package v1.2.16.)

### Other

- **Sync debounce**: Raised from 5 s to 120 s. A 5-second window was
  effectively zero — every app relaunch re-synced all tables. Quick restarts
  (e.g. from Settings → Reload Data) now skip the expensive full sync while
  normal relaunches (minutes apart) still fetch fresh data.

## 2.4.5+1111 (2026-05-21)

### Enhancements

- **Photo review — 6-level approval scale**: The Hash Flash approval screen is
  replaced by a full **Photo Review** screen with two rejection options (Keep
  Private, Delete) and four escalating approval levels, each implying all
  levels below it:
  - **Share with Hash** — visible to all Harrier Central users on run maps
  - **Run Gallery** — also appears in the run's photo gallery
  - **Home Gallery** — also featured on the kennel home page
  - **Event Cover** — also set as the run's cover photo (`HC.Event.EventCoverPhotoUrl`)

- **Photo review — expanded reviewer roles**: The Review Photos button in the
  kennel admin page is now visible to Hash Flash, Grand Master, Vice-GM, and RA
  (previously Hash Flash only).

- **Photo upload — kennel slug folder**: Photos now upload into
  `trail-photos/{kennelSlug}/` in Azure Blob Storage rather than a UUID-named
  folder. The slug is resolved server-side so no app rebuild was required for
  the initial fix.

### Bug fixes

- **Photo upload — upload token error**: Fixed a 403 auth failure caused by the
  SP checking `IsMember = 1` (defaults to 0); relaxed to `Following = 1` so any
  kennel follower can take photos during a run.

## 2.4.4+1110 (2026-05-20)

### New features

- **KennelPhotos — photo capture during a live run**: Hashers can now take photos
  mid-run using the new **Take Photo** button on the Live Run Tools tab. Photos are
  uploaded directly to Azure Blob Storage via a short-lived SAS token, then recorded
  against the run. A `PHO` marker is enqueued into the GPS track feed so the photo
  location appears on the map.

- **KennelPhotos — sharing preference**: Sharing is controlled by a three-level
  preference (per-run → per-kennel → global). Photos default to private; members
  can opt in to share with the Hash Flash for review.

- **Hash Flash approval screen**: Committee members with the Hash Flash role can
  now review shared photos from the kennel admin page. Each photo can be approved
  (made public), kept private, or deleted. Accessible via the **Review Photos**
  button in the kennel admin functions section (visible only to Hash Flash role
  holders).

- **Live Run Tools — chat strip**: The embedded full chat UI on the Tools tab is
  replaced with a compact read-only strip showing the last 3 messages, a total
  message count badge, and an **Open Chat** button that jumps to the Chat tab.

- **Live Run Tools — QR codes button**: The QR code carousel is removed from the
  Tools tab. A slim **QR Codes** outline button now navigates directly to the
  existing QR tab.

### Bug fixes

- **Live Run nav bar — selected icon invisible**: The active tab icon was
  `Colors.black54` regardless of state, making it invisible against the red
  button background. Selected icons are now white.

- **Live Run Tools — page crash on load**: Two layout assertion failures fixed:
  `Expanded` was incorrectly nested inside an `Obx` wrapper (must be a direct
  `Row` child), and `CrossAxisAlignment.stretch` was applied to a `Row` inside
  an unbounded-height `Column` (resolved with `IntrinsicHeight`).

## 2.4.3+1109 (2026-05-19)

### Code quality

- **`setStateIfMounted` utility**: Added `safe_set_state.dart` — a `State<T>`
  extension that wraps `setState` with a mounted guard. Exported globally via
  `imports.dart`.
- **Codebase-wide `setState` → `setStateIfMounted` migration**: Replaced all
  bare `setState` calls across ~80 files (pages, widgets, controllers) with
  the guarded variant, eliminating a class of "setState called after dispose"
  crashes that can surface when async callbacks complete after a widget unmounts.
- **`buildMapLocation()` utility**: Added to `Utilities` in
  `utilities_null_safe.dart` — resolves an `EventModel` to a map-resolvable
  location string (structured address → coordinates → one-line description).
- **`dart format`**: Applied formatter across the codebase to normalise line
  lengths and indentation.

## 2.4.2+1108 (2026-05-16)

### Enhancements

- **Profile — distance preference auto-saves on selection**: Selecting a distance
  unit (Auto / Kilometers / Miles) in the profile settings now immediately saves the
  preference to the server without requiring the "Save Changes" button. A spinner
  appears next to the "Distance Preference" heading while the call is in-flight, and
  the radio group is non-interactive until the save completes.

### Bug fixes

- **Hash History — wrong table domain in hasher profile view**: Run history launched
  from a hasher's profile was reading from the kennel-domain tables instead of the
  common-domain tables, causing empty or incorrect history. Fixed to always use the
  common domain for all history views.
- **Hash History — missing table prefix in country history query**: The UNION branch
  of the country history query referenced `kennels` instead of `common_kennels`,
  causing a SQLite "no such table" error. Fixed.
- **Hash History — missing table alias in run history UNION query**: JOIN conditions
  in the UNION branch were missing the `hem.` alias, causing ambiguous column errors.
  Fixed.
- **Hash History — UUID not normalised in country stats**: `CountryStats.fromMap` was
  not normalising the `countryId` UUID, causing country drill-down navigation to fail
  silently when the server returned uppercase UUIDs. Fixed.
- **Kennel admin — past runs not loading**: Kennel admins who were not following a
  kennel saw an empty past runs calendar because `common_events` only holds 10 days
  of history for unfollowed kennels. The app now automatically follows the kennel and
  force-replicates all event history before entering admin screens.
- **Kennel admin — filter events GetX crash**: The `publishedRunCount` field was a
  plain `List`, causing the `Obx` widget that reads it to throw a GetX "improper use"
  error on load. Made it reactive (`RxList`).
- **Kennel admin — manual refresh skipped kennel domain sync**: Pull-to-refresh on
  the filter events page only re-synced events, leaving kennel-domain membership data
  stale. Now also refreshes `hasherKennelMap` via `syncKennelAdminService`.
- **Chat — access token always rejected**: `hcapp_getEventMessages` and
  `hcapp_sendEventMessage` were generating compound tokens (`deviceSecret + eventId`)
  but the SPs validated against `eventId` only. Token generation and SPs now both use
  the standard device-secret token.

## 2.4.1+1107 (2026-05-13)

7 bug fixes — see git log for details.

## 2.4.0+1106 (2026-05-10)

State management overhaul, 4 new GetX migrations, boot fix.
