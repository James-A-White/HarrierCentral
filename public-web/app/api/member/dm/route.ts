import { NextRequest, NextResponse } from "next/server";
import { endDirectMessage, setDirectMessageMute, startDirectMessage } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f-]{36}$/;

/**
 * POST { targetPublicHasherId } → { ok, outcome, threadId, otherDisplayName, … }
 * — "Message <name>" (E9.F1.S19) through publicWeb_startDirectMessage →
 * hcapp_startDirectMessage. Every answer the SP gives is a 200: `requested`,
 * `refused` and `blocked` are outcomes the page has words for, not errors.
 * Only a real refusal (yourself, no such hasher) comes back 403 with the
 * SP's message.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ targetPublicHasherId?: string }>(req);
  const target = (body?.targetPublicHasherId ?? "").toLowerCase();
  if (!GUID.test(target)) return bad("Bad request.");
  try {
    const r = await startDirectMessage(s, target);
    return r.ok ? NextResponse.json({ ok: true, ...r.start }) : bad(r.message, 403);
  } catch (e) {
    await logWebError({ source: "/api/member/dm", error: e, session: s });
    return bad("Couldn't start that conversation just now.", 502);
  }
}

/**
 * PATCH { threadId, mute: 1 | 0 } → { ok, muted } — mutes or unmutes one
 * thread's pushes (hcapp_setDirectMessageMute). The web gets no push itself;
 * this is the same switch the app shows, kept in one place on the server.
 */
export async function PATCH(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ threadId?: string; mute?: number }>(req);
  const threadId = (body?.threadId ?? "").toLowerCase();
  const mute = body?.mute;
  if (!GUID.test(threadId) || (mute !== 0 && mute !== 1)) return bad("Bad request.");
  try {
    const r = await setDirectMessageMute(s, threadId, mute);
    return r.ok ? NextResponse.json({ ok: true, muted: r.muted }) : bad(r.message, 403);
  } catch (e) {
    await logWebError({ source: "/api/member/dm PATCH", error: e, session: s });
    return bad("Couldn't change that just now.", 502);
  }
}

/**
 * DELETE { threadId } → { ok } — ends the conversation from my side
 * (hcapp_endDirectMessage). The thread stays readable; nobody can send in
 * it until the other hasher starts it again, and they are not told.
 */
export async function DELETE(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ threadId?: string }>(req);
  const threadId = (body?.threadId ?? "").toLowerCase();
  if (!GUID.test(threadId)) return bad("Bad request.");
  try {
    const r = await endDirectMessage(s, threadId);
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "That could not be saved.", 403);
  } catch (e) {
    await logWebError({ source: "/api/member/dm DELETE", error: e, session: s });
    return bad("Couldn't end that conversation just now.", 502);
  }
}
