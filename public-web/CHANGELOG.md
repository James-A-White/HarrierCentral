# public-web Changelog

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
