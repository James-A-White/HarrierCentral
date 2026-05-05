import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents, getPageLayout } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { ScrollHero } from "@/components/kennel/ScrollHero";
import { SiteFooter } from "@/components/kennel/SiteFooter";
import { PuckRenderer } from "@/components/puck/PuckRenderer";
import type { PageLayoutBlob } from "@/lib/page-layout";
import { defaultLayouts } from "@/lib/page-layout";
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

  const ogImageUrl = kennel.BannerImage?.startsWith("https://") ? kennel.BannerImage
    : kennel.OgImageUrl?.startsWith("https://") ? kennel.OgImageUrl
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

export default async function KennelPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);

  if (!kennelData) notFound();

  // ── Website disabled — show holding screen ────────────────────────────────
  if (kennelData.WebsiteEnabled === false) {
    const bgUrl = kennelData.WebsiteBackgroundImage?.startsWith("https://")
      ? kennelData.WebsiteBackgroundImage
      : "/images/jungle_background.jpg";
    const logoUrl = kennelData.KennelLogo?.startsWith("https://") ? kennelData.KennelLogo : null;

    return (
      <html lang="en" className="dark">
        <body className="overflow-hidden">
          <div
            className="fixed inset-0 scale-[1.08] bg-cover bg-center bg-no-repeat"
            style={{ backgroundImage: `url(${bgUrl})` }}
          />
          <div className="fixed inset-0 bg-black/60" />
          {logoUrl && (
            <div className="fixed inset-0 flex items-center justify-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={logoUrl}
                alt={kennelData.KennelShortName}
                className="h-auto w-[min(60vw,60vh)] max-w-[480px] object-contain drop-shadow-2xl"
              />
            </div>
          )}
        </body>
      </html>
    );
  }

  const kennel = toKennelContext(kennelData);

  // Fetch runs + saved layout in parallel — blocks slice to their own count
  const [eventsResult, pastResult, layoutJson] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  maxEvents: 20 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 20 }),
    getPageLayout(slug),
  ]);
  const futureRuns = eventsResult?.events ?? [];
  const pastRuns   = pastResult?.events   ?? [];
  const blob: PageLayoutBlob = layoutJson ? (JSON.parse(layoutJson) as PageLayoutBlob) : {};
  const pageLayout = blob.home ?? defaultLayouts.home;

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary":      kennel.primaryColor,
        "--kennel-primary-fg":   kennel.primaryFg,
        "--kennel-accent":       kennel.accentColor,
        "--kennel-text-title":   kennel.textTitleColor,
        "--kennel-text-body":    kennel.textBodyColor,
        "--kennel-text-muted":   kennel.textMutedColor,
        "--kennel-card-bg":      kennel.cardBackgroundColor,
        "--kennel-btn-primary":  kennel.buttonPrimaryColor,
        "--kennel-btn-cancel":   kennel.buttonCancelColor,
        "--kennel-btn-secondary":kennel.buttonSecondaryColor,
        "--kennel-run-card-bg":  kennel.runCardBackgroundColor,
        "--kennel-menu-text":    kennel.menuTextColor,
      } as React.CSSProperties}
    >
      <body className={`${kennel.backgroundImageUrl ? "" : "dark:bg-zinc-950 bg-zinc-50"} text-zinc-100 antialiased overflow-x-hidden`}>

        {/* ── Fixed shell — always present, not configurable ───────────── */}
        <StickyNav kennel={kennel} nextRun={futureRuns[0] ?? null} slug={slug} />
        <ScrollHero kennel={kennel} slug={slug} nextRun={futureRuns[0] ?? null} />

        {/* ── Puck-rendered content area ───────────────────────────────── */}
        <main className="relative z-10 mx-auto max-w-7xl px-4 pb-8 md:px-6">
          <PuckRenderer
            data={pageLayout}
            pageData={{ kennelData, slug, futureRuns, pastRuns }}
          />
        </main>

        {/* ── Fixed footer — always present, not configurable ─────────── */}
        <SiteFooter />

      </body>
    </html>
  );
}
