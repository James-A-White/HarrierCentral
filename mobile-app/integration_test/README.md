# On-device screen walk

A headless check that the app's screens open without framework errors, run
on a simulator with no window needed (the Mac can stay locked). It exists
because the GetX "improper use of a GetX" class — an `Obx` whose only Rx read
gets skipped — compiles clean and only throws on the path a user walks.

| File | What |
|---|---|
| `harness/hc_harness.dart` | `Harness`: boots the real app, pumps real frames (`settle`, `waitFor`), taps, screenshots, and an `ErrorLedger` that records every `FlutterError` against the screen that was open |
| `screens_test.dart` | The walk over the 16 pages migrated on 2026-09-23 (18 screens counting the shared controllers), plus sign-in through the invite-code page |
| `smoke_test.dart` | Boots the app and takes one screenshot — proves the pipeline |
| `../test_driver/integration_test.dart` | Saves screenshots to `integration_test/screenshots/` (ignored by git) |

## Run it

```bash
cd mobile-app
xcrun simctl list devices | grep Booted          # or boot one
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screens_test.dart -d <udid> \
  --dart-define=HC_TEST_INVITE_CODE=ABCDEF \     # only if the simulator is signed out
  --dart-define=HC_TEST_KENNEL=HCTEST-ABC \      # a kennel you manage (default)
  --dart-define=HC_TEST_RUN="Test image upload"  # one of its runs you attended, with a charge (default)
```

The app talks to the **production** server as you. The invite code is the six
characters after `URC:` in `HC.Hasher.ResetCode`; once the device is authorised
it stays signed in and the define can be dropped. About four minutes to build,
then a few minutes to walk.

A failing screen does not stop the walk: the step is recorded in the ledger,
a `FAILED_…` screenshot is taken, the app is popped back to the main page and
the next step runs. The test fails at the end if the ledger is not empty, and
the report names the screen for each error.

## Footguns

- **`flutter clean` before the next release archive.** A simulator build
  leaves simulator-slice frameworks that Apple rejects (see the
  `simulator-poisons-release` note).
- `pumpAndSettle` is never used: the map, spinners and the location stream
  never settle. `Harness.settle(Duration)` pumps real frames for a while.
- Labels in the run-admin and kennel-admin grids contain `\r\n`; use
  `find.textContaining`.
- Native permission prompts (camera on the QR page) do not block the test —
  taps go to the Flutter engine, not through the OS — but grant them first so
  the screens behave: `xcrun simctl privacy <udid> grant camera|photos|location com.harriercentral.app`.
- Every run adds nothing to `HC.Device` after the first: the device id is
  kept in the simulator's keychain between builds.
