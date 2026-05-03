# public-web Changelog

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
