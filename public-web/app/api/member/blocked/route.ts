import { NextRequest, NextResponse } from "next/server";
import { getBlockedHashers, setHasherBlock } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f-]{36}$/;

/**
 * GET → { blocked } — everyone this member has blocked, newest first
 * (E9.F1.S16).
 */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  try {
    return NextResponse.json({ blocked: await getBlockedHashers(s) });
  } catch (e) {
    await logWebError({ source: "/api/member/blocked", error: e, session: s });
    return bad("Couldn't load your blocked hashers just now.", 502);
  }
}

/**
 * POST { targetPublicHasherId, blocked: 1 | 0 } → { ok, blocked } — blocks or
 * unblocks one hasher and hands back the list as it now stands. The rule
 * (not yourself, a real hasher) lives in hcapp_setHasherBlock; a refusal is
 * an answer, so it comes back 403 with the SP's own message, not 502.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ targetPublicHasherId?: string; blocked?: number }>(req);
  const target = (body?.targetPublicHasherId ?? "").toLowerCase();
  const blocked = body?.blocked;
  if (!GUID.test(target) || (blocked !== 0 && blocked !== 1)) return bad("Bad request.");
  try {
    const r = await setHasherBlock(s, target, blocked);
    return r.ok
      ? NextResponse.json({ ok: true, blocked: r.blocked })
      : bad(r.message ?? "That could not be saved.", 403);
  } catch (e) {
    await logWebError({ source: "/api/member/blocked", error: e, session: s });
    return bad(blocked === 1 ? "Couldn't block them just now." : "Couldn't unblock them just now.", 502);
  }
}
