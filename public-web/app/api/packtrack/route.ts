import { NextRequest, NextResponse } from "next/server";

const UPSTREAM = "https://harriercentralpublicapi.azurewebsites.net/api/GetPositions";

// GetPositions is gated behind an API key (X-Api-Key). Set GET_POSITIONS_API_KEY
// in .env.local for dev and as an App Service env var in production. Without it
// the upstream returns 401 and no tracks are ever shown.
const API_KEY = process.env.GET_POSITIONS_API_KEY;

export async function GET(req: NextRequest) {
  const eventId = req.nextUrl.searchParams.get("eventId");
  if (!eventId) return NextResponse.json({ error: "eventId required" }, { status: 400 });
  if (!API_KEY) {
    console.error("[packtrack] GET_POSITIONS_API_KEY not set — cannot call GetPositions");
    return NextResponse.json({ error: "not configured" }, { status: 500 });
  }

  try {
    // Mobile app uses POST with JSON body — match that behaviour
    const res = await fetch(UPSTREAM, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Api-Key": API_KEY,
      },
      body: JSON.stringify({ eventId }),
      cache: "no-store",
    });

    console.log(`[packtrack] eventId=${eventId} status=${res.status}`);

    if (!res.ok) {
      const text = await res.text();
      console.error(`[packtrack] upstream error: ${res.status} ${text}`);
      return NextResponse.json({ error: "upstream error", status: res.status }, { status: res.status });
    }

    const data = await res.json();
    const userCount = (data.users as unknown[])?.length ?? 0;
    const posCount = (data.users as { positions: unknown[] }[])?.reduce((s, u) => s + (u.positions?.length ?? 0), 0) ?? 0;
    console.log(`[packtrack] users=${userCount} positions=${posCount}`);

    return NextResponse.json(data, {
      headers: { "Cache-Control": "public, s-maxage=300" },
    });
  } catch (err) {
    console.error("[packtrack] fetch error:", err);
    return NextResponse.json({ error: String(err) }, { status: 500 });
  }
}
