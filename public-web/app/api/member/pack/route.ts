import { NextRequest, NextResponse } from "next/server";
import { getRunPack } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad } from "@/lib/member-routes";

/** GET ?publicEventId= → { pack } — own state and who else is coming. */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const publicEventId = (req.nextUrl.searchParams.get("publicEventId") ?? "").toLowerCase();
  if (!/^[0-9a-f-]{36}$/.test(publicEventId)) return bad("Bad request.");
  try {
    return NextResponse.json({ pack: await getRunPack(s, publicEventId) });
  } catch (e) {
    console.error("pack:", e);
    return bad("Couldn't load the pack just now.", 502);
  }
}
