import { type NextRequest, NextResponse } from "next/server";
import { getGlobalCalendar } from "@/lib/api";

/**
 * GET /api/global-calendar?fromDate=YYYY-MM-DD&daysLimit=30
 *
 * Proxy route used by the GlobalCalendar client component to load more
 * calendar rows as the user scrolls. Delegates to the same getGlobalCalendar
 * function used for the initial server render.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const fromDate = searchParams.get("fromDate");
  const daysLimitParam = searchParams.get("daysLimit");

  if (!fromDate || !/^\d{4}-\d{2}-\d{2}$/.test(fromDate)) {
    return NextResponse.json(
      { error: "fromDate is required and must be in YYYY-MM-DD format" },
      { status: 400 }
    );
  }

  const daysLimit = daysLimitParam ? parseInt(daysLimitParam, 10) : 30;

  const rows = await getGlobalCalendar({ fromDate, daysLimit });
  return NextResponse.json(rows);
}
