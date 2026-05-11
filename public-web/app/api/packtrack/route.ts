import { NextRequest, NextResponse } from "next/server";

const UPSTREAM = "https://harriercentralpublicapi.azurewebsites.net/api/GetPositions";

export async function GET(req: NextRequest) {
  const eventId = req.nextUrl.searchParams.get("eventId");
  if (!eventId) return NextResponse.json({ error: "eventId required" }, { status: 400 });

  const res = await fetch(`${UPSTREAM}?eventId=${encodeURIComponent(eventId)}`, {
    headers: { "Accept-Encoding": "gzip", "Accept": "application/json" },
    next: { revalidate: 300 }, // cache 5 min — past run data doesn't change
  });

  if (!res.ok) return NextResponse.json({ error: "upstream error" }, { status: res.status });

  const data = await res.json();
  return NextResponse.json(data);
}
