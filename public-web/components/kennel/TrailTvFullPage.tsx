"use client";

import dynamic from "next/dynamic";

// Leaflet needs the DOM — client-only, same pattern as PackTrackFullPage.
const TrailTv = dynamic(() => import("./TrailTv"), { ssr: false });

interface TrailTvFullPageProps {
  slug: string;
  runNumber: string;
  lat: number;
  lon: number;
  eventId: string;
  publicEventId: string;
  eventName: string;
  kennelName: string;
  eventStartMs: number | null;
  initialMode: "live" | "replay" | null;
}

/** Client wrapper for the `/[slug]/[runNumber]/trail-tv` event wall. */
export function TrailTvFullPage(props: TrailTvFullPageProps) {
  return <TrailTv {...props} />;
}
