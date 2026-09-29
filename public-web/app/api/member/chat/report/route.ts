import { NextRequest, NextResponse } from "next/server";
import { CHAT_REPORT_REASON_MAX, reportChatMessage } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f-]{36}$/;

/**
 * POST { messageId, reason? } → { ok } — reports one message to Harrier
 * Central's reviewers (E9.F1.S17). Nothing is hidden or removed by this;
 * Block is the member's own tool for that. The SP decides what may be
 * reported (not your own, still in the chat), so a refusal comes back 403
 * with its message.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ messageId?: string; reason?: string }>(req);
  const messageId = (body?.messageId ?? "").toLowerCase();
  const reason = (body?.reason ?? "").trim();
  if (!GUID.test(messageId)) return bad("Bad request.");
  // Refused, not sliced: the SP enforces the same 1,000, this saves a round trip.
  if (reason.length > CHAT_REPORT_REASON_MAX) return bad(`The reason can be up to ${CHAT_REPORT_REASON_MAX.toLocaleString()} characters; this one is ${reason.length.toLocaleString()}.`);
  try {
    const r = await reportChatMessage(s, messageId, reason || null);
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "The report could not be sent.", 403);
  } catch (e) {
    await logWebError({ source: "/api/member/chat/report", error: e, session: s });
    return bad("Couldn't send the report just now.", 502);
  }
}
