import { type NextRequest, NextResponse } from "next/server";
import { getMultiKennelRuns } from "@/lib/api";

/**
 * GET /api/runs/multi-kennel?slugs=lh3,sh3&isFuture=1&maxEvents=50&daysOffset=90
 *
 * Proxies publicWeb_getMultiKennelRuns for use by client components.
 * Always returns fresh data — upcoming runs change frequently, and this
 * endpoint is used by the RunListBlock which may include runs from other
 * kennels configured by the page author.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;

  const slugs       = searchParams.get("slugs") ?? "";
  const isFutureRaw = searchParams.get("isFuture");
  const maxEvents   = searchParams.get("maxEvents");
  const daysOffset  = searchParams.get("daysOffset");

  if (!slugs.trim()) {
    return NextResponse.json({ error: "slugs is required" }, { status: 400 });
  }

  if (isFutureRaw !== "0" && isFutureRaw !== "1") {
    return NextResponse.json({ error: "isFuture must be '0' or '1'" }, { status: 400 });
  }

  const result = await getMultiKennelRuns(slugs, {
    isFuture:   isFutureRaw === "1",
    maxEvents:  maxEvents  ? parseInt(maxEvents,  10) : undefined,
    daysOffset: daysOffset ? parseInt(daysOffset, 10) : undefined,
  });

  if (!result) {
    return NextResponse.json({ totalMatchingEvents: 0, events: [] });
  }

  return NextResponse.json(result);
}
