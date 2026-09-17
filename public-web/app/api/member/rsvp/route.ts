import { NextRequest, NextResponse } from "next/server";
import { getRunPack, setRunRsvp } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/** POST { publicEventId, rsvp: 'yes'|'no'|'maybe' } → { ok, message?, pack } */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ publicEventId?: string; rsvp?: string }>(req);
  const publicEventId = (body?.publicEventId ?? "").toLowerCase();
  const state = ({ no: 1, maybe: 2, yes: 3 } as const)[(body?.rsvp ?? "").toLowerCase()];
  if (!/^[0-9a-f-]{36}$/.test(publicEventId) || !state) return bad("Bad request.");
  try {
    const r = await setRunRsvp(s, publicEventId, state);
    if (!r.ok) return bad(r.message ?? "Couldn't save your RSVP.", 502);
    const pack = await getRunPack(s, publicEventId).catch(() => null);
    return NextResponse.json({ ok: true, message: r.message, pack });
  } catch (e) {
    await logWebError({ source: "/api/member/rsvp", error: e, session: s });
    return bad("Couldn't save your RSVP just now. Please try again.", 502);
  }
}
