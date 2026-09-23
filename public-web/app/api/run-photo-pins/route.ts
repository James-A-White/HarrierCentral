import { NextRequest, NextResponse } from "next/server";
import { logWebError } from "@/lib/web-log";

// Proxies to the PublicWebApi shim's publicWeb_getRunPhotoPins SP: where and
// when each Hash Flash-approved PUBLIC photo was taken. Photos are their own
// thing — location, time, photographer — and are no longer written into any
// GPS track, so the PackTrack map and Trail TV read pins from here instead of
// from PHO:: marks. Same exposure as those marks carried; the gallery endpoint
// (/api/run-photos) still returns no coordinates.
const BASE = process.env.HC_API_URL ?? "http://localhost:7071";

interface PinRow {
  photoId?: string;
  Latitude?: number | string | null;
  Longitude?: number | string | null;
  TakenAtUtc?: string | null;
  CreatedAt?: string | null;
}

export async function GET(req: NextRequest) {
  const publicEventId = req.nextUrl.searchParams.get("publicEventId");
  if (!publicEventId) {
    return NextResponse.json({ pins: [] });
  }

  const url = new URL(`${BASE}/api/PublicWebApi`);
  url.searchParams.set("queryType", "getRunPhotoPins");
  url.searchParams.set("publicEventId", publicEventId);

  try {
    const res = await fetch(url.toString(), { cache: "no-store" });
    if (!res.ok) {
      console.warn(`[run-photo-pins] upstream ${res.status}`);
      void logWebError({ source: "/api/run-photo-pins", error: `upstream ${res.status}`, url: req.nextUrl.pathname });
      return NextResponse.json({ pins: [] });
    }
    // Shape: [[{ EventFound: 1 }], [{ photoId, Latitude, Longitude, TakenAtUtc, CreatedAt }, ...]]
    const data = (await res.json()) as PinRow[][];
    const pins = Array.isArray(data?.[1]) ? data[1] : [];
    return NextResponse.json(
      { pins },
      { headers: { "Cache-Control": "public, s-maxage=30, max-age=0" } },
    );
  } catch (err) {
    void logWebError({ source: "/api/run-photo-pins", error: err, url: req.nextUrl.pathname });
    return NextResponse.json({ pins: [] });
  }
}
