import { NextRequest, NextResponse } from "next/server";
import { searchKennels } from "@/lib/member-api";

/** GET ?q= → { kennels } — public directory, no sign-in needed. */
export async function GET(req: NextRequest) {
  const q = (req.nextUrl.searchParams.get("q") ?? "").trim().slice(0, 100);
  try {
    return NextResponse.json({ kennels: await searchKennels(q) });
  } catch (e) {
    console.error("kennel-search:", e);
    return NextResponse.json({ kennels: [] }, { status: 502 });
  }
}
