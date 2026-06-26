import { NextRequest, NextResponse } from "next/server";

// Proxies to the PublicWebApi shim's publicWeb_getEventRunners SP, keeping the
// upstream URL server-side. Resolves PackTrack runner ids to display names.
const BASE = process.env.HC_API_URL ?? "http://localhost:7071";

interface RunnerRow { userId?: string; displayName?: string }

export async function GET(req: NextRequest) {
  const publicEventId = req.nextUrl.searchParams.get("publicEventId");
  const userIds = req.nextUrl.searchParams.get("userIds");
  if (!publicEventId || !userIds) {
    return NextResponse.json({ runners: [] });
  }

  const url = new URL(`${BASE}/api/PublicWebApi`);
  url.searchParams.set("queryType", "getEventRunners");
  url.searchParams.set("publicEventId", publicEventId);
  url.searchParams.set("userIds", userIds);

  try {
    const res = await fetch(url.toString(), { cache: "no-store" });
    // 404 (event not found) / 400 (SP error) — names are optional, fall back gracefully.
    if (!res.ok) {
      console.warn(`[runner-names] upstream ${res.status}`);
      return NextResponse.json({ runners: [] });
    }
    // Shape: [[{ EventFound: 1 }], [{ userId, displayName }, ...]]
    const data = (await res.json()) as RunnerRow[][];
    const runners = Array.isArray(data?.[1]) ? data[1] : [];
    return NextResponse.json(
      { runners },
      { headers: { "Cache-Control": "public, s-maxage=300" } },
    );
  } catch (err) {
    console.error("[runner-names] fetch error:", err);
    return NextResponse.json({ runners: [] });
  }
}
