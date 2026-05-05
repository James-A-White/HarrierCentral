import { notFound } from "next/navigation";
import { getKennelLandingData, getPageLayout } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { PuckRenderer } from "@/components/puck/PuckRenderer";
import type { PageLayoutBlob } from "@/lib/page-layout";
import { defaultLayouts } from "@/lib/page-layout";

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

  return {
    title: `Events | ${kennel.KennelShortName}`,
    description: `Events for ${kennel.KennelName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
  };
}


export default async function EventsPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const layoutJson = await getPageLayout(slug);
  const kennel = toKennelContext(kennelData);

  const blob: PageLayoutBlob = layoutJson ? (JSON.parse(layoutJson) as PageLayoutBlob) : {};
  const pageLayout = blob.events ?? defaultLayouts.events;

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
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />
        <div className="pt-20">
          <PuckRenderer
            data={pageLayout}
            pageData={{ kennelData, slug, futureRuns: [], pastRuns: [] }}
          />
        </div>
      </body>
    </html>
  );
}
