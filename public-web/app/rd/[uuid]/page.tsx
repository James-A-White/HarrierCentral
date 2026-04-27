import { notFound } from "next/navigation";
import { resolveKennelsByUuid, getKennelLandingData, getEvents } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { RunsPageClient } from "@/components/kennel/RunsPageClient";

interface PageProps {
  params: Promise<{ uuid: string }>;
}

export default async function LegacyRunsPage({ params }: PageProps) {
  const { uuid } = await params;

  const resolved = await resolveKennelsByUuid(uuid);
  if (!resolved || resolved.length === 0) notFound();

  const { KennelSlug: slug } = resolved[0];
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const [futureResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true, maxEvents: 100, summaryOnly: true }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 3650, summaryOnly: true }),
  ]);

  const futureRuns = futureResult?.events ?? [];
  const pastRuns = pastResult?.events ?? [];
  const kennel = toKennelContext(kennelData);

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
      <body className="text-zinc-100 antialiased overflow-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />
        <div className="pt-20">
          <RunsPageClient
            futureRuns={futureRuns}
            pastRuns={pastRuns}
            kennel={kennel}
            slug={slug}
          />
        </div>
      </body>
    </html>
  );
}
