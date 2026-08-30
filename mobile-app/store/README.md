# App Store screenshots

Raw simulator captures → branded, captioned store images at Apple's exact sizes.

Two different products come out of this pipeline — don't mix them up:

| | App Store (`out/`) | In-app version-promo deck (`out/splash/`) |
|---|---|---|
| Background | baked in, **flattened, no alpha** (Apple rejects alpha) | **transparent** — the app paints its own behind |
| Size | 1320×2868 / 2064×2752 | 1170×2532 |
| Format | PNG | AVIF (`sips -s format avif`, keeps alpha) |
| Goes to | App Store Connect | `splash-sequences` blob container |

## Sizes Apple requires (2026)
| Slot | Pixels | Simulator |
|---|---|---|
| iPhone 6.9" (mandatory) | 1320 × 2868 | iPhone 17 Pro Max |
| iPad 13" (mandatory — Runner targets iPad, and Apple never lets a universal app drop a device family) | 2064 × 2752 | iPad Pro 13-inch (M5) |

## Google Play
Play will NOT take the App Store phone set: it caps screenshots at a **2:1**
aspect ratio and the 6.9" images are 1320x2868 = 1:2.17, so they are refused.
`python3 store/compose.py play` re-frames the SAME iPhone raws onto 1080x1920
(9:16 — inside the cap, and the ratio Google recommends for featuring) and
writes `out/play_01..08.png`. Play also requires no alpha channel (these have
none) and allows at most 8 screenshots per form factor.
The iPad set (1:1.33) and the watch shot (1:1.22) are already Play-legal and can
be reused for the tablet form factors.

## Workflow
1. Boot the simulator, `flutter run -d <udid>` (debug is fine — the banner is off).
2. Fake the status bar: `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4`
3. Put the sim in London so "nearby" makes sense: `xcrun simctl location booted set 51.5074,-0.1278` (relaunch the app — it reads location at boot).
4. Drive the app with the helpers (see below) and capture each screen:
   `xcrun simctl io booted screenshot store/raw/<name>.png` — native pixels, no scaling.
   iPad captures go in `store/raw/ipad13/<same name>.png` — `compose.py` prefers a
   `raw/<device>/` file over the shared `raw/` one, so one `SLIDES` list serves both.
5. Edit `SLIDES` in `compose.py`, then `python3 store/compose.py iphone69` / `ipad13`. Output lands in `store/out/`.
6. Upload to App Store Connect: `python3 store/asc_upload.py` (dry run) then
   `--apply`. It targets whichever version is in an editable state, DELETES the
   existing screenshot sets on it and uploads `out/` in filename order. The live
   version's screenshots are untouched — each appStoreVersion owns its own.
   Dragging the files in by hand still works. `raw/`, `out/`, `html/` are git-ignored.

### Display-type gotcha (a 409 the first time, 2026-08-29)
There is **no** `APP_IPHONE_69` or `APP_IPAD_13` in the API enum:

| Set | Pixels | API `screenshotDisplayType` |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | `APP_IPHONE_67` |
| iPad 13" | 2064 × 2752 | `APP_IPAD_PRO_3GEN_129` |

A localization holds at most ONE set per display type, so an occupied slot must be
deleted before a set of that type can be created. To get the current valid list,
POST a bogus `screenshotDisplayType` — the 409 body enumerates every accepted value.

## Apple Watch screenshot
Apple requires one whenever the build embeds `HarrierWatch.app` — it does since 1301.

1. Boot **Apple Watch SE 3 (44mm)**: it renders **368×448**, an exact match for
   `APP_WATCH_SERIES_4`. Ultra 3 (422×514) and Series 11 46mm (416×496) are NOT
   accepted sizes — don't use them.
2. Build the watch app:
   `xcodebuild -project ios/Runner.xcodeproj -scheme HarrierWatch -configuration Debug -sdk watchsimulator -destination 'platform=watchOS Simulator,id=<UDID>' -derivedDataPath <dd> build`
   **This reports BUILD FAILED and that is expected** — the scheme also builds the
   Runner dependency, whose Flutter script phase cannot package for the watch SDK.
   `HarrierWatch.app` is still produced in `<dd>/Build/Products/Debug-watchsimulator/`;
   `simctl install` that directly.
3. The interesting screen needs session state the watch only ever gets from the
   phone. Temporarily seed it in `WatchConnectivityManager.init()` behind
   `ProcessInfo.processInfo.environment["HC_WATCH_DEMO"] == "1"` (phase
   "tracking", isTracking, eventName, distanceKm, elapsedSec), launch with
   `SIMCTL_CHILD_HC_WATCH_DEMO=1 xcrun simctl launch <udid> com.harriercentral.app.watchkitapp`,
   then **revert the Swift file**. Use the same run/figures as the phone
   screenshots so the listing is consistent.
4. Screenshot a few times in a row — the first seconds show a spinner.
5. **Flatten it.** `simctl io … screenshot` on watchOS emits an alpha channel and
   Apple rejects alpha. Render it onto an opaque black page with headless Chrome
   (`sips` will not drop alpha), then confirm `sips -g hasAlpha` says `no`.

`simctl status_bar override` is unsupported on watchOS, so the watch clock shows
the real time rather than 9:41. Apple does not require 9:41.

## Simulator helpers (Quartz, no idb/cliclick needed)
One-time: `python3 -m venv store/venv && store/venv/bin/pip install pyobjc-framework-Quartz`, and grant the
terminal app (VS Code / Terminal) **Accessibility** in System Settings → Privacy & Security — without it the
synthetic events are silently dropped. Turn **Window → Show Device Bezels OFF** in Simulator, or set
`SIM_INSETS=left,top,right,bottom` (points) to describe the bezel.

| Helper | Does |
|---|---|
| `simtap.sh X Y` | Tap at screenshot-pixel coordinates (read them off a scaled-down capture). |
| `simtype.sh "text"` | Type into the focused field (virtual keycodes; ASCII only). |
| `simzoom.sh out 10` | Scroll-wheel zoom on a Google Map (iPhone sim). Does nothing on the iPad sim — use `simpinch.sh`. |
| `simpinch.sh X Y 220 30` | Real pinch (Option-drag via a Swift CGEvent helper, compiled on first use). start>end zooms out. |

Set `SIM_UDID` when more than one simulator is booted. Keep hands off the mouse while a helper runs —
the cursor is shared.

## iPad (2026-08-29)
- Sim: iPad Pro 13-inch (M5). Put it in Settings → Multitasking & Gestures → **Full Screen Apps** first;
  in the default windowed mode the app launches in a floating window and the `•••` control sits over the app bar.
- Scroll-wheel zoom is ignored by the map on the iPad sim; `simpinch.sh` works.
- Welcome deck: set `flutter.StringPrefsEnum.harrierCentralPreviousVersion` to an old version in the app's
  Preferences plist (app terminated) and relaunch — the deck replays and re-stamps itself when dismissed.
- Only `window 1` is used for geometry: shut down other simulators first.

## Gotchas learned 2026-08-28
- The Simulator drops Quartz events while another app is frontmost: `osascript -e 'tell application "Simulator" to activate'` first.
- Enabling location adds a blue arrow to the status bar that `status_bar override` can't hide — capture map shots last, or crop.
- `screencapture` needs Screen Recording permission; `simctl io screenshot` needs nothing.
- Apple's 9:41 shows as `09:41` on an en_GB sim (24h clock). Cosmetic.
