import { NextRequest, NextResponse } from "next/server";
import { resolveKennelsByUuid, getKennelLandingData, getEvents } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";

export async function GET(request: NextRequest) {
  const uuid = request.nextUrl.searchParams.get("uuid")?.trim();
  if (!uuid) return NextResponse.json(null, { status: 400 });

  // Sanitise: UUID characters only
  const sanitised = uuid.replace(/[^a-fA-F0-9\-]/g, "");
  if (!sanitised) return NextResponse.json(null, { status: 400 });

  try {
    const resolved = await resolveKennelsByUuid(sanitised);
    if (!resolved.length) return NextResponse.json(null, { status: 404 });

    const { KennelSlug: slug } = resolved[0];
    const landingData = await getKennelLandingData(slug);
    if (!landingData) return NextResponse.json(null, { status: 404 });

    const [futureResult, pastResult] = await Promise.all([
      getEvents(landingData.PublicKennelId, { isFuture: true, maxEvents: 100, summaryOnly: true }),
      getEvents(landingData.PublicKennelId, { isFuture: false, daysOffset: 3650, summaryOnly: true }),
    ]);

    return NextResponse.json({
      slug,
      kennel: toKennelContext(landingData),
      futureRuns: futureResult?.events ?? [],
      pastRuns: pastResult?.events ?? [],
    });
  } catch {
    return NextResponse.json(null, { status: 500 });
  }
}
