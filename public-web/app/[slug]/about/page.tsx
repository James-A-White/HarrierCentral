import { notFound } from "next/navigation";
import { getKennelLandingData, getPageLayout } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { PuckRenderer } from "@/components/puck/PuckRenderer";
import { parseSiteConfig, getDefaultLayout, deriveNavItems } from "@/lib/page-layout";
import { kennelBaseUrl } from "@/lib/seo";
import { getIsCustomDomain } from "@/lib/server-utils";

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

  const base = kennelBaseUrl(slug, kennel.CustomDomain);
  const canonical = `${base}/about`;
  const description = kennel.KennelDescription ?? `About ${kennel.KennelName}`;

  return {
    metadataBase: new URL(base),
    title: `About | ${kennel.KennelName}`,
    description,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    alternates: { canonical },
    openGraph: {
      type: "website",
      siteName: kennel.KennelName,
      title: `About | ${kennel.KennelName}`,
      description,
      url: canonical,
    },
    twitter: { card: "summary", title: `About | ${kennel.KennelName}`, description },
  };
}


export default async function AboutPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const [layoutJson, isCustomDomain] = await Promise.all([getPageLayout(slug), getIsCustomDomain()]);
  const kennel = toKennelContext(kennelData);

  const siteConfig = parseSiteConfig(layoutJson);
  const pageLayout = siteConfig.pages.find(p => p.id === "about")?.layout ?? getDefaultLayout("about");
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
        <div className="pt-20">
          <PuckRenderer
            data={pageLayout}
            pageData={{ kennelData, slug, futureRuns: [], pastRuns: [], isCustomDomain }}
          />
        </div>
      </body>
    </html>
  );
}
