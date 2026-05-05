import { NextRequest, NextResponse } from "next/server";

const API_BASE = process.env.HC_API_URL ?? "http://localhost:7071";

export async function POST(req: NextRequest) {
  let body: { slug?: string; pageLayoutJson?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 });
  }

  const { slug, pageLayoutJson } = body;

  if (!slug || !pageLayoutJson) {
    return NextResponse.json({ error: "Missing required fields: slug, pageLayoutJson." }, { status: 400 });
  }

  try {
    const res = await fetch(`${API_BASE}/api/PublicWebAdminApi`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        queryType: "savePageLayout",
        KennelSlug: slug,
        PageLayoutJson: pageLayoutJson,
      }),
      cache: "no-store",
    });

    if (!res.ok) {
      const text = await res.text().catch(() => "");
      return NextResponse.json(
        { error: `Admin API error: ${res.status}`, detail: text },
        { status: res.status >= 500 ? 502 : res.status }
      );
    }

    return NextResponse.json({ success: true });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: "Failed to reach admin API.", detail: message }, { status: 502 });
  }
}
