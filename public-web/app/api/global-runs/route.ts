import { type NextRequest, NextResponse } from "next/server";
import { getGlobalRuns } from "@/lib/api";

/**
 * GET /api/global-runs
 *
 * Future runs (isFuture=1):
 *   Always fresh. Supports pageSize + offset for pagination.
 *
 * Past runs (isFuture=0):
 *   Expects minEventDate + maxEventDate defining a fixed calendar-quarter bucket.
 *   The revalidation period is computed from how old the bucket is:
 *     - Current quarter (maxEventDate >= today):  5 minutes
 *     - Recent past (bucket started < 6 months ago):  1 hour
 *     - Mid-range past (6 months – 5 years old):  1 week
 *     - Deep history (older than 5 years):  1 month
 *
 *   Fixed-quarter boundaries never shift when new runs are added, so every
 *   cache entry for a completed quarter is permanently stable until it
 *   naturally ages through the revalidation window.
 */

function getRevalidateSeconds(minEventDate: string, maxEventDate: string): number {
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);

  // Current quarter still has runs being added — short window.
  if (new Date(maxEventDate) >= todayStart) return 300;

  // Age is measured from the START of the bucket (minEventDate).
  const ageMs     = todayStart.getTime() - new Date(minEventDate).getTime();
  const ageMonths = ageMs / (1000 * 60 * 60 * 24 * 30.44);

  if (ageMonths <   6) return   3_600;  // 1 hour  — recent, edits still likely
  if (ageMonths <  60) return 604_800;  // 1 week  — stable completed quarters
  return 2_592_000;                     // 1 month — deep history, rarely changes
}

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const isFutureParam = searchParams.get("isFuture");
  const pageSizeParam = searchParams.get("pageSize");
  const offsetParam   = searchParams.get("offset");
  const minEventDate  = searchParams.get("minEventDate") ?? undefined;
  const maxEventDate  = searchParams.get("maxEventDate") ?? undefined;

  if (isFutureParam !== "0" && isFutureParam !== "1") {
    return NextResponse.json(
      { error: "isFuture must be '0' or '1'" },
      { status: 400 }
    );
  }

  const isFuture = isFutureParam === "1";

  // ── Future runs ─────────────────────────────────────────────────────────────
  // Always fresh — upcoming events change frequently.

  if (isFuture) {
    const pageSize = pageSizeParam ? parseInt(pageSizeParam, 10) : 200;
    const offset   = offsetParam   ? parseInt(offsetParam,   10) : 0;
    const result = await getGlobalRuns({ isFuture: true, pageSize, offset });
    return NextResponse.json(result);
  }

  // ── Past runs: single fixed-quarter bucket ───────────────────────────────────

  if (!minEventDate || !maxEventDate) {
    return NextResponse.json(
      { error: "minEventDate and maxEventDate are required for past runs" },
      { status: 400 }
    );
  }

  const revalidate = getRevalidateSeconds(minEventDate, maxEventDate);
  const result = await getGlobalRuns(
    { isFuture: false, minEventDate, maxEventDate, pageSize: 5000 },
    { next: { revalidate } }
  );

  return NextResponse.json(result, {
    headers: { "Cache-Control": `public, max-age=${revalidate}, stale-while-revalidate=${revalidate * 2}` },
  });
}
