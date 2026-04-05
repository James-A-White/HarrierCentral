# Public Web — Claude Code Context

This file covers the `/public-web` Next.js application only.
Read the root `CLAUDE.md` first for the overall Harrier Central architecture.

---

## What This App Is

A multi-tenant Next.js application that hosts a full public website for every
registered kennel from a single deployment. Each kennel gets its own visual
identity, URL, and content — served from shared page templates.

---

## URL / Tenancy Model

| Tier | URL Form | Who controls DNS? | Status |
|------|----------|-------------------|--------|
| 2 (default) | `a.harriercentral.com` | Harrier Central (wildcard `*.harriercentral.com`) | Every kennel gets this automatically |
| 3 (upgrade) | `a.com` | The kennel | Custom domain; requires `Kennel.customDomain` record in DB |

Tier 1 (`harriercentral.com/a/`) is intentionally skipped.

### Tenant Resolution

Next.js middleware inspects every request's hostname and resolves a kennel slug:

- `a.harriercentral.com` → slug `a`
- `a.com` → slug looked up from `Kennel.customDomain` in DB → `a`

All page components receive the resolved `KennelContext` and may only fetch
data scoped to that kennel. Cross-kennel data access is never permitted.

### Canonical URLs

If a kennel is on tier 3, all tier 2 URLs must redirect (301) to the custom
domain. The canonical `<link>` always points to the authoritative domain to
avoid duplicate content penalties.

---

## User Populations

Three distinct user populations with separate access levels. Auth uses
NextAuth.js (email/password) — entirely separate from the Flutter portal's
device-bound token system.

| Population | Who | Access |
|------------|-----|--------|
| **Public** | Anyone, unauthenticated | Run calendar, recent trails, club info, social links, new runner info |
| **Member** | Logged-in registered member of *this kennel* | All public content + member roster, GPS trails, mis-management contacts, hash counts, member-only pages |
| **Admin** | Logged-in committee member of *this kennel* | All member content + web content management (edit runs, manage members, kennel settings) |

**Key rules:**
- All roles are kennel-scoped — an admin of kennel A has no elevated access on kennel B
- A hasher can be a Member of multiple kennels; their role is resolved per request
- Admin here means web content management, not platform administration
  (platform admin lives in the Flutter portal)

---

## Tech Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Next.js App Router | ISR for SEO, middleware for tenant resolution, per-tenant metadata |
| Styling | Tailwind CSS | Utility-first; theme tokens injected as CSS custom properties |
| Components | shadcn/ui | Radix UI primitives; copy-into-project model; we own the code |
| Animation | Framer Motion | Scroll-triggered entrances, hover states, page transitions |
| Smooth scroll | Lenis (`react-lenis`) | Applied globally; gives a premium feel without being distracting |
| Maps | React-Leaflet | OSM tiles, GPX trail overlay, elevation markers, directions |
| Charts | Recharts | Elevation profiles for run trails |
| Auth | NextAuth.js | Email/password; session is kennel-scoped |

---

## Theming System

Each kennel configures two things: a **colour identity** and a **theme mode**.
Both are stored in the DB and applied at the tenant-resolution layer.

### Theme Mode

Kennels choose `light` or `dark`. This maps directly to Tailwind's `class`
dark mode strategy — the tenant layer sets or omits the `dark` class on `<html>`.

| Mode | Base surface | Card surface | Body text | Kennel colour role |
|------|-------------|--------------|-----------|-------------------|
| **Light** | `white` / `zinc-50` | `white` | `zinc-900` | Accent — buttons, borders, active states |
| **Dark** | `zinc-950` | `zinc-900` / `white/8` glassmorphism | `zinc-100` | Accent + subtle radial gradient behind hero |

🧠 **Why Tailwind's `class` strategy?** It means we flip the entire theme by
toggling one class on `<html>` — no JavaScript theme context, no prop drilling.
Every component uses `dark:` variants. shadcn/ui already works this way out of the box.

### Colour Tokens

Injected as CSS custom properties on `<html>` by the tenant-resolution layer:

```css
--color-primary        /* kennel's primary brand colour (hex) */
--color-primary-fg     /* foreground on primary — auto-derived for WCAG AA contrast */
--color-accent         /* secondary accent colour (optional; falls back to primary) */
```

These are referenced in Tailwind config via `theme.extend.colors` so you can
write `bg-kennel-primary`, `text-kennel-primary-fg`, etc.

### Dark Mode Hero Gradient

In dark mode the hero background uses the kennel's primary colour as a subtle
radial tint — never as a dominant backdrop:

```css
background: radial-gradient(circle at top, color-mix(in srgb, var(--color-primary) 16%, transparent), transparent 32%),
            linear-gradient(135deg, #1c1917 0%, #18181b 35%, #09090b 100%);
```

In light mode, a lighter variant of the primary colour is used for section
accents and dividers only.

### Rules

- Never hardcode a kennel colour in a component — always use `var(--color-primary)`
  or the `kennel-primary` Tailwind token
- Every component must be built and tested in **both** light and dark modes
- Never sacrifice readability for brand colour — contrast takes priority
- The `dark` class is set server-side at the tenant layer — never toggle it client-side
- `prefers-color-scheme` is intentionally ignored — the kennel's stored preference
  overrides the user's OS setting (the kennel controls its brand, not the visitor)

---

## Design Language

### Inspiration Sources

| Site | What to borrow | What to avoid |
|------|---------------|---------------|
| **Brighton Hash** (brightonhash.co.uk) | Content model, GPX trails, elevation profiles, run detail depth | Generic WordPress aesthetic, flat gray palette, no imagery |
| **Von Tramp H3** | Clean nav hierarchy, event-focused structure, generous whitespace | Generic Squarespace feel |
| **Phive** (phive.pt/en) | Animation techniques, fluid typography, Lenis scroll, easing curves | Full-screen colour curtains, simultaneous multi-property animations, saturated dominant backgrounds |
| **ChatGPT mockup** | Scroll-collapse hero (logo starts large, collapses into sticky nav on scroll); glassmorphism card style; featured run card structure (image + hares + on-after in one card) | Platform/marketing framing ("148 kennels onboarded"); perpetual float animation; hardcoded dark-only theme; manual scroll math (`scrollY / 280`) |

### Scroll-Collapse Hero Pattern

The hero uses Framer Motion's `useScroll` + `useTransform` (not manual `scrollY` math)
to scale and fade the logo/title as the user scrolls, collapsing it into the sticky nav.
The sticky nav fades in with `backdropFilter: blur(18px)` and a semi-transparent
background once scroll begins.

```
Scroll 0   → Large logo + title in hero, nav is invisible
Scroll ~280px → Logo has collapsed, nav is fully visible and sticky
```

This gives a dramatic first impression without permanently stealing vertical space.

### Typography

- **Display headings:** Strong, characterful font (not system fonts) — tight tracking
  (`letter-spacing: -0.02em`) at large sizes, fluid scaling via `clamp()`
- **Body:** Clean geometric sans-serif — legible, neutral
- **Hierarchy:** Size + weight + tracking together, not size alone
- **Fluid scaling example:**
  ```css
  font-size: clamp(2.5rem, 1.5rem + 4vw, 5rem);
  ```

### No Horizontal Scrolling

**Horizontal scrolling is forbidden on every page, with the sole exception of
embedded maps.** Violations break the mobile experience and are treated as bugs.

Rules:
- `html` must always have `overflow-x: hidden` (set in `globals.css`) — `body` alone
  is not sufficient; browsers propagate overflow inconsistently between the two
- Never use Framer Motion `x` transforms on scroll-triggered entrance animations —
  they push elements outside the viewport during load, triggering a horizontal
  scroll position. Use `y` instead
- All flex and grid children that may contain text must have `min-w-0` to allow
  shrinking below their intrinsic size
- Fixed-width elements (`w-60`, `w-48`, etc.) inside flex rows must be verified on
  narrow screens (320px) before shipping

---

### Animation Principles

Use Phive's techniques at ~30% intensity. One animated property at a time.

| Effect | Rule |
|--------|------|
| Smooth scroll | Lenis at full intensity — always on |
| Scroll-triggered entrances | Fade + translateY(20px) → 0, word or line level (not character) |
| Button hover | `scale(1.02)`, `0.15s`, easing `[0.19, 1, 0.22, 1]` |
| Card hover | Subtle shadow lift + `scale(1.01)` |
| Page transitions | Simple opacity fade, `0.3s` — no full-screen curtains |
| Hover colour shifts | `0.2s` max — never `0.5s+` |
| Simultaneous transforms | Never animate more than one property at a time per element |

**Easing curves (from Phive):**
```js
// Primary — bouncy exit
[0.19, 1, 0.22, 1]

// Secondary — smooth ease
[0.075, 0.82, 0.165, 1]
```

### Imagery

- Hash runs are outdoor, social, community events — photography should reflect this
- Pack photos, trail landscapes, post-run pub scenes
- Each kennel uploads its own imagery; templates must degrade gracefully
  when no images are provided (use placeholder gradients, not broken layouts)

---

## Content Model

Based on Brighton Hash's information depth as the target.

### Public Pages (every kennel)

| Page | Key Content |
|------|-------------|
| Home | Hero, next run preview, recent trail card, join CTA, social links |
| Upcoming Runs | Paginated list — date, location, hares, difficulty, RSVP count |
| Run Detail | Full run info: location + postcode, hare assignments, embedded map, GPX trail + elevation profile, distance/elevation stats, post-run pub |
| Run Archive | Past runs with photos, trails, attendance counts |
| About | Club history, mis-management contacts, what is hashing? |
| Join | New runner guide |

### Member Pages (login required)

| Page | Key Content |
|------|-------------|
| Member Area | Hash count, nickname, sashing records, upcoming RSVPs |
| Member Directory | Hasher profiles, nicknames, hash counts |
| Trails | Full GPX downloads, detailed maps |

### Admin Pages (login required, admin role)

| Page | Key Content |
|------|-------------|
| Run Management | Add/edit/delete runs, assign hares |
| Member Management | Approve members, assign roles |
| Kennel Settings | Logo, colours, about text, social links |
| Content | Edit static pages (About, Join) |

---

## API Layer

### Shim Endpoint

The public web calls the **PublicWebApi** shim (`api/Endpoints/PublicWebApi.cs`):

```
GET /api/PublicWebApi?queryType=<spSuffix>&<param>=<value>...
```

- Unauthenticated (anonymous) GET
- Routes to `[HC6].[publicWeb_{queryType}]` stored procedures
- Returns `[[row, ...], [row, ...]]` — array of result sets
- Returns HTTP 404 when the SP returns an empty first rowset (kennel not found)
- Returns HTTP 400 with `{ success: false, errorMessage: "Invalid request." }` on SP errors
  (internal error details are never exposed publicly)

### SP Naming Convention

All public web SPs live in `/db/hc6/public-web/` and use the `publicWeb_` prefix:
- `HC6.publicWeb_getLandingPageData` — kennel identity for landing page
- Future: `HC6.publicWeb_getUpcomingRuns`, `HC6.publicWeb_getRunDetail`, etc.

### SP Rules

- **Never reference HC.Kennel Website\* columns as fallbacks.** No kennel has data
  in HC5's `WebsiteBannerImage`, `WebsiteBackgroundColor`, `KennelLogo`, `KennelFavicon`,
  `WebsiteTitleText`, `KennelSeoTitle`, `KennelSeoDescription`, etc. for the HC6 public web.
  All website styling and content comes from `HC.KennelWebsite` only.
- **FILTH is the platform-level style default.** When a kennel has no value in
  `HC.KennelWebsite`, style columns fall back to the FILTH kennel's row via a second
  `LEFT JOIN HC.KennelWebsite kwf ON kwf.KennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'`.
  COALESCE order: `kw` (kennel) → `kwf` (FILTH) → hardcoded literal (ThemeMode/ScrollBlur only).
- **Kennel-specific content never inherits from FILTH.** `TitleText`, `Tagline`,
  `WelcomeText`, `SeoTitle`, `SeoDescription`, `SeoStructuredDataJson` are always
  kennel-owned — return NULL if not set, never a FILTH default.
- **HC.Kennel is joined for slug resolution and core identity only** (`KennelName`,
  `KennelShortName`, `KennelUniqueShortName`, `KennelDescription`, `deleted`, `removed`).

### Client (`lib/api.ts`)

Server-side only — never import in `"use client"` components.

```ts
// Fetch landing data for a kennel slug
const data = await getKennelLandingData("lh3");
// Returns KennelLandingData | null (null = 404)
```

- Reads `HC_API_URL` from environment (`.env.local` in dev)
- Uses `next: { revalidate: 60 }` — cached for 60s, revalidated on demand
- Throws on network / server errors (let Next.js error boundary handle it)

### Dynamic Route

`app/[slug]/page.tsx` catches any kennel slug, fetches live data, and calls
`notFound()` if the kennel doesn't exist. The `toMockKennel()` adapter bridges
the live `KennelLandingData` type to the `MockKennel` shape the components
currently expect — it will be replaced once colour/theme fields are added to the SP.

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HC_API_URL` | Dev only | Base URL of the Azure Functions shim (e.g. `http://localhost:7071`) |

In production, `HC_API_URL` is set as an environment variable on the hosting platform.

---

## SEO

- ISR (Incremental Static Regeneration) — fully rendered HTML for crawlers
- Per-tenant `generateMetadata()` — title, description, Open Graph, Twitter Card
- Per-tenant `sitemap.xml` at `/sitemap.xml` on each domain
- Per-tenant `robots.txt`
- Canonical URLs always point to the authoritative domain (tier 3 if set, else tier 2)
- Structured data (JSON-LD) for events on run pages

---

## Folder Structure (target)

```
/public-web
  /app
    /[...slug]           ← catch-all for tenant-resolved routes
    /layout.tsx          ← injects KennelContext and theme tokens
    /middleware.ts        ← tenant resolution from hostname
  /components
    /ui                  ← shadcn/ui base components
    /kennel              ← kennel-specific composed components
    /maps                ← Leaflet map and GPX components
    /charts              ← Recharts elevation profile
  /lib
    /tenant.ts           ← tenant resolution logic
    /auth.ts             ← NextAuth config
    /api.ts              ← API shim client
  /styles
    /globals.css         ← CSS custom properties, base resets
```

---

## Key Rules

- Never hardcode a kennel slug, name, or colour in any component
- Never fetch data outside the resolved kennel context
- Always use ISR (`revalidate`) — never fully dynamic unless behind auth
- Member and admin pages must be server-side protected — middleware + server
  component auth check, never rely on client-side hiding alone
- Leaflet maps must not SSR (use `dynamic(() => import(...), { ssr: false })`)
- Test all components with both light and dark kennel primary colours
- `publicWeb_` SPs must never fall back to `HC.Kennel` Website\* columns — all
  website data comes from `HC.KennelWebsite`; FILTH is the platform style default
  (see SP Rules above)
- **All non-hero sub-pages** (songs, about, run detail, etc.) must use
  `KennelBackground` (`components/kennel/KennelBackground.tsx`) to render the
  kennel's background image at full blur + max overlay opacity, matching the
  "fully scrolled" state of the landing page hero. The `<body>` on these pages
  must not set a solid background colour (omit `dark:bg-zinc-950 bg-zinc-50`
  when `kennel.backgroundImageUrl` is set, or omit it entirely and rely on
  `KennelBackground`'s gradient fallback for kennels without an image).
- **`StickyNav` on sub-pages must always pass `alwaysVisible`** — the fade-in
  animation is only appropriate on the landing page where the hero is present.
  Every non-landing page must pass `alwaysVisible` to `StickyNav` so the nav
  is visible immediately on load.

---

## Deployment Rule

**Never deploy the public web autonomously.** James may want to group multiple
features into a single deployment. Always make code changes and stop there —
do not run the build, package, or `az webapp deploy` steps unless James
explicitly says to deploy in that conversation turn.

The deploy steps when James does ask:
```bash
cd public-web
npm run build
cp -r public .next/standalone/public
cp -r .next/static .next/standalone/.next/static
cd .next/standalone && zip -rq ../../deploy.zip . && cd ../..
az webapp deploy --name harriercentralpublicweb --resource-group harrier --src-path deploy.zip --type zip
rm deploy.zip
```

---

*Last updated: April 2026 — added deployment rule; Events nav item; global calendar page*
