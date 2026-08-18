"use client";

import dynamic from "next/dynamic";
import { useRouter } from "next/navigation";

const PackTrackMap = dynamic(() => import("./PackTrackMap"), { ssr: false });

interface PackTrackFullPageProps {
  slug: string;
  runNumber: string;
  lat: number;
  lon: number;
  /** Event's internal id (HC.Event.id) — the PackTrack track key. */
  eventId: string;
  /** Event's public UUID — used to resolve runner display names. */
  publicEventId: string;
  /** Kennel website background image for the photo lightbox backdrop. */
  kennelBackgroundUrl?: string | null;
}

/**
 * Client wrapper for the dedicated `/[slug]/[runNumber]/packtrack` page. Renders
 * the PackTrack map full-screen; closing returns to the run detail page.
 */
export function PackTrackFullPage({
  slug, runNumber, lat, lon, eventId, publicEventId, kennelBackgroundUrl = null,
}: PackTrackFullPageProps) {
  const router = useRouter();
  return (
    <PackTrackMap
      fullPage
      lat={lat}
      lon={lon}
      eventId={eventId}
      publicEventId={publicEventId}
      kennelBackgroundUrl={kennelBackgroundUrl}
      onClose={() => router.push(`/${slug}/${runNumber}`)}
    />
  );
}
