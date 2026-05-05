import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents, getPageLayout } from "@/lib/api";
import { PuckEditor } from "@/components/puck/PuckEditor";
import { defaultLayout } from "@/components/puck/defaultLayout";
import type { Data } from "@measured/puck";

interface PageProps {
  params: Promise<{ slug: string }>;
}

// Opt out of static generation — editor always needs fresh layout data.
export const dynamic = "force-dynamic";

export default async function AdminLayoutPage({ params }: PageProps) {
  const { slug } = await params;

  // Temporarily locked to LH3 while the OTP auth scheme is being built.
  if (slug !== "lh3") notFound();

  const [kennelData, layoutJson] = await Promise.all([
    getKennelLandingData(slug),
    getPageLayout(slug),
  ]);

  if (!kennelData) notFound();

  const [eventsResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  maxEvents: 20 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 20 }),
  ]);

  const futureRuns = eventsResult?.events ?? [];
  const pastRuns   = pastResult?.events   ?? [];

  const initialData: Data = layoutJson ? (JSON.parse(layoutJson) as Data) : defaultLayout;

  return (
    <html lang="en">
      <body style={{ margin: 0, height: "100vh", overflow: "hidden" }}>
        <PuckEditor
          slug={slug}
          initialData={initialData}
          pageData={{ kennelData, slug, futureRuns, pastRuns }}
        />
      </body>
    </html>
  );
}
