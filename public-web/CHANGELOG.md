# public-web Changelog

## 0.21.31 (2026-08-28)
- **Trail-TV shows trail marks**: checks, drink stops, on-inn and text
  tiles now draw on all three Trail-TV maps (larger on the front-runner
  cam), revealed as the replay clock passes them. The mark renderer and
  visibility collector moved out of PackTrackMap into a shared
  `trackMarks.ts` so both maps draw identical tiles.
- **Photo takeovers zoom back out**: a takeover now eases back out (450ms)
  instead of vanishing.
- **Fix**: the first-load live → replay switch is decided in the same state
  batch as the track load, so the live maps no longer start an animated
  fit right before being unmounted (orphaned Leaflet zoom timer threw
  `_leaflet_pos` on a removed map).

## 0.21.30 (2026-08-28)
- **Trail-TV auto-switches to replay once the pack is home**: a screen
  opened the morning after a run stayed in live mode (whole-run map, no
  front-runner cam, no photo takeovers) until 24h after the start. Now
  live mode flips to replay as soon as tracks exist but nobody has
  reported a position in the last 30 minutes. `?mode=` and the on-screen
  toggle still pin the mode.
- **Trail-TV photo takeovers shortened**: 4s in replay (was 12s), 10s in
  live mode.

## 0.21.29 (2026-08-26)
- **Photos resized + compressed before serving**: Trail-TV carousel and
  takeovers, PackTrack map markers, callouts, and lightbox now load
  server-resized WebP renditions via the Next image optimizer (256 /
  1080 / 1920px tiers) instead of multi-MB originals — a ~1.4MB photo
  becomes ~19KB as a map marker. Falls back to the original blob if the
  optimizer is unavailable; downloads still serve the full-res original.
  Deploys must now stage with `scripts/stage-standalone.sh`, which
  injects the Linux x64 sharp binaries into the standalone bundle.

## 0.21.28 (2026-08-25)
- **Trail-TV**: front-runner cam motion smoothing — a critically-damped
  spring camera eases in and out of motion (no more per-tick jumps),
  the map pans without churning tiles, and the cam only switches
  leaders when a runner is 15m clear (no ping-pong between
  neck-and-neck runners).

## 0.21.27 (2026-08-25)
- **Trail-TV / PackTrack photos**: photo list fetches now bypass the
  browser cache, so a photo set back to private drops off an open
  Trail-TV screen within one poll cycle. (Server-side permission
  filtering was verified correct — private photos were never served.)

## 0.21.26 (2026-08-25)
- **Trail-TV**: the photo carousel eases to a stop while a photo takeover
  is showing and eases back up afterwards.

## 0.21.25 (2026-08-25)
- **Trail-TV**: replay playback pauses while a photo takeover is on
  screen, resuming where it left off.

## 0.21.24 (2026-08-25)
- **Trail-TV**: runner name chips on head dots (live map + front-runner
  cam) plus a colored-dot legend; photo carousel now measures real
  overflow so photos never vanish on narrow screens.

## 0.21.23 (2026-08-25)
- **Trail-TV**: carousel photos fit the panel width uncropped (no more
  cut-off heads); front-runner cam ~3x tighter zoom.

## 0.21.22 (2026-08-25)
- **Trail-TV replay**: two maps — a front-runner cam that follows the
  leader (with the pack in frame) above the whole-run progress view.
- **Trail-TV fixes**: photo carousel no longer goes blank with few
  photos; photo takeovers finish before the next one fires.

## 0.21.21 (2026-08-25)
- **Trail-TV** (`/[slug]/[runNumber]/trail-tv`): big-screen event wall.
  Live mode: live tracks, 10-second run loop, scrolling approved-photo
  carousel, trail-mark callouts, stats ticker, follow-along QR. Replay
  mode (auto after 24h): full-run replay at 1 min/km of the first
  finisher's trail with photo takeovers synced to capture times. New
  approved photos take over the screen ("Fresh from trail").

## 0.21.20 — 2026-08-23

- **Viewer-local run times on cards and lists**: when a visitor's clock
  differs from the kennel's, run cards, the Upcoming Runs list, and the
  Featured Run card now show "JST · 12:00 your time" alongside the kennel
  time (the run detail page already had this). Computed client-side after
  hydration; invisible for kennel-local visitors.

## 0.21.19 — 2026-08-18

- PackTrack photo lightbox: new Download button saves the photo to the viewer's device (streamed same-origin so it works on phones)
- PackTrack photo lightbox: backdrop is now the kennel's website background (Harrier Central jungle tile when none is set) instead of plain black; next/back buttons enlarged

## 0.21.18 — 2026-08-16

- PackTrack: a mid-track On Inn (runner tapped it, then resumed) no longer truncates the drawn track or shows its icon — only an On Inn that is effectively the runner's last point ends the trail (matches the mobile app)

## 0.21.17 — 2026-07-25

- PackTrack spectator harmonised with the app: photo zoom is rock-controlled via tilt (zoom one way, then the other, depending on the rock), and the speed chip turns orange when tracking backward

## 0.21.16 — 2026-07-25

- PackTrack photo showcase now sweeps the photo in from the right and out to the left (mirrored on a reverse crossing), matching the app, so the navigation direction is obvious

## 0.21.15 — 2026-07-25

- PackTrack spectator renders the new glyph/text trail marks as square tiles (monochrome glyphs tinted, Caution full-colour, text stacked on spaces); legacy circular marks are unchanged

## 0.21.14 — 2026-07-12

- PackTrack tilt: widened the neutral (paused) zone so there's latitude to hold the phone at the stop-point without drifting in/out; the speed bubble now turns red with a pause icon while in that neutral zone

## 0.21.13 — 2026-07-12

- PackTrack photo showcase: photos now come only from the selected runner's track (no more pop-ins from an offscreen track); the zoom triggers when navigating backwards as well as forwards
- PackTrack photo showcase (tilt): removed the fixed timer — zoom in/out rate now follows the tilt-driven playback speed (tilt away = faster, tilt to the stop-point = freeze the photo at its current zoom), the same going forwards or backwards

## 0.21.12 — 2026-07-12

- Fix: PackTrack photo showcase now always auto zooms back out (in → hold → out) instead of holding at full; screen tilt scales the in/out rate, and the zoom-in is quicker

## 0.21.11 — 2026-07-12

- New: opt-in photo showcase on the PackTrack map (📷 camera toggle) — playback pauses as each Hash Flash photo is reached, zooming it out of its map pin and back; ~3 s at ×1 (scaled by playback speed), or hand-driven by screen tilt (tilt away to zoom in, back to dismiss)

## 0.21.10 — 2026-07-11

- New: "Harrier Central 3.0" adventure-style title banner across the top of the PackTrack map (embedded run card, full-screen, and full-page views)

## 0.21.9 — 2026-06-27

- New: filter PackTrack playback by trail type — chips for the trail types present on a run, with a per-runner trail emoji badge (track colours still mark runner identity)

## 0.21.8 — 2026-06-26

- New: PackTrack live run tracking on public run pages — animated GPS trails, per-runner playback, trail-mark icons
- New: shareable full-screen PackTrack URL — /<slug>/<run>/packtrack (e.g. hashruns.org/lh3/2839/packtrack)
- New: runner names resolved on PackTrack tracks (via publicWeb_getEventRunners)

## 0.21.7 — 2026-06-14

- Fix: past runs not loading on hashruns.org — bucket date format mismatch (ISO string vs YYYY-MM-DD)

## 0.21.6 — 2026-05-29

- Security: admin session cookie upgraded to sameSite strict
- Security: rehype-sanitize added — blocks script/event handler injection in admin-authored markdown
- Security: HTTP security headers added (X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy)
- Security: OTP redemption rate-limited (10 req/min per IP)
- Security: X-Internal-Secret header sent to PublicWebAdminApi on save-layout
- Fix: slug cache now has 10-minute TTL and 500-entry size cap
- Fix: date format validation on global-runs API route
- Fix: admin page returns 401 instead of 200 on unauthenticated access

## 0.21.4 — 2026-05-11

- Calendar view: day separator line moved above the date header so date and its runs are visually grouped together

## 0.21.3 — 2026-05-11

- Kennel logos no longer clipped to any shape across all render locations (StickyNav, RunDetail, RunsPageClient, GlobalRunsList, guest run attribution badge)
- RichText: raw HTML enabled via rehype-raw — `<u>`, `<mark>`, `<details>`, `<sup>`, `<sub>` etc. work in both Rich Text and Content blocks
- RunListBlock: "Scroll container on desktop" checkbox — limits height to ~one screen, scrolls internally; no effect on mobile

## 0.21.2 — 2026-05-11

- Guest run page: runs from other kennels open within the host kennel's theme with attribution and external link
- Clean URLs on custom domains: `londonhash.uk/guest/CityH3/1921` instead of `londonhash.uk/lh3/guest/CityH3/1921`
- `isCustomDomain` flag threaded from middleware header through all page server components into context

## 0.21.1 — 2026-05-11

- Fix: RichText colour parameter now applies to headings and bold text, not just body paragraphs
- Fix: Events page was passing empty run arrays to the renderer — promoted events now display correctly
- Fix: `IsPromotedEvent` and `EventGeographicScope` added to `publicWeb_getEvents` and `publicWeb_getMultiKennelRuns` SPs
- RunListBlock: new "Flat" view type — same layout as Card without background, shadow, or border
- RunListBlock: "Show divider" option with configurable colour and width between run entries
- RunListBlock: run name colour and detail text colour properties
- RunListBlock: "Events only" checkbox now correctly filters on `IsPromotedEvent`
- RunCardView: each field on its own line with consistent text sizing; date moved into the detail stack
- RunCalendarView: time and location split onto separate lines

## 0.21.0 — 2026-05-10

### RunListBlock overhaul

- Card view and calendar view types selectable via dropdown
- Display toggles for run number, name, date, time, location, hares, and run image
- Kennel logo and kennel name tri-state (always / multi-kennel only / never) with logo size selector (S/M/L/XL)
- Multi-kennel support: comma-separated slug list fetches runs from other kennels via new `publicWeb_getMultiKennelRuns` SP; runs merged and sorted; kennel badges shown automatically
- Max runs and max days filters (0 = no limit); skip-next-run toggle
- Calendar view: grouped by date with day headers; optional empty-day rows; kennel logo column at far left when multi-kennel

### NextRunBlock

- Run offset (−5 to +10): positive = future runs, negative = past runs
- Hide-when-no-run checkbox and optional placeholder text when no run exists at the selected offset
- Full display toggles: run number, name, date, time, location, hares, description, tags, embedded map, image

### Rich Text Block (new)

- New block for long-form prose: markdown with inline links, headings (H1–H4), bullet/numbered lists, bold, italic, blockquote, horizontal rule
- Constrain-to-readable-width option (max-w-2xl)

### ContentBlock

- Body field upgraded to markdown — inline links, headings, and bullet lists now supported

### FeaturedRunCard

- Embedded Leaflet map showing run start location (dynamically imported)
- Tag pills rendered from decoded run tag bitflags
- All fields individually toggleable via display options

### RowBlock

- Migrated from deprecated Puck DropZone API to slot fields; `migrate()` called in renderer and editor for backward compatibility with existing layouts
- Responsive collapse-below breakpoint selector (Small / Medium / Large / Never)

### Infrastructure

- `middleware.ts` renamed to `proxy.ts` (Next.js 16 deprecation fix)
- `publicWeb_getMultiKennelRuns` SP deployed — cross-kennel run query with kennel name, logo, and colours per row
- LH3 About page assembled from Rich Text and Content blocks

## 0.20.0 — 2026-05-09

### Row block

- New Row block: 2, 3, or 4 columns selectable via button group
- Per-column flex widths via dropdowns (1–10); unused columns greyed out
- Column gap (None / Small / Medium / Large / XL) and vertical alignment (Top / Centre / Stretch)
- Any block type can be dropped into each column; RowBlock nesting is disallowed

### Common block properties

- Background colour and padding controls added to all blocks that didn't have them (Next Run, Run List, Runs Page, Events List, Songs List, Stats List, Button, Row)
- About block removed — Content block covers the same use case

## 0.19.0 — 2026-05-09

### ContentBlock (formerly ImageTextBlock)

- Renamed `ImageTextBlock` → `ContentBlock` (display label and internal Puck key; existing saved layouts unaffected)
- Separate heading and body colour dropdowns (theme tokens + named colours) replacing the single unified text colour
- Separate heading and body alignment controls — heading supports Left / Centre / Right; body adds Full (justify)
- Heading / body gap: single cycling button (— / S / M / L / XL) between the two; defaults to L (16px); `—` collapses to flush

### ContentBlock — button

- Optional link button positioned above or below block content via a visual 2×3 grid (↖↑↗ / ↙↓↘); clicking an active cell removes the button
- Target page picker populated from all non-draft kennel pages
- Button text, text colour, text alignment, and button colour controls
- Icon picker: 20 curated Lucide icons shown as a visual 4-column grid, covering template pages (Music/songs, Route/runs, Calendar/events, BarChart2/stats, Info/about, UserPlus/join) and common actions (ArrowRight, ExternalLink, Mail, Phone, Globe, Download, Star, Heart, Share2, Plus)
- Icon position: Before text / After text / Icon only

### ContentBlock — padding controls

- All four padding dropdowns replaced with a compact cross-shaped control (↑ ← → ↓); each arm cycles through named steps on click and highlights blue when non-zero
- Block padding (vertical px, horizontal %): — / S / M / L / XL; sits at the top of the panel just below the Layout selector
- Image padding and Text padding (all sides px): — / S / M / L / XL; zero default, placed below their respective field groups
- Button padding (spacing between button and adjacent content, all sides px): — / S / M / L / XL; sits below Button colour

### Portal

- Removed the Welcome Text field from the Kennel Website → Content tab; use a Content Block in the page builder instead

## 0.18.0 — 2026-05-08

### Puck page management panel

- New left-side panel (toggle with Layers icon in editor header) lists all pages with Globe (active/draft) and Eye (in menu/url-only) controls
- Drag-to-reorder pages; default pages shown in bold; draft pages greyed out
- Add custom pages with an auto-generated, validated slug; delete custom pages (default pages cannot be deleted)
- Custom pages served at `/[slug]/[pageSlug]`; draft pages return 404; url-only pages are accessible by URL but hidden from the nav
- Page dropdown in the editor header replaced with a text label showing the current page name

### Navigation

- `StickyNav` now reads page visibility from `SiteConfig` — the designer controls which pages appear in the menu, replacing the old portal `pageFeatures` flags
- All public pages (Home, Runs, About, Events, Songs, Stats, custom) pass designer-controlled nav items to the nav bar

### ButtonBlock

- New block: a link button with target page picker (populated from all non-draft pages), style (Primary / Outline / Ghost), alignment (Left / Centre / Right), and top/bottom padding

### ImageTextBlock

- Border toggle (show/hide), border colour (theme token), border width (1–8px), and corner radius (0–64px)

### Data model

- `SiteConfig` replaces `PageLayoutBlob` — page layouts, visibility state, and display order are unified in one JSON blob stored in `HC.KennelWebsite.PageLayoutJson`
- `WelcomeBlock` removed from the Puck block picker

## 0.17.1 — 2026-05-07

### ImageTextBlock enhancements

- Image upload field in the Puck editor — picks a file, uploads to Azure Blob Storage (`kennel-web-images` container) via admin-authenticated API route, stores the public blob URL
- Layout dropdown: side-by-side ratios (10%–90%), Image only, Text only, Image above text, Text above image
- Top/bottom padding presets: None / Small (16px) / Medium (40px) / Large (80px) / XL (128px)
- Left/right padding: 0–30% in 5% steps
- Block background colour: Transparent (default) or any kennel theme token
- Text colour: Default or any kennel theme token

### Puck editor canvas

- Canvas now renders the kennel's actual background (image + blur + colour overlay) so text and background colour choices preview accurately
- Kennel CSS theme variables (`--kennel-primary`, `--kennel-text-title`, etc.) set on `<html>` in the admin layout page so all `var(--kennel-*)` tokens resolve correctly in the editor

## 0.17.0 — 2026-05-05

### Multi-page Puck editor

- Page dropdown in the editor header lets admins switch between Home, Runs, About, Events, Songs, and Stats
- Switching pages with unpublished changes prompts "Publish & Switch", "Discard & Switch", or "Cancel"
- Publish shows a green/red toast confirming success or failure
- All six page layouts stored in a single `PageLayoutJson` blob (keyed by page type); backward-compatible with existing single-page blobs
- `lib/page-layout.ts` centralises `PageType`, `PageLayoutBlob`, page labels, and per-page default layouts

### New Puck blocks

- `RunsPageBlock` — wraps the full runs page client (search, filter, pagination, side panel)
- `AboutBlock` — renders kennel description / welcome text with fallback copy
- `EventsListBlock` — placeholder for the upcoming Events feature
- `SongsListBlock` — wraps the full songs list; shows empty state when kennel has no songs
- `StatsListBlock` — wraps the full stats table with sort controls

### Public page routes updated

- `/[slug]/runs`, `/about`, `/events`, `/songs`, `/stats` now all load the saved Puck layout (or page default) and render via `PuckRenderer`
- Each page only fetches the data its blocks need; page-specific data (songs, stats, runs) is passed through `KennelDataContext`

### KennelDataContext

- Added optional `songs`, `statsRows`, and `hasherCount` fields so all page data is accessible to blocks
- Editor page fetches all data up-front so any block can be placed on any page

---

## 0.14.1 — 2026-05-03

### Timezone-aware future/past run boundaries
- Future runs: a run stays in the upcoming list for 8 hours after its local start time, so a morning run is still visible that evening
- Past runs: a run appears in the past list as soon as its local start time passes
- Runs appear in both lists during the 8-hour overlap window — intentional
- Uses `EventStartDateTimeGmt` (UTC equivalent maintained by trigger via Kennel→City→Timezone); falls back to `EventStartDatetime` for kennels without a city/timezone configured
- Applied to both `publicWeb_getGlobalRuns` and `publicWeb_getEvents`

### No upcoming run — sticky nav fix
- When a kennel has no upcoming run the sticky nav now shows immediately at full opacity instead of rendering as an invisible bar waiting to fade in

### Version display
- `GlobalRunsList` was showing a hardcoded `0.9.0`; now reads `NEXT_PUBLIC_APP_VERSION` like the rest of the app
- `NEXT_PUBLIC_APP_VERSION` is injected at build time from `package.json` in `next.config.ts` — single source of truth

---

## 0.14.0 — 2026-05-03

### Run detail — unified shared component
- Eliminated all separate run detail implementations (modal, inline panel, standalone page variants)
- New shared `RunDetail` component (`components/kennel/RunDetail.tsx`) used by every surface: kennel runs page side panel, kennel run standalone page, and global runs detail panel
- `RunDetailModal` removed entirely — photo grid cards now navigate directly to the run page
- `RunDetailRun` and `RunDetailKennel` minimal interfaces allow both `RunEvent` and `GlobalRunRow` to satisfy the component's props without casting

### Run detail — redesigned layout
- Section dividers (horizontal rule + centred dot) between major sections instead of per-row borders
- Row labels: golden yellow (`--kennel-accent`), bold, right-aligned
- Row values: white, bold
- Section headings: `text-2xl font-semibold`, accent colour, centred
- Large kennel logo (`h-20 w-20`) in header
- Action buttons: large pill style (`px-5 py-2.5 text-sm`)
- Location split into its own section; added Region and Country rows
- `extraButtons` prop allows callers (global runs panel) to inject additional buttons inline with the action row

### Run detail — global runs panel
- QR code and kennel website buttons moved inline with the main action buttons via `extraButtons`
- Accent colour default corrected to golden yellow (`#eab308`); was orange (`#f97316`)

### SP: publicWeb_getEvents
- Added `SyncLocationRegion AS LocationRegion` and `SyncLocationCountry AS LocationCountry` to SELECT
- `RunEvent` TypeScript interface updated to include both new fields

### SP: publicWeb_getGlobalRuns
- Added `kw.AccentColor` to SELECT for per-kennel accent theming in the detail panel

### Style tokens
- `HC.KennelWebsite` extended with `TextMutedColor` and `CardBackgroundColor` columns
- `toKennelContext()` in `kennel-utils.ts` is now the single source of truth for all theme token defaults; local copies removed from all sub-pages

---

## 0.12.0 — 2026-04-24

### SEO — per-kennel sitemaps
- Added `app/[slug]/sitemap.xml/route.ts` — a per-kennel sitemap served at `/{slug}/sitemap.xml` (or at the root of the custom domain)
- Each sitemap covers the kennel home, `/runs`, `/about`, all future runs (`changefreq: daily`), and past runs from the last 90 days (`changefreq: monthly`)
- Canonical URLs use the kennel's custom domain when configured, falling back to `hashruns.org/{slug}`
- Referenced by the global sitemap index so Google discovers all kennels from a single submission

---

## 0.8.0 — 2026-04-20

### Global Runs — past runs caching
- Past runs now fetched in fixed calendar-quarter buckets (Jan–Mar, Apr–Jun, Jul–Sep, Oct–Dec) with server-side revalidation via Next.js `fetch` cache
- Revalidation window is tiered by bucket age: 5 minutes (current quarter), 1 hour (< 6 months old), 1 week (older)
- Cache keys are permanently stable for completed quarters — adding new runs never invalidates old buckets

### Global Runs — tab switching performance
- First 100 runs render immediately on tab switch; remaining items load in the background via `startTransition`
- Eliminates the multi-second UI freeze that previously blocked the button highlight

### Global Runs — persistent tab state
- Future and past run lists are held in independent state and never reset on tab switch
- Switching back to Future Runs is instantaneous — no re-fetch

### Global Runs — today boundary fix
- SP now uses a midnight-today (`@TodayStart`) boundary instead of the exact current time
- Today's runs remain in the Future list all day and never fall off mid-event

### SP: publicWeb_getGlobalRuns
- Added `@MinEventDate` and `@MaxEventDate` parameters for fixed-quarter filtering
- Added `@TodayStart` computed column for consistent midnight boundary across count and data queries

### Custom domain support
- New `middleware.ts` — intercepts requests from unrecognised hostnames, looks up the kennel slug via `publicWeb_resolveCustomDomain`, and rewrites the URL transparently
- Resolved slug and original hostname forwarded as request headers (`x-kennel-slug`, `x-custom-domain`) for use in server components

### SP: publicWeb_resolveCustomDomain
- New stored procedure: resolves a custom domain string to a kennel slug
- Used by the middleware for per-request hostname routing

---

## 0.7.2 — 2026-04-14

Past runs fix, expanded search, tab bar redesign

## 0.7.1 — 2026-04-13

Global runs page UI overhaul — transparent background, larger cards, Avenir Next font

## 0.7.0 — 2026-04-12

ScrollBlur, KennelContext rename, remove FILTH fallback, logo/favicon from HC.Kennel
