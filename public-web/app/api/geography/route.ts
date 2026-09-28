import { NextRequest, NextResponse } from "next/server";
import { getGeography } from "@/lib/api";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * GET ?countryId=… → that country's regions; ?regionId=… → that region's
 * cities. For the add-kennel form's cascading pickers. Reference data that
 * changes rarely, so browsers and the CDN may keep it for an hour.
 */
export async function GET(req: NextRequest) {
  const countryId = req.nextUrl.searchParams.get("countryId") ?? "";
  const regionId = req.nextUrl.searchParams.get("regionId") ?? "";
  if ((countryId && !GUID.test(countryId)) || (regionId && !GUID.test(regionId)) || (!countryId && !regionId)) {
    return NextResponse.json({ error: "countryId or regionId is required" }, { status: 400 });
  }
  try {
    const places = await getGeography(regionId ? { regionId } : { countryId });
    return NextResponse.json(places, { headers: { "Cache-Control": "public, max-age=3600" } });
  } catch (e) {
    await logWebError({ source: "/api/geography", error: e });
    return NextResponse.json({ error: "Could not load the list" }, { status: 502 });
  }
}
