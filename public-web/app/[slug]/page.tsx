import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { ScrollHero } from "@/components/kennel/ScrollHero";
import type { KennelContext } from "@/lib/types/kennel";
import { FeaturedRunCard } from "@/components/kennel/FeaturedRunCard";
import { UpcomingRunsList } from "@/components/kennel/UpcomingRunsList";
import { PhotoGrid } from "@/components/kennel/PhotoGrid";
import { KennelWelcome } from "@/components/kennel/KennelWelcome";
import { kennelBaseUrl } from "@/lib/seo";

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

  const base = kennelBaseUrl(slug, kennel.CustomDomain);
  const description = kennel.KennelDescription ?? `${kennel.KennelName} — hash running club`;

  return {
    metadataBase: new URL(base),
    title: kennel.KennelName,
    description,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    alternates: { canonical: base },
    openGraph: {
      type: "website",
      siteName: kennel.KennelName,
      title: kennel.KennelName,
      description,
      url: base,
      ...(ogImageUrl && { images: [{ url: ogImageUrl, alt: kennel.KennelName }] }),
    },
    twitter: {
      card: ogImageUrl ? "summary_large_image" : "summary",
      title: kennel.KennelName,
      description,
    },
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
        "--kennel-text-title": kennel.textTitleColor,
        "--kennel-text-body": kennel.textBodyColor,
        "--kennel-text-muted": kennel.textMutedColor,
        "--kennel-card-bg": kennel.cardBackgroundColor,
        "--kennel-menu-text": kennel.menuTextColor,
      } as React.CSSProperties}
    >
      <body className={`${kennel.backgroundImageUrl ? "" : "dark:bg-zinc-950 bg-zinc-50"} text-zinc-100 antialiased overflow-x-hidden`}>
        <StickyNav kennel={kennel} nextRun={events[0] ?? null} slug={slug} />
        <ScrollHero kennel={kennel} slug={slug} nextRun={events[0] ?? null} />

        <main className="relative z-10 mx-auto max-w-7xl px-4 pb-24 md:px-6">
          <KennelWelcome bannerImage={kennelData.OgImageUrl} welcomeText={kennelData.WelcomeText} slug={slug} />

          <section id="runs" className="grid min-w-0 gap-6 lg:grid-cols-[1.1fr_0.9fr]">
            <div className="min-w-0">
              {events[0] && <FeaturedRunCard run={events[0]} href={`/${slug}/${events[0].EventNumber}`} />}
            </div>
            <div className="min-w-0">
              <UpcomingRunsList runs={events.slice(1)} slug={slug} />
            </div>
          </section>

          <section className="mt-8">
            <PhotoGrid runs={pastRuns} kennel={kennel} slug={slug} />
          </section>

        </main>
      </body>
    </html>
  );
}
