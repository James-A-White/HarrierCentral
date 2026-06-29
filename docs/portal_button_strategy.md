# Portal Button Consistency Strategy

_Audit + proposal, 2026-06-28._

---

## ✅ IMPLEMENTATION STATUS (2026-06-29) — committed locally, NOT pushed/deployed

Implemented with the recommended decisions (red800 primary, blueGrey secondary,
deep-red destructive, 8px / 44h / 16 DemiBold, `HcButton` widget). Three commits
on `master` (`948b0750`, `77463066`, + this doc) — **not pushed**, so you can run
it locally (`flutter run -d chrome`) and eyeball before shipping. `flutter
analyze` is clean.

- **Phase 1 — foundation + theme (done).** `HcButtonTokens` + `hcPrimary/
  Secondary/Destructive/Text/Outlined` styles + the `HcButton` widget in
  `lib/util/styles.dart` / `lib/tabbed_ui/widgets/hc_button.dart`. `ThemeData`
  fixed: `elevatedButtonTheme` → primary, `textButtonTheme` now **flat** (killed
  the red-fill-on-Cancel bug), added `outlinedButtonTheme`. `defaultButtonStyle`
  & `hcDialogButtonStyle` now alias the system; `textStyleButton` 22 → 16.
- **Phase 2/3 — migrations (done).** Removed all ad-hoc one-off styles and
  converted dialog action buttons to `HcButton` (Set Location, trail-symbols,
  developer, kennel-members Close, login-history/category-detail Close, songs
  add/edit, unsaved-leave Stay/Leave, newsflash dialog/delete/edit).
- **Phase 4 — tappables (reviewed, intentionally left).** The 49 `GestureDetector`
  + 12 `InkWell` are custom interactions (map pins, photo tiles, tappable cards/
  rows, colour swatches), **not** buttons — converting them would break layout/
  behaviour. Left as-is by design.

**Deliberately left** (not buttons): the stateful segmented toggles in the run
list / run detail / photo review (they use dynamic `bg/fg` per selection), and
the chat bottom-sheet options list.

**To finish:** review in the running app, then push `master` (CI deploys) or
tell me to ship. If you want a different secondary treatment (e.g. outlined
instead of filled blueGrey for in-page secondaries), it's a one-line token/style
change now that everything routes through the system.

---

---

## 1. What the audit found

**Button widgets in `portal/lib` (.dart):**

| Widget | Uses | Files |
|---|---:|---:|
| ElevatedButton | 96 | 40 |
| TextButton | 31 | 15 |
| IconButton | 24 | 10 |
| OutlinedButton | 7 | 5 |
| FilledButton | 7 | 4 |
| GestureDetector (as tappable) | 49 | 30 |
| InkWell (as tappable) | 12 | 9 |

**How they're styled:**
- `defaultButtonStyle` — 46 refs (the de-facto standard: red800, 8px radius, white text, grey-when-disabled, elevation 0).
- `hcDialogButtonStyle` — 4 refs (new dialog standard added this week).
- Inline `*.styleFrom` — ~17 (10 ElevatedButton, 6 TextButton, 1 FilledButton) with **ad-hoc** colours: `red.shade600`, `red.shade900`, `Colors.blue`, `0xFFB91C1C` (×12), `0xFFDC2626`, `0xFFC62828`, etc.
- The rest fall through to the **app theme**.

**Root causes of the inconsistency (in priority order):**
1. **The theme is internally inconsistent and partly wrong** (`main.dart`):
   - `elevatedButtonTheme`: `red.shade900`, **10px** radius.
   - `textButtonTheme`: forces a **`red.shade900` background** on TextButtons — so a flat/secondary button (e.g. "Cancel") renders as a filled red button. This is the single biggest source of "weird" buttons.
2. **`defaultButtonStyle` conflicts with the theme** — red800 vs red900, 8px vs 10px — and it's applied to ~46 buttons, so two visual languages coexist app-wide.
3. **~17 inline one-off styles** with at least 5 different reds + blue, various radii and font sizes.
4. **Typography varies widely** — button text at 22 (`textStyleButton`), 20, 18, 16, 14…
5. **61 `GestureDetector`/`InkWell`** custom tappables bypass button semantics entirely (no consistent size/hit-area/disabled/hover).

---

## 2. Proposed system — a small set of semantic buttons

One source of truth (design tokens + a widget set). Five roles, nothing more:

| Role | When | Look |
|---|---|---|
| **Primary** | the main active action on a screen (Save, Submit, Confirm) | filled brand **red** (`0xFFC62828`) |
| **Secondary** | Cancel / the alternative | filled **blueGrey** (`0xFF546E7A`) |
| **Navigation** | wizard / tab Next & Back | filled **blue** (`0xFF1E88E5`) |
| **Destructive** | irreversible (Delete, Clear, Regenerate) | filled **deep red** (`0xFFB71C1C`) |
| **Text** | low-emphasis inline link-style | flat, brand-coloured text, **no background** |
| **Icon** | toolbar / compact actions | `IconButton`, standard size + tooltip |

> James' rule (2026-06-29): **all navigation (Next/Back) = one colour, all
> Cancel = one colour, all primary-active = one colour.** Encoded as the
> Primary / Navigation / Secondary roles above.

**Shared tokens (every filled button identical except colour):**
- Corner radius: **8**
- Min height: **44** (touch target)
- Font: **AvenirNextDemiBold, 16** (22 is oversized for buttons)
- Foreground: white on filled; brand colour on text/outlined
- Disabled: grey background, no hand-rolled disabled colours (`onPressed: null` drives it)
- Elevation: 0 (flat, matches current look)

---

## 3. How to implement (recommended approach)

**Theme-first + a thin semantic widget.** Two layers so both new and old code converge:

**(a) Fix the theme** (`main.dart`) so *bare* buttons are correct by default and the ad-hoc ones visually converge:
- `elevatedButtonTheme` → the Primary style (red, 8px, 44 min, 16 font, grey-disabled, elevation 0).
- `textButtonTheme` → **remove the red background**; flat button, brand-coloured text. (Fixes the whole "Cancel looks like a primary" class instantly.)
- `outlinedButtonTheme` → consistent Secondary outline.
- Pick **one** red and **one** radius.

**(b) Provide a semantic API** in `lib/util/styles.dart` (or a new `widgets/hc_button.dart`):
- Either named styles — `hcPrimaryButtonStyle`, `hcSecondaryButtonStyle`, `hcDestructiveButtonStyle`, `hcTextButtonStyle` — **or** (preferred) a small widget `HcButton.primary(...) / .secondary(...) / .destructive(...) / .text(...)` that also bakes in a built-in loading spinner + disabled handling (we hand-roll those everywhere today).
- `hcDialogButtonStyle` (just added) folds into this as Primary/Secondary.
- Keep `defaultButtonStyle` as a temporary alias of the Primary style during migration, then remove.

**Tokens** live in one place (`HcButtonTokens`: radius, height, font, the colour constants) so there's exactly one number to change.

---

## 4. Migration plan (incremental, low-risk — one commit per phase)

1. **Foundation** — add tokens + the semantic widget/styles + fix the theme. Tuned so it matches today's dominant `defaultButtonStyle` look → minimal visual change, immediate fix to the TextButton bug.
2. **Replace the standards** — swap the 46 `defaultButtonStyle` + 4 `hcDialogButtonStyle` uses to the new API (mechanical).
3. **Sweep inline styles** — map each of the ~17 `*.styleFrom` to a role; flag any that were intentionally different.
4. **Tappables** — review the 61 `GestureDetector`/`InkWell`; convert genuine buttons to the standard, leave true custom interactions (cards, map pins, etc.).

Each phase is independently shippable and visually diff-reviewable.

---

## 5. Decisions I need from you

1. **Primary red** — standardise on one. De-facto is `red800` (defaultButtonStyle); theme uses `red900`. _My rec: `red800` (`0xFFC62828`)._
2. **Secondary/Cancel** — filled neutral (blueGrey, as in the new dialog) **or** outlined? _My rec: filled blueGrey for dialogs, outlined for in-page secondary — but happy to use one everywhere._
3. **Corner radius** — 8 (defaultButtonStyle/dialog) vs 10 (theme). _My rec: 8._
4. **Button font size** — _My rec: 16 DemiBold (retire the 22)._
5. **Semantic widget vs. shared styles** — do you want a `HcButton` widget (nicer ergonomics, built-in loading/disabled) or just shared `ButtonStyle` constants? _My rec: the widget._

Once you pick, Phase 1 is ~an hour and instantly kills the worst offenders (the themed-red TextButtons).
