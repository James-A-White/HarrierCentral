import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents, type KennelLandingData } from "@/lib/api";
import { StickyNav } from "@/components/StickyNav";
import { ScrollHero } from "@/components/kennel/ScrollHero";
import { StatsSection } from "@/components/kennel/StatsSection";
import type { KennelContext } from "@/lib/types/kennel";
import { FeaturedRunCard } from "@/components/kennel/FeaturedRunCard";
import { UpcomingRunsList } from "@/components/kennel/UpcomingRunsList";
import { PhotoGrid } from "@/components/kennel/PhotoGrid";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);
  if (!kennel) return { title: "Kennel not found" };

  const faviconUrl = kennel.FaviconUrl?.startsWith("https://") ? kennel.FaviconUrl
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  const ogImageUrl = kennel.OgImageUrl?.startsWith("https://") ? kennel.OgImageUrl
    : kennel.BannerImage?.startsWith("https://") ? kennel.BannerImage
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  return {
    title: `${kennel.KennelName} | Harrier Central`,
    description: kennel.KennelDescription ?? `${kennel.KennelName} — hash running club`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    ...(ogImageUrl && { openGraph: { images: [{ url: ogImageUrl }] } }),
  };
}

/**
 * Parses a WebsiteBackgroundColor value from the DB into a CSS color and
 * a max opacity for the scroll-driven overlay.
 *
 * Supported formats:
 *   #RRGGBB   — standard hex; max opacity defaults to 0.88
 *   #RRGGBBAA — CSS 8-digit hex (alpha last); AA drives max opacity
 */
function parseOverlayColor(raw: string | null): {
  backgroundOverlayColor: string;
  backgroundOverlayMaxOpacity: number;
} {
  if (raw && /^#[0-9A-Fa-f]{8}$/.test(raw)) {
    const maxOpacity = parseInt(raw.slice(7, 9), 16) / 255;
    return { backgroundOverlayColor: `#${raw.slice(1, 7)}`, backgroundOverlayMaxOpacity: maxOpacity };
  }
  return {
    backgroundOverlayColor: raw && /^#[0-9A-Fa-f]{6}$/.test(raw) ? raw : "#000000",
    backgroundOverlayMaxOpacity: 0.88,
  };
}

function clampScrollBlur(raw: number | null): number {
  const value = raw ?? 0;
  return Math.min(100, Math.max(0, value));
}

function parseMenuBackground(raw: string | null, theme: "dark" | "light"): {
  menuBackgroundColor: string;
  menuBackgroundOpacity: number;
} {
  const s = raw?.trim() ?? "";
  if (/^#[0-9A-Fa-f]{8}$/.test(s)) {
    // 8-digit hex: RRGGBBAA — alpha byte drives opacity
    const maxOpacity = parseInt(s.slice(7, 9), 16) / 255;
    return { menuBackgroundColor: `#${s.slice(1, 7)}`, menuBackgroundOpacity: maxOpacity };
  }
  if (/^#[0-9A-Fa-f]{6}$/.test(s)) {
    // 6-digit hex: fully opaque (use 8-digit hex to set partial opacity)
    return { menuBackgroundColor: s, menuBackgroundOpacity: 1.0 };
  }
  // null or unrecognised: theme-appropriate default
  return theme === "dark"
    ? { menuBackgroundColor: "#09090b", menuBackgroundOpacity: 0.8 }
    : { menuBackgroundColor: "#ffffff", menuBackgroundOpacity: 0.8 };
}

/**
 * Converts the live KennelLandingData from the API into the shape that
 * the existing components expect. Theme and colour defaults are used
 * until those fields are added to the SP in a future iteration.
 */
function toKennelContext(data: KennelLandingData): KennelContext {
  return {
    slug: data.KennelUniqueShortName,
    name: data.KennelName,
    shortName: data.KennelShortName,
    tagline: "",
    city: "",
    foundedYear: 0,
    primaryColor: data.PrimaryColor ?? "#dc2626",
    primaryFg: "#ffffff",
    accentColor: data.AccentColor ?? "#f97316",
    theme: "dark",
    titleText: data.WebsiteTitleText ?? undefined,
    titleTextColor: data.TitleTextColor ?? undefined,
    logoLetter: data.KennelShortName.charAt(0).toUpperCase(),
    logoUrl: data.KennelLogo?.startsWith("https://") ? data.KennelLogo : undefined,
    backgroundImageUrl: data.WebsiteBackgroundImage?.startsWith("https://") ? data.WebsiteBackgroundImage : "/images/jungle_background.jpg",
    ...parseOverlayColor(data.WebsiteBackgroundColor),
    scrollBlur: clampScrollBlur(data.ScrollBlur),
    ...parseMenuBackground(data.MenuBackgroundColor ?? null, data.ThemeMode === "light" ? "light" : "dark"),
    menuTextColor: data.MenuTextColor ?? (data.ThemeMode === "light" ? "#18181b" : "#ffffff"),
    socialLinks: {},
    stats: {
      totalRuns: 0,
      activeMembers: 0,
      photosUploaded: 0,
      yearsRunning: 0,
    },
  };
}

export default async function KennelPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);

  if (!kennelData) notFound();

  const kennel = toKennelContext(kennelData);

  const [eventsResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true, maxEvents: 10 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 50 }),
  ]);
  const events = eventsResult?.events ?? [];
  const pastRuns = pastResult?.events ?? [];

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary": kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent": kennel.accentColor,
      } as React.CSSProperties}
    >
      <body className={`${kennel.backgroundImageUrl ? "" : "dark:bg-zinc-950 bg-zinc-50"} text-zinc-100 antialiased overflow-x-hidden`}>
        <StickyNav kennel={kennel} nextRun={events[0] ?? null} slug={slug} />
        <ScrollHero kennel={kennel} slug={slug} nextRun={events[0] ?? null} />

        <main className="relative z-10 mx-auto max-w-7xl px-4 pb-24 md:px-6">
          <section id="runs" className="grid min-w-0 gap-6 lg:grid-cols-[1.1fr_0.9fr]">
            <div className="min-w-0">
              {events[0] && <FeaturedRunCard run={events[0]} href={`/${slug}/runs/${events[0].EventNumber}`} />}
            </div>
            <div className="min-w-0">
              <UpcomingRunsList runs={events.slice(1)} slug={slug} />
            </div>
          </section>

          <section className="mt-8 grid gap-6 lg:grid-cols-[1.25fr_0.75fr]">
            <PhotoGrid runs={pastRuns} kennel={kennel} slug={slug} />
            <StatsSection kennel={kennel} />
          </section>

        </main>
      </body>
    </html>
  );
}
