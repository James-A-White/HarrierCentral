---
paths:
  - "mobile-app/**/*.dart"
  - "portal/**/*.dart"
---

# Flutter and Dart Rules

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read a Dart file in `mobile-app/` or `portal/`.

---

## Code Quality Rules (Flutter/Dart)

**Centre the controls you add to a layout (Flutter/Dart):**

Buttons, segmented switches, counts and the messages that go with them are
**centred**, not left-aligned against the padding (James, 2026-09-13). Set
`crossAxisAlignment: CrossAxisAlignment.center` on the Column and
`textAlign: TextAlign.center` on the text that sits with them.

Two traps, both of which shipped:

- **A Column does not fill its width** — it takes the width of its widest
  child. Inside a `Padding` it therefore sits against the LEFT edge, and its
  `crossAxisAlignment` then centres the children against *each other* rather
  than against the screen. Wrap it in a `Center` when it is the whole body.
- **Two controls side by side want a `Wrap`, not a `Row`.** At a large text
  size a switch plus a button is wider than a phone; a `Wrap` with
  `alignment: WrapAlignment.center` takes a second line, a `Row` overflows.

**Wrapped button text is centred, every time (Flutter/Dart):**

A `Text` defaults to `TextAlign.start`. Inside a button that is invisible
while the label fits on one line, and shows the moment it wraps — a small
phone, a large text size — as lines hugging the left edge (James,
2026-09-25). Every `Text` that is a button's `child:` / `label:` carries
`textAlign: TextAlign.center`; a single-line label looks identical with or
without it, so this never changes a large screen. `ButtonStyle` cannot set
it, so it goes on each Text.

```bash
python3 tools/button_text_scan.py          # MUST print nothing
python3 tools/button_text_scan.py --fix    # adds the missing ones
```

The scan sees stock `ElevatedButton` / `TextButton` / `OutlinedButton` (and
`.icon`); custom button widgets keep their labels centred by hand.

**Every new screen gets the jungle background (Flutter/Dart):**

New pages default to the Harrier Central jungle background, not the theme's
plain scaffold colour and not black. Wrap the body:

```dart
AppScaffold(
  appBar: AppBar(backgroundColor: themeAppBarBackground, title: Text(..., style: ts_appBarTitle)),
  body: DecoratedBox(
    decoration: Backgrounds.defaultHcBackground(),
    child: ...,
  ),
)
```

`AppScaffold` does **not** apply it — it paints the theme colour — so a page
that forgets the wrapper comes out plain grey and looks like a different app.
51 of the 64 `AppScaffold` screens already wrap their own body; the rule exists
so the next one does too.

**The background is dark, so the text has to be light.** Use `ts_body`,
`ts_titleMedium` and friends (white). The `ts_alertDialog*` and
`ts_footnoteBlack` styles are BLACK — they belong on a white dialog and are
unreadable on the jungle. Same for borders and icons: `Colors.black12` /
`black38` / `black45` disappear. Use `Colors.white24` / `white60` / `white70`,
and give a card its own `Colors.black.withValues(alpha: 0.28)` fill so it reads
against the leaves.

(James, 2026-09-12, after the photo-sweep carousel shipped on a black
background and the sweep pages on plain grey.)

**Button text on red buttons (Flutter/Dart):**

The app's `TextButton`/`ElevatedButton` themes render default buttons with a
red background. Any text placed on a red (or other saturated/dark) button
must be **white** — never `themeAppBarBackground` or another dark color.
This mistake recurs whenever new views are built with copied nav styles:
the old transparent-button styles used dark text, but on today's themed red
buttons dark-on-red is unreadable. When creating any new button or button
text style, check what background the theme actually paints and default to
white text on red buttons, every time.

**Ids are lowercase, everywhere — `HcId` (Flutter/Dart):**

SQL Server writes a `UNIQUEIDENTIFIER` in UPPERCASE whenever SQL itself makes
it text (push payloads, `CAST(id AS NVARCHAR)` columns); the API's JSON and
the phone's database use lowercase. Dart `==` and SQLite `=` are both
case-sensitive, so a mixed-case id matches nothing and says nothing. On
2026-09-27 that lost "you" on the PackTrack map and made every chat push open
nothing. The fix is structural — keep ids lowercase where they ENTER, so a
plain `==` / `=` is always right:

| Door | What lowercases it |
|---|---|
| Sync + adHoc replies | `lowerGuidsInPlace` in `base_service.dart` |
| Push payloads | `message.payload` (never `message.data`) |
| PackTrack positions | `lowerGuidsInPlace` in `get_positions.dart` |
| GUID-shaped string prefs | `getStringPref` / `setStringPref` |
| Rows written before 1416 | `lowercaseStoredGuidsOnce` (one-time, at boot sync) |

Rules:
- **`HcId`** (`lib/util/hc_id.dart`, exported via `imports.dart`) is the id
  type: an extension type over `String` whose only constructor lowercases. It
  costs nothing at runtime and `implements String`, so it drops in anywhere.
  Query functions take ids as `HcId` (`QueryRuns`, `QueryKennels`,
  `CommonQueries.isAtRunStart`), so a raw payload string cannot reach SQL.
  New id parameters and fields use `HcId`; migrate old ones as you touch them.
- An id from outside the app — payload, URL, scan, another service — becomes
  an `HcId` on the line it arrives.
- Never `toUpperCase()` an id. The rare deliberate case carries
  `// id-case-ok: <why>`.
- `normalizeUuid` / `.asUuid` / `equalsUuid` still work for existing code.

```bash
python3 tools/id_case_scan.py     # MUST print nothing
```

**BIT columns in Flutter/Dart `fromJson` (API serialisation gotcha):**

Some columns in existing tables are `BIT` — these are bugs to fix, but until
they are migrated to `SMALLINT` they need careful handling in Dart.

The .NET Azure Functions API shim serialises SQL Server `BIT` columns as JSON
booleans (`true`/`false`), not as integers (`1`/`0`). All other integer column
types (`INT`, `SMALLINT`, etc.) come back as `num`/`int` as expected.

Rules:
- Never cast a `BIT`-sourced field with `(json['field'] as int?) == 1` — this
  throws a `TypeError` at runtime when the value is `false` or `true`.
- Always parse `BIT` fields with:
  `json['field'] == true || json['field'] == 1`
  The `== 1` guard defends against any future API behaviour change.
- This applies to every `fromJson` factory that reads a column declared as
  `BIT` in the base table, including hand-written and Freezed models.

**After any page migration or new `Obx`, run the on-device screen walk
(Flutter/Dart):**

`mobile-app/integration_test/screens_test.dart` boots the real app on a
simulator, signs in if it has to, and opens the screens that moved to GetX
controllers — recording every framework error against the screen that was
open. It needs no window, so the Mac can stay locked; it does not need
Puppeteer, which cannot drive a Flutter app. Usage, defines and footguns are
in `mobile-app/integration_test/README.md`; the one-line version:

```bash
cd mobile-app && flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screens_test.dart -d <simulator udid> --dart-define=HC_UI_TEST=true
```

`HC_UI_TEST` skips the notification permission request (a native alert the
walk cannot answer); it is never set for a release build. Two rules that
came out of building it (2026-09-24): an `Obx` must read its Rx before any
`??` / ternary / early return that could skip it (`tools/obx_scan.py` lists
the candidates), and a tab that owns a camera preview must stay mounted
across swipes (`KeepAliveTab`). `flutter clean` before the next release
archive — a simulator build poisons it.

**`Get.back()` does not pop while a GetX snackbar is open (Flutter/Dart):**

GetX 4.7.3's `Get.back()` starts with a compatibility shim: if a GetX
snackbar is showing it closes the snackbar and RETURNS. A page that shows
"Saved!" with `hcSnack` / `Get.rawSnackbar` / `Get.snackbar` and then calls
`Get.back()` stays on screen, and any `isSaving` flag behind the button never
clears. That hung Add Down Down on 1397 and 1399 (2026-09-24): the charge was
saved, the spinner never stopped. The old page used a ScaffoldMessenger
SnackBar, which GetX does not count, so the migration to `hcSnack` exposed it.

Rules: pop a page with `hcPop()` (`lib/util/hc_nav.dart`, pops through the
navigator itself), never `Get.back()`, and show the toast AFTER the pop —
it draws on the app overlay and survives it. `test/unit/hc_pop_test.dart`
pins both behaviours. The same shim bites `Get.back()` used to close a
dialog while a toast is up.

**Fixing a crash? Find the other call sites BEFORE you commit.**

A stack trace names one file and one line, so the natural fix is that line.
In this codebase that fix is usually incomplete, because the same idiom is
hand-copied across several files and only the one that crashed gets guarded.

Measured on 2026-09-18, five classes were each fixed once and missed elsewhere:

| Class | Guarded | Missed until it crashed |
|---|---|---|
| Empty SP reply read at `[0]` | run tabs (5 Sep), run list | check-in, 3 sites (17 Sep) |
| Write to a disposed chat stream | delta fetch, send (14 Sep) | delivered receipts, image picker |
| GetX snackbar throwing | around close (11 Sep) | around show (12 Sep) |
| `int.tryParse` on a missing key | notification service (30 Aug) | run list controller |
| Stale `BuildContext` for the messenger | 4 calls commented out | the controller's 5 copies (16 Sep) |

So: after writing the fix and before committing, grep for the SHAPE, not the
symptom. One command, and on 18 Sep it turned one fix into three — including a
crash on a kennel's first ever run that nobody had reported.

```bash
# MUST print nothing. Skips sp_reply.dart's own docs and commented-out code.
grep -rn "adHocData\[" mobile-app/lib | grep -v sp_reply.dart | grep -vE ":[[:space:]]*//"

# Every one of these inside a deferred callback is a bug — resolve it early.
grep -rn "ScaffoldMessenger.of(" mobile-app/lib

# tryParse unless the input is ours and cannot be a decimal or absent.
grep -rn "int.parse(" mobile-app/lib
```

Two classes are now structural rather than a matter of remembering:

- **`firstRow(adHocData)`** (`lib/util/sp_reply.dart`) is the ONLY way to read
  an SP's adHoc reply. An empty list is what a dropped socket, a local timeout
  or an error envelope look like, and indexing it throws a `RangeError` that
  also kills the rest of the callback — the refresh never runs and the spinner
  never clears, so the user sees a dead tap rather than an error. `adHocData[`
  appearing anywhere is a new unguarded read, not a survivor.
- **A `BuildContext` captured for later is a bug.** Resolve what you need from
  it (`ScaffoldMessenger.of`) while it is certainly alive and hand the resolved
  object to the callback. The row that opened a snackbar is gone by the time
  its buttons are pressed.

Still open, and worth an audit rather than a guess: 36 GetX controllers exist
and 6 ever check `isClosed`. Only those that await and then touch state have
the fault, so that is an exposure figure, not a bug count.
