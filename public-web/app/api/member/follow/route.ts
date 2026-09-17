import { NextRequest, NextResponse } from "next/server";
import { setKennelFollowing } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * POST { publicKennelId, following?: 0|1|2, isHomeKennel?: 0|1 } → { ok }
 * — the app's kennel-card popup through its own joinKennel, self-mode.
 * (`following: true|false` is still accepted from older pages: 1 / 0.)
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ publicKennelId?: string; following?: number | boolean; isHomeKennel?: number }>(req);
  const id = (body?.publicKennelId ?? "").toLowerCase();
  if (!/^[0-9a-f-]{36}$/.test(id)) return bad("Bad request.");
  const following = body?.following === true ? 1 : body?.following === false ? 0 : body?.following;
  const isHomeKennel = body?.isHomeKennel;
  if ((following != null && ![0, 1, 2].includes(following)) || (isHomeKennel != null && ![0, 1].includes(isHomeKennel)) || (following == null && isHomeKennel == null)) return bad("Bad request.");
  try {
    const r = await setKennelFollowing(s, id, { following: following as 0 | 1 | 2 | undefined, isHomeKennel: isHomeKennel as 0 | 1 | undefined });
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "Couldn't update.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/follow", error: e, session: s });
    return bad("Couldn't update just now.", 502);
  }
}
