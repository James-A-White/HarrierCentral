import { NextRequest, NextResponse } from "next/server";
import { getDirectMessageRequests, respondDirectMessageRequest } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f-]{36}$/;

/** GET → { requests } — direct-message requests waiting on me (E9.F1.S19). */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  try {
    return NextResponse.json({ requests: await getDirectMessageRequests(s) });
  } catch (e) {
    await logWebError({ source: "/api/member/dm/requests", error: e, session: s });
    return bad("Couldn't load your requests just now.", 502);
  }
}

/**
 * POST { fromPublicHasherId, accept: 1 | 0 } → { ok, outcome, threadId } —
 * answers one request through hcapp_respondDirectMessageRequest. Accepting
 * mints the thread, and `threadId` is where the page goes next; declining
 * is silent to the requester. A request that is no longer waiting is a
 * 403 with the SP's own words, not a 502.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ fromPublicHasherId?: string; accept?: number }>(req);
  const from = (body?.fromPublicHasherId ?? "").toLowerCase();
  const accept = body?.accept;
  if (!GUID.test(from) || (accept !== 0 && accept !== 1)) return bad("Bad request.");
  try {
    const r = await respondDirectMessageRequest(s, from, accept);
    return r.ok ? NextResponse.json({ ok: true, outcome: r.outcome, threadId: r.threadId }) : bad(r.message, 403);
  } catch (e) {
    await logWebError({ source: "/api/member/dm/requests POST", error: e, session: s });
    return bad(accept === 1 ? "Couldn't accept that just now." : "Couldn't decline that just now.", 502);
  }
}
