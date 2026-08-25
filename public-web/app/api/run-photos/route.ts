import { NextRequest, NextResponse } from "next/server";

// Proxies to the PublicWebApi shim's publicWeb_getRunPhotos SP, keeping the
// upstream URL server-side. Returns the Hash Flash-approved PUBLIC photos
// (Status >= 3) for a run — used to resolve PHO:: marks on the PackTrack map.
const BASE = process.env.HC_API_URL ?? "http://localhost:7071";

interface PhotoRow {
  photoId?: string;
  BlobUrl?: string;
  Title?: string | null;
  Description?: string | null;
  uploaderDisplayName?: string | null;
}

export async function GET(req: NextRequest) {
  const publicEventId = req.nextUrl.searchParams.get("publicEventId");
  if (!publicEventId) {
    return NextResponse.json({ photos: [] });
  }

  const url = new URL(`${BASE}/api/PublicWebApi`);
  url.searchParams.set("queryType", "getRunPhotos");
  url.searchParams.set("publicEventId", publicEventId);

  try {
    const res = await fetch(url.toString(), { cache: "no-store" });
    // 404 (event not found) / 400 (SP error) — photos are optional, fall back gracefully.
    if (!res.ok) {
      console.warn(`[run-photos] upstream ${res.status}`);
      return NextResponse.json({ photos: [] });
    }
    // Shape: [[{ EventFound: 1 }], [{ photoId, BlobUrl, Title, ... }, ...]]
    const data = (await res.json()) as PhotoRow[][];
    const photos = Array.isArray(data?.[1]) ? data[1] : [];
    return NextResponse.json(
      { photos },
      // Short cache — Hash Flash approves photos DURING a live run, so new
      // approvals should surface within roughly one track-refresh cycle.
      // max-age=0: browsers must revalidate every poll — an un-approved
      // (re-privated) photo must drop from an already-open Trail-TV within
      // one poll cycle, not linger in the browser cache.
      { headers: { "Cache-Control": "public, s-maxage=30, max-age=0" } },
    );
  } catch (err) {
    console.error("[run-photos] fetch error:", err);
    return NextResponse.json({ photos: [] });
  }
}
