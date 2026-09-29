import { NextRequest, NextResponse } from "next/server";
import { setDirectMessagePreference } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * POST { preference: 0 | 1 | 2 } → { ok, preference } — who may message me
 * (E9.F1.S18): 0 friends only, 1 anyone, 2 nobody. hcapp_setDirectMessagePreference
 * read-modify-writes its own two bits of HC.Hasher.Preferences and answers
 * with the value as stored, which is what the page then shows.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ preference?: number }>(req);
  const p = body?.preference;
  if (p !== 0 && p !== 1 && p !== 2) return bad("Bad request.");
  try {
    const r = await setDirectMessagePreference(s, p);
    return r.ok ? NextResponse.json({ ok: true, preference: r.preference }) : bad(r.message, 403);
  } catch (e) {
    await logWebError({ source: "/api/member/dm/preference", error: e, session: s });
    return bad("Couldn't save that just now.", 502);
  }
}
