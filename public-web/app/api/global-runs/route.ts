import { type NextRequest, NextResponse } from "next/server";
import { getGlobalRuns } from "@/lib/api";

/**
 * GET /api/global-runs?isFuture=1&pageSize=50&offset=0
 *
 * Proxy route used by the GlobalRunsList client component to load more
 * runs as the user scrolls or switches between Future/Past tabs.
 * Delegates to the same getGlobalRuns function used for the initial
 * server render.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const isFutureParam = searchParams.get("isFuture");
  const pageSizeParam = searchParams.get("pageSize");
  const offsetParam   = searchParams.get("offset");

  if (isFutureParam !== "0" && isFutureParam !== "1") {
    return NextResponse.json(
      { error: "isFuture must be '0' or '1'" },
      { status: 400 }
    );
  }

  const isFuture = isFutureParam === "1";
  const pageSize = pageSizeParam ? parseInt(pageSizeParam, 10) : undefined;
  const offset   = offsetParam   ? parseInt(offsetParam,   10) : undefined;

  const result = await getGlobalRuns({ isFuture, pageSize, offset });
  return NextResponse.json(result);
}
