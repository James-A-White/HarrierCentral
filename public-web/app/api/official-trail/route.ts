import { NextRequest, NextResponse } from "next/server";
import { logWebError } from "@/lib/web-log";
import type { OfficialTrailLane, OfficialTrailLaneInfo } from "@/lib/official-trail";

// Proxies to publicWeb_getOfficialTrail: a run's official (hare's) trail,
// one lane per trail type (E5.F6.S6, 2026-10-03). The SP returns nothing
// until the run has ended, so this is never a spoiler.
const BASE = process.env.HC_API_URL ?? "http://localhost:7071";

export async function GET(req: NextRequest) {
  const publicEventId = req.nextUrl.searchParams.get("publicEventId");
  if (!publicEventId) return NextResponse.json({ lanes: [], info: [] });

  const url = new URL(`${BASE}/api/PublicWebApi`);
  url.searchParams.set("queryType", "getOfficialTrail");
  url.searchParams.set("publicEventId", publicEventId);
  try {
    const res = await fetch(url.toString(), { cache: "no-store" });
    if (!res.ok) {
      void logWebError({ source: "/api/official-trail", error: `upstream ${res.status}`, url: req.nextUrl.pathname });
      return NextResponse.json({ lanes: [], info: [] });
    }
    // Shape: [[{ EventFound, Available, OfficialTrailInfo }], [{ OfficialTrail }]?]
    const data = (await res.json()) as Record<string, unknown>[][];
    const head = data?.[0]?.[0] ?? {};
    if (head.Available !== 1) return NextResponse.json({ lanes: [], info: [] });
    const trail = JSON.parse(String(data?.[1]?.[0]?.OfficialTrail ?? "{}")) as { lanes?: OfficialTrailLane[] };
    const info = JSON.parse(String(head.OfficialTrailInfo ?? "{}")) as { lanes?: OfficialTrailLaneInfo[] };
    return NextResponse.json(
      { lanes: trail.lanes ?? [], info: info.lanes ?? [] },
      { headers: { "Cache-Control": "public, s-maxage=300, max-age=0" } },
    );
  } catch (err) {
    void logWebError({ source: "/api/official-trail", error: err, url: req.nextUrl.pathname });
    return NextResponse.json({ lanes: [], info: [] });
  }
}
