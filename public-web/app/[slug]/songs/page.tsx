import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { notFound } from "next/navigation";
import { getKennelLandingData, getSongs, getPageLayout } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { PuckRenderer } from "@/components/puck/PuckRenderer";
import { parseSiteConfig, getDefaultLayout, deriveNavItems } from "@/lib/page-layout";
import { getIsCustomDomain } from "@/lib/server-utils";

interface PageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ back?: string }>;
}

/** Only ever follow an in-site path back, never an absolute URL. */
function safeBack(back: string | undefined): string | null {
  return back && back.startsWith("/") && !back.startsWith("//") ? back : null;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);
  if (!kennel) return { title: "Kennel not found" };

  const faviconUrl = kennel.FaviconUrl?.startsWith("https://") ? kennel.FaviconUrl
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  return {
    title: `Songs | ${kennel.KennelShortName}`,
    description: `Song book for ${kennel.KennelName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
  };
}


export default async function SongsPage({ params, searchParams }: PageProps) {
  const [{ slug }, sp] = await Promise.all([params, searchParams]);
  const back = safeBack(sp.back);
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const [songs, layoutJson] = await Promise.all([
    getSongs(kennelData.PublicKennelId),
    getPageLayout(slug),
  ]);

  const isCustomDomain = await getIsCustomDomain();
  const kennel = toKennelContext(kennelData);

  const siteConfig = parseSiteConfig(layoutJson);
  const pageLayout = siteConfig.pages.find(p => p.id === "songs")?.layout ?? getDefaultLayout("songs");
  const navItems   = deriveNavItems(siteConfig, slug);

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
        "--kennel-btn-primary": kennel.buttonPrimaryColor,
        "--kennel-btn-cancel": kennel.buttonCancelColor,
        "--kennel-btn-secondary": kennel.buttonSecondaryColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible navItems={navItems} />
        <div className="pt-20 pb-24">
          {back && (
            <div className="mx-auto w-full max-w-3xl px-4 pb-4 md:px-6">
              <Link
                href={back}
                className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50"
                style={{ color: "var(--kennel-text-body)" }}
              >
                <ArrowLeft className="h-4 w-4" />
                {back === "/me/songs" ? "Back to my songs" : "Back"}
              </Link>
            </div>
          )}
          <PuckRenderer
            data={pageLayout}
            pageData={{ kennelData, slug, futureRuns: [], pastRuns: [], songs, isCustomDomain, backHref: back ?? undefined }}
          />
        </div>
      </body>
    </html>
  );
}
