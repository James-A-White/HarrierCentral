# public-web Changelog

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
