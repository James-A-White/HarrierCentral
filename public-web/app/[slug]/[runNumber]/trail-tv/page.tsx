import { notFound } from "next/navigation";
import { isNumeric, resolveKennelAndEvent } from "@/lib/run-resolve";
import { TrailTvFullPage } from "@/components/kennel/TrailTvFullPage";

/**
 * Trail-TV — the big-screen event wall: live tracks, a 10-second run loop,
 * and a rolling carousel of approved photos. Meant for a projector/TV at
 * events. Unlisted (not linked from navigation), like /packtrack.
 * `?mode=live` / `?mode=replay` overrides the automatic mode selection.
 */

interface PageProps {
  params: Promise<{ slug: string; runNumber: string }>;
  searchParams: Promise<{ mode?: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug, runNumber } = await params;
  if (!isNumeric(runNumber)) return { title: "Trail-TV not found" };

  const [kennel, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennel || !event) return { title: "Trail-TV not found" };

  return {
    title: `Trail-TV — ${event.EventName} | ${kennel.KennelName}`,
    robots: { index: false, follow: false },
  };
}

export default async function TrailTvPage({ params, searchParams }: PageProps) {
  const { slug, runNumber } = await params;
  const { mode } = await searchParams;
  if (!isNumeric(runNumber)) notFound();

  const [kennelData, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennelData || !event) notFound();
  if (event.Latitude == null || event.Longitude == null) notFound();

  // The run's start instant (GMT column — see /hc-event-datetimes).
  const eventStartMs = event.EventStartDatetimeGmt
    ? Date.parse(event.EventStartDatetimeGmt)
    : null;

  const initialMode = mode === "live" || mode === "replay" ? mode : null;

  return (
    <html lang="en" className="dark">
      <body className="antialiased overflow-hidden bg-black">
        <TrailTvFullPage
          slug={slug}
          runNumber={runNumber}
          lat={event.Latitude}
          lon={event.Longitude}
          eventId={event.EventId ?? event.PublicEventId}
          publicEventId={event.PublicEventId}
          eventName={event.EventName}
          kennelName={kennelData.KennelName}
          eventStartMs={Number.isFinite(eventStartMs) ? eventStartMs : null}
          initialMode={initialMode}
        />
      </body>
    </html>
  );
}
