# On-On — The Harrier Central Guide: specification

This file describes `on-on-user-guide.html` completely enough to rebuild it
from nothing, or to update it when the product changes. Read it top to
bottom once; after that, use the section headings as a checklist.

---

## 1. What the document is

| | |
|---|---|
| **Name** | On-On: The Harrier Central Guide |
| **Form** | A user guide written and laid out as a magazine issue |
| **Audience** | Hashers of every kind — new members, regulars, office holders (Hash Cash, Religious Advisor, Hash Flash, Grand Master, Hare Raiser) and kennel admins |
| **Job** | Explain what Harrier Central does, one functional area per chapter, in the language hashers already use |
| **Format** | One HTML file published as a claude.ai Artifact, plus 25 WebP screenshots published with it. Decorative art is inline SVG |
| **Tone** | Plain, warm, a little dry. The hash's humour, never forced. Second person ("you"). Short sentences |
| **Issue line** | `Issue 3.1 · Autumn 2026` — the issue number follows the app's version train |

The guide is a **reader's** document, not a reference manual. Each chapter
says what a feature is for, then shows the one or two tasks people actually
do. It never lists every option.

---

## 2. Structure (in order)

Every top-level block is a "page": a full-width section with a large vertical
margin, a hairline rule above it, and a **folio** at its foot (section name on
the left, a page number on the right).

| # | Anchor | Page | Folio no. | Contents |
|---|---|---|---|---|
| 1 | — | Cover | — | Masthead, sub-line, trail illustration, four cover lines |
| 2 | `#contents` | Contents | 02 | All 15 entries below, each linking to its anchor |
| 3 | `#history` | Feature: *From the Hash House* | 03 | History essay, timeline, 1950 objectives, pull quote |
| 4 | `#glossary` | Reference: *Speaking Hash* | 07 | 12 terms + 4 trail-mark drawings |
| 5–16 | `#ch1`…`#ch12` | Chapters 01–12 | 09, 11 … 31 (odd numbers, step 2) | One functional group each |
| 17 | `#back` | Back page: *Quick reference* | 33 | Four help panels + colophon |

Folio numbers are invented magazine page numbers. They step by 2 for chapters
(each chapter is a notional spread) and must match the Contents list.

### 2.1 Cover

- Top line (mono, uppercase, muted): `Harrier Central · User Guide` left, issue line right.
- Masthead: **ON-ON**, the hyphen coloured `--jungle`.
- Sub-line: *The magazine for hashers who carry a phone on trail*.
- Trail illustration: one dotted curve across the page (stroke-dasharray `2 14`)
  with, in `--chalk`, two **check circles**, two **arrows** and a **three-bar
  false-trail mark**, ending in a solid dot. Caption below explains the marks.
- Four cover lines (bold display title + one-sentence teaser), each topped by a
  2px ink rule: *From the Hash House*, *PackTrack*, *Hash Cash*, *Your kennel on the web*.

### 2.2 Contents

A two-column (auto-fit) list. Each entry: label (`Feature`, `Ref`, `01`–`12`,
`End`) in chalk mono; title in the display face; folio number right-aligned;
one-line description under the title. The numbers are true chapter order —
the only place numbering is used as structure besides chapter openers.

### 2.3 Feature — From the Hash House

Kicker `Feature · History`, huge display headline, standfirst, byline.
Two-column body with a display-face drop cap on the first paragraph and these
sub-heads, in order:

1. *(opening, no sub-head)* — hare and hounds / paper chase; December 1938,
   Kuala Lumpur, Monday evenings.
2. *(continued)* — Selangor Club Chambers nicknamed the **Hash House** for its
   monotonous food; A. S. Gispert ("G"), with Cecil Lee, Frederick "Horse"
   Thomson, Ronald "Torch" Bennett.
3. **War, and a second start** — runs stop; Gispert killed early 1942 in the
   fighting for Singapore; restart 1946; registered as a society in 1950;
   KL is the **Mother Hash**.
4. **From one kennel to thousands** — Singapore 1962; spread through Southeast
   Asia, Australia and beyond via postings; first **InterHash, Hong Kong 1978**;
   kennels on every continent today.
5. **What has not changed** — hare, marks, checks, false trails, On Inn, circle, names.
6. **Where Harrier Central fits** — began as one hash's app when Flutter was at
   0.8; now app (iOS/Android), admin portal, a site per kennel at hashruns.org.

Then:
- **Timeline** — five milestones: 1938, 1942, 1946, 1962, 1978 (year in large
  display numerals, one line each).
- **Objectives box** (tint background), kicker *From the 1950 registration*,
  the four objectives verbatim:
  1. To promote physical fitness among our members.
  2. To get rid of weekend hangovers.
  3. To acquire a good thirst and to satisfy it in beer.
  4. To persuade the older members that they are not as old as they feel.
- **Pull quote**: "A drinking club with a running problem." — *The hash,
  describing itself, everywhere*.

> Keep history claims to these widely documented facts. Do not add founding
> member lists, kennel counts or dates beyond them without a source.

### 2.4 Reference — Speaking Hash

Definition grid, 12 terms, each with a one-sentence definition:
Kennel, Hare, Pack, On-On, Check, On Inn, Circle, Down-down, Virgin,
Hash name, Mismanagement, Hash trash.

Then four **trail marks**, each a 64×64 inline SVG in `--chalk` with a title
and a line: **Arrow** (on-on), **Circle** (check), **Three bars** (false trail),
**Cross** (not this way — note that marks vary by kennel).

### 2.5 Chapters 01–12

Every chapter uses the same parts, in this order:

1. **Opener** — big numeral (`01`) in the left column on desktop; on the right:
   kicker `Chapter NN · <backlog epic name>`, display title, standfirst
   (one or two sentences), and a **chips row**:
   `For` + role chips (outlined) and `In` + surface chips (tinted:
   App / Portal / Web).
2. **Body** in two flowing columns, with a drop cap on the first paragraph.
3. Exactly **one how-to box** (tint background, chalk mono heading). Use an
   ordered list when the steps are a real sequence, a bulleted list when they
   are a set.
4. Optional **tip** (italic, chalk left rule) — one sentence, a fact worth
   remembering.
5. Optional `h3` sub-heads inside the body.
6. Folio.

| Ch | Title | Backlog epic | For (chips) | In | How-to box |
|---|---|---|---|---|---|
| 01 | Getting started | E1 Identity & Account Access | Every hasher | App, Web | Sign in on a new phone (invite code → *Get Started!*) |
| 02 | Kennels & membership | E2 Kennels, Membership & Permissions | Hasher, Kennel admin, Hash Cash | App, Portal | Follow a kennel |
| 03 | Runs & the calendar | E3 Runs & the Calendar | Hasher, Hare, Hare Raiser | App, Portal, Web | Set a run (ends with *Save* / *Save and send*) |
| 04 | RSVP & check-in | E4 Attendance & Check-In | Hasher, Hash Cash | App, Web | Check in the pack (list, QR, group, fee, offline) |
| 05 | PackTrack | E5 PackTrack Live Tracking | Hasher, Hare, Kennel admin | App, Web | Lost? Find the pack (map → Radar → List) |
| 06 | Photos & Hash Flash | E6 Photos & Hash Flash | Hasher, Hash Flash | App, Portal, Web | Review submissions (approve/reject in bulk, cover, crop) |
| 07 | The circle | E7 Circle, Down Downs & Songs | Religious Advisor, Hasher | App, Web | Lead a song |
| 08 | Hash Cash | E8 Money & the Hash Cash Ledger | Hash Cash, Hasher, Kennel admin | App | What the ledger handles (fees, memberships, haberdashery, credit, expenses) |
| 09 | Chat, alerts & email | E9 Messaging, Notifications & Teaching | Hasher, Hare Raiser, Kennel admin | App, Portal, Web | Save and send a run (WhatsApp, Email hashers, Use run description / Write with AI, Preview to me, Who gets it) |
| 10 | Stats & leaderboards | E10 Stats, Leaderboards & Reporting | Hasher, Grand Master | App, Web | Leaderboards (kennel, global, by period) |
| 11 | Your kennel on the web | E11 Public Web Presence | Visitor, Kennel admin | Web, Portal | Make the site look like your club |
| 12 | The admin portal | E12 Platform Administration | Kennel admin, Mismanagement, Platform admin | Portal | What you can do in the portal |

**Facts each chapter must keep true** (check against `docs/backlog.md` before
each new issue — only `Shipped` stories go in):

- Ch 01 — device-bound sign-in, no password; six-letter invite code; *Find my
  account* emails the code; admins may have registered you already; guest mode;
  account deletion keeps anonymous run records.
- Ch 02 — search by name/city/region/country + search tags; following pulls full
  history; **member = membership date in the future** (never "IsMember");
  admin rights and club offices are independent grantors; hare edits own run only.
- Ch 03 — run list filters; today's attended run stays on top; past-run card
  icons (track + runner count, photos, chat, down-downs); same offline;
  automatic renumbering + manual override; Google Calendar; runs-page import.
- Ch 04 — Yes/Maybe/No; multi-run RSVP; RSVP hidden on past runs; self check-in
  prompt; "Check In" on free runs; starting PackTrack checks you in; offline check-in.
- Ch 05 — Best / Balanced / Power Saver (all precise GPS; they differ in upload
  cadence); pocket tracking, buffering, auto-stop; map / Radar / List; marks incl.
  On Inn and distress; replay with photos; web replay; GPX export/import,
  Strava/Garmin; Trail TV; noise smoothing and standing-still detection.
- Ch 06 — private vs club per photo; camera-roll copy; camera-roll import pins
  where taken; Hash Flash queue, bulk, cover, reversible crop; photos shown whole
  at their own shape; public gallery has no GPS.
- Ch 07 — down-downs with reason; done/undo/cancel; nominations by anyone;
  drink count; push the song to everyone; per-kennel songbook; hash trash.
- Ch 08 — member/visitor/virgin prices; cash/credit/card; group charge; free runs;
  self-pay and app renewal; annual/rolling/calendar-year; haberdashery; credit
  switchable per kennel; exact decimals; offline outbox; no double charge;
  nightly standing; scheduled reports.
- Ch 09 — run, kennel and role rooms; photos, locations, replies, reactions,
  direct messages; opens at newest; badge clears on every device; Save and send;
  email audience = **members, followers and RSVPs, minus anyone who turned run
  emails off** (and the blocked/bouncing); unsubscribe link; web sign-in by
  emailed code or passkey. Use the word **hashers**, not "members", for the audience.
- Ch 10 — per-kennel and total counts, rolling 12 months, historical estimate;
  kennel/global/period leaderboards; GM trends and emailed summary; public stats.
- Ch 11 — `hashruns.org/<slug>` and `/<slug>/<run number>`; custom domain;
  page builder; colours/logo/light-dark with guaranteed legibility; global
  calendar; SEO; old links redirect.
- Ch 12 — portal = app admin parity (James's rule); sign in by confirming on the
  phone; kennel requests at harriercentral.com; usage, account merging, newsflashes.

### 2.6 Back page

Four panels (display heading + short paragraph or list): **Get the app**,
**Where things live** (App · Portal `portal.harriercentral.com` · Kennel sites
`hashruns.org` · New kennels `harriercentral.com`), **Stuck?** (in-app FAQ,
video tutorials, support carries device details), **Locked out?** (Find my
account). Colophon names the versions the guide describes and ends "On-On."

---

## 3. Visual design

### 3.1 Concept

A print magazine on cool paper. Generous white space is the main design
device: wide outer gutters, ~170px between pages on desktop, a narrow body
measure, and no boxes except the how-to panels and the objectives box. One
colour does the shouting (trail-mark red), used only for kickers, marks, the
how-to heading and the tip rule. Green is the brand voice: numerals, the
masthead hyphen, drop caps, links.

### 3.2 Tokens (copy exactly)

```css
:root {
  --paper:  #FBFCFA;  --ink:   #14201A;  --muted: #5E6B63;
  --rule:   #DCE3DE;  --tint:  #EEF3EF;
  --jungle: #1F5A3A;  /* brand green */
  --chalk:  #C62828;  /* trail-mark red, sparingly */
  --measure: 34rem;
  --gutter: clamp(16px, 5vw, 72px);
  --space-page: clamp(72px, 12vw, 168px);
}
/* Dark: same token names, redefined under
   @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {…} }
   and again under :root[data-theme="dark"] {…} */
--paper #0F1512  --ink #E8EEEA  --muted #9AA8A0  --rule #26332C
--tint  #16201B  --jungle #7CC99A  --chalk #FF6B5E   (+ color-scheme: dark)
```

`body` always sets `background: var(--paper); color: var(--ink)`. No colour
appears anywhere except through these tokens (SVG strokes use
`currentColor`, `var(--chalk)` or `var(--ink)`).

### 3.3 Typography

Google Fonts link:

```
https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@600;800;900&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;1,8..60,400&family=IBM+Plex+Mono:wght@400;500&display=swap
```

| Role | Face | Use |
|---|---|---|
| Display | **Big Shoulders Display** 600/800/900, uppercase | Masthead, headlines, numerals, drop caps, glossary terms. Condensed, race-bib feel |
| Body | **Source Serif 4** 400/600, italic 400 | Running text, standfirsts, pull quote (italic) |
| Utility | **IBM Plex Mono** 400/500, uppercase, 0.08em tracking, 0.75rem | Kickers, chips, folios, captions, contents numbers |

Fallbacks: `"Arial Narrow", "Helvetica Neue", Arial, sans-serif` /
`Georgia, "Times New Roman", serif` / `ui-monospace, "SF Mono", Menlo, monospace`.

Scale (all `clamp()` so phones scale down):

| Element | Size | Line-height |
|---|---|---|
| Masthead | `clamp(5.5rem, 22vw, 15rem)` 900 | 0.82 |
| Feature headline | `clamp(3rem, 9vw, 7rem)` 900 | 0.88 |
| Chapter numeral | `clamp(6rem, 16vw, 12rem)` 900, `--jungle` | 0.78 |
| Chapter title | `clamp(2.6rem, 6.5vw, 5rem)` 900 | 0.9 |
| Section title (Contents, Glossary, Back) | `clamp(2.75rem, 7vw, 5rem)` 800 | 0.92 |
| Standfirst | `clamp(1.2rem, 2.2vw, 1.5rem)`, muted | 1.45 |
| Pull quote | `clamp(1.5rem, 3.2vw, 2.25rem)` italic serif | 1.3 |
| Body | 1.0625rem (1rem under 600px) | 1.65 |
| Sub-heads (h3) | 1.35rem display 800 | — |

Headings use `text-wrap: balance`.

### 3.4 Layout

- Content width `max-width: 1180px`, side padding `--gutter` (never below 16px).
- Each page: `padding-block: var(--space-page)`, 1px `--rule` top border
  (none on the cover).
- **Chapter opener** grid: one column on phones; from 900px,
  `15rem | 1fr` with the numeral in the narrow column.
- **Body**: CSS columns `columns: 2 22rem; column-gap: clamp(2.5rem,5vw,4.5rem)`
  — two columns when there is room, one on phones. Every child
  `break-inside: avoid-column` so a how-to box never splits.
- **Drop cap**: first paragraph of each `.columns`, display 900, 4.6em, `--jungle`.
- Grids (cover lines, contents, timeline, glossary, marks, back page) all use
  `repeat(auto-fit, minmax(min(100%, Nrem), 1fr))` so nothing overflows at 400px.
- **Folio**: mono, muted, flex space-between, 1px rule above, large top margin.

### 3.5 Components

| Component | Rule |
|---|---|
| Kicker | Mono uppercase, `--chalk`, sits above every headline |
| Chip | Mono, pill (`border-radius: 999px`), 1px `--rule` border. Surface chips (`.where`) use `--tint` fill and no border. Preceded by a muted `For` / `In` label |
| How-to box | `--tint` fill, 1.75rem padding, no border or radius, heading in chalk mono |
| Tip | Italic muted serif, 2px `--chalk` left rule |
| Timeline item | 1px ink top rule, year in display 900 `--jungle` |
| Objectives box | `--tint` fill, kicker + display heading + ordered list |
| Trail mark | 64px SVG, `stroke: currentColor`, colour `--chalk`, 4px stroke, round caps |

No shadows. No rounded cards. No emoji. Numbering appears only where order is
real: the chapter sequence and step-by-step how-tos.

### 3.6 Accessibility & behaviour

- Landmarks: cover is `<header>`, chapters are `<section>` / the feature is
  `<article>`, the back page is `<footer>`; each has `aria-labelledby` its heading.
- Decorative numerals and SVGs carry `aria-hidden="true"`.
- Visible focus: 2px `--chalk` outline on links.
- Colour transitions only under `prefers-reduced-motion: no-preference`.
- No scripts at all. The page is complete at rest.

---

## 3A. Screenshots

The guide carries **25 images**: 21 phone screens and 4 web pages, stored as
WebP in `docs/user-guide/images/` and published alongside the page with the
Artifact tool's `files` map (published path `images/<name>.webp`).

### Placement

| Chapter | Kind | Images (in order) |
|---|---|---|
| 01 | phone row | `invite-code` |
| 02 | phone row | `kennels-list`, `kennel-members` |
| 03 | phone row | `runs-list`, `run-details`, `run-map` |
| 04 | phone row | `rsvp` |
| 05 | phone row + wide | `run-packtrack`; `web-packtrack` (City H3 #1940 replay) |
| 06 | phone row + wide | `run-photos`, `review-photos`; `web-photos` |
| 07 | phone row | `down-downs`, `songs`, `award-list` |
| 08 | phone row | `run-admin`, `hash-cash` |
| 09 | phone row | `edit-run`, `email-composer`, `email-audience` |
| 10 | phone row | `run-counts`, `run-stats` |
| 11 | wide ×2 | `web-kennel`, `web-run` |
| 12 | phone row | `kennel-admin` |

Figures go after the chapter's body columns and before its folio. The cover,
contents, history, glossary and back page carry no screenshots.

### Components

- **Phone row** (`.shots` > `figure.shot`): one flex row, centred
  (`justify-content: safe center`), scrolls sideways when wider than the
  screen. Every screen is the SAME HEIGHT — `clamp(380px, 44vw, 560px)` —
  with `width: auto`, so each keeps its own shape and is never cropped
  (CLAUDE.md photo rule). 28px radius, 1px `--rule` border. The figure is a
  1px-wide table so its caption wraps to the image's width.
- **Wide figure** (`figure.wide`): full content width, `height: auto`,
  10px radius, 1px `--rule` border.
- **Caption**: a mono uppercase label (`<b>`, the screen's own title, e.g.
  *Run Admin*) above one serif sentence (`<span>`) saying what the reader
  can do there.
- Every `<img>` has `width`/`height` attributes, `loading="lazy"` and alt text
  that describes what is on the screen.

### Capturing them again

Phone screens come from an integration test that drives the real app on a
simulator and saves each screen at 2× (no status bar; the Flutter layer only):

```bash
cd mobile-app && flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/user_guide_shots_test.dart -d <simulator udid> \
  --dart-define=HC_UI_TEST=true [--dart-define=HC_TEST_INVITE_CODE=XXXXXX]
```

Files land in `mobile-app/integration_test/screenshots/NN_guide_<screen>.png`.

**Two passes.** The run screens look best on a real kennel with a busy run, so
the walk runs twice:

| Pass | Defines | Supplies |
|---|---|---|
| Real kennel | `HC_GUIDE_REAL=true HC_TEST_KENNEL=BMPH3 HC_TEST_RUN=2060` | `run-details`, `rsvp`, `run-packtrack`, `run-photos`, `review-photos`, `award-list`, `run-stats`, `run-admin`, `kennel-admin` (files `NN_guide_real_*`) |
| Test kennel | none (defaults HCTEST-ABC, *Test image upload*) | everything else, including the run editor, the email composer and Who gets the email |

`HC_TEST_RUN` is any text on the run's card (the run number works); the walk
opens **Past Runs** when the run is not already listed. In real mode it skips
every screen that shows members' private details: the roster, manual check-in,
payments, the run editor and the email audience. BMPH3 #2060 was chosen by
query as the busiest recent run (30 at the hash, 15 photos, 7 trails); pick
the next one the same way when it is replaced.
The walk signs in if needed, then visits Runs, Kennels (HCTEST-ABC page and
members), Map, History, Songs, Global Leaders, and the test run
*Test image upload* (details and tabs, Run Admin, Award list, Down Downs,
Hash cash, Manual check in, Hash Trash, Edit run details, Email the run,
Who gets the email). It saves and sends nothing. If the simulator is stuck
on "Device No Longer Registered", uninstall the app first, then pass the code.

Web pages come from headless Chrome at 1280 wide:

```bash
C="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$C" --headless=new --hide-scrollbars --window-size=1280,820 --virtual-time-budget=15000 \
  --screenshot=pt.png https://www.hashruns.org/cityh3/1940/packtrack
# web-kennel: /cityh3   web-run: /cityh3/1940   web-photos: /cityh3/1940/photos  (1280x900)
```

Convert: phone PNGs resized to 720px wide, WebP quality 82; web PNGs at full
size, WebP quality 80 (Pillow, `method=6`). The set totals about 2.4 MB.

### What never goes in a screenshot

- Support and the check-in **Be Scanned** tab — they show the user's secret QR code.
- **My Account** — email address and personal details.
- The **Chats** list — its previews show other people's messages.
- **Manual check-in** — it shows members' real (mortal) names.
- The global leaderboard and the hashruns.org global calendar — real hash
  names and event images can be crude; use the run's own Stats tab instead.
- Real-kennel screens come only from the real-mode pass above; anything showing money, contact details or mortal names comes from **HCTEST-ABC**.

---

## 4. Artifact rules that shape the file

The HTML is published with the claude.ai Artifact tool, which wraps it in its
own `<!doctype><html><head><body>`. So the file:

- starts with `<title>On-On: The Harrier Central Guide</title>`, then the font
  `<link>`s, then one `<style>` block — **no** doctype/html/head/body tags;
- loads fonts only from `fonts.googleapis.com` (the only stylesheet host allowed);
- uses no external scripts and no `localStorage`; its images are published
  files referenced by relative path (`images/…`);
- uses plain `#anchors` for the contents links (the only hash form the viewer passes).

To view it outside the Artifact viewer, wrap it in a normal HTML5 skeleton
with `<meta charset="utf-8">` and `<meta name="viewport" content="width=device-width, initial-scale=1">`.

---

## 5. How to rebuild or update

1. **Gather facts.** Read `docs/backlog.md`. For each chapter's epic, list the
   `Shipped` stories only; `Building` and `Next` work does not go in the guide.
   Check `CLAUDE.md` for rules that change wording (e.g. member = date in the
   future; "hashers" not "members" for email audiences; photos at their own shape).
2. **Write the copy first**, in the order of §2, one standfirst + body + one
   how-to per chapter. Translate stories into what a hasher does, never how the
   system is built (no SP names, no table names, no story IDs in the page).
3. **Use the vocabulary** of §2.4 and the app's own button labels in **bold**
   (*Save and send*, *Use run description*, *Write with AI*, *Preview to me*,
   *Who gets it*, *Get Started!*, *Find my account*, *Check In*, *Radar*, *List*).
4. **Build** with the tokens, faces and components of §3. Keep one how-to per
   chapter and at most one tip.
5. **Update the issue line and colophon** with the app, portal and web versions
   from `mobile-app/pubspec.yaml`, `portal/pubspec.yaml` and the season.
6. **Check** at 400px and 1280px, light and dark: no horizontal scroll, folios
   and Contents numbers agree, every anchor resolves.
7. **Recapture screenshots** (§3A) whenever a pictured screen changes.
8. **Publish** the HTML with the Artifact tool to the same URL (pass `url`),
   with every image in the `files` map, so shared links keep working.

### Adding a chapter

Append it after Chapter 12 as `#ch13`, folio 33, and move the back page to 35.
Add its row to the Contents list and to the table in §2.5. Chapter numbers,
like backlog IDs, are never reused or reordered.

---

## 6. File locations

| File | Purpose |
|---|---|
| `docs/user-guide/on-on-user-guide.html` | The magazine (Artifact source) |
| `docs/user-guide/on-on-user-guide.md` | This specification |
| `docs/user-guide/images/*.webp` | The 25 screenshots |
| `mobile-app/integration_test/user_guide_shots_test.dart` | The walk that captures the phone screens |
