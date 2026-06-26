import { notFound } from "next/navigation";
import { isNumeric, resolveKennelAndEvent } from "@/lib/run-resolve";
import { PackTrackFullPage } from "@/components/kennel/PackTrackFullPage";

interface PageProps {
  params: Promise<{ slug: string; runNumber: string }>;
}

// ── Metadata ───────────────────────────────────────────────────────────────────

export async function generateMetadata({ params }: PageProps) {
  const { slug, runNumber } = await params;
  if (!isNumeric(runNumber)) return { title: "PackTrack not found" };

  const [kennel, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennel || !event) return { title: "PackTrack not found" };

  return {
    title: `PackTrack — ${event.EventName} | ${kennel.KennelName}`,
    // The map is interactive and per-visitor; no value in indexing it.
    robots: { index: false, follow: false },
  };
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default async function PackTrackPage({ params }: PageProps) {
  const { slug, runNumber } = await params;
  if (!isNumeric(runNumber)) notFound();

  const [kennelData, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennelData || !event) notFound();
  if (event.Latitude == null || event.Longitude == null) notFound();

  return (
    <html lang="en" className="dark">
      <body className="antialiased overflow-hidden bg-black">
        <PackTrackFullPage
          slug={slug}
          runNumber={runNumber}
          lat={event.Latitude}
          lon={event.Longitude}
          eventId={event.EventId ?? event.PublicEventId}
          publicEventId={event.PublicEventId}
        />
      </body>
    </html>
  );
}
