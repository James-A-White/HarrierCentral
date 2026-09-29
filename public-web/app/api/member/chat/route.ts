import { NextRequest, NextResponse } from "next/server";
import { deleteChatMessage, getChatMessages, getChatThreads, sendChatMessage, type ChatKind } from "@/lib/member-api";
import { CHAT_KIND_LOCATION, CHAT_KIND_PHOTO, CHAT_KIND_TEXT, isChatPhotoUrl, parseChatLocation, type ChatMessageKind } from "@/lib/chat-content";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/** "dm" (E9.F1.S7): the id is the ThreadId. */
const KINDS: ChatKind[] = ["run", "kennel", "room", "dm"];
const MESSAGE_KINDS: ChatMessageKind[] = [CHAT_KIND_TEXT, CHAT_KIND_PHOTO, CHAT_KIND_LOCATION];
/** HC.EventMessage.MessageContent is NVARCHAR(4000). */
export const CHAT_MESSAGE_MAX = 4000;
const GUID = /^[0-9a-f-]{36}$/;
const okId = (kind: ChatKind, id: string) => kind === "room" ? /^\d{1,6}$/.test(id) : GUID.test(id);

/**
 * GET ?threads=1 → { me, threads }   (the app's Unseen Chats list + badges)
 * GET ?kind=&id=&since= → { me, messages, removed, dm? }   (a thread, or just what is new,
 *                          plus every removed id so a deletion reaches an open page;
 *                          a DM also carries its status — canSend, muted — every time)
 * POST { kind, id, messageId, text, messageKind? } → { ok }
 * DELETE { messageId } → { ok }   (E9.F1.S13/S14 — the SP decides who may)
 */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const q = req.nextUrl.searchParams;
  try {
    if (q.get("threads") === "1") return NextResponse.json(await getChatThreads(s));
    const kind = q.get("kind") as ChatKind, id = (q.get("id") ?? "").toLowerCase();
    if (!KINDS.includes(kind) || !okId(kind, id)) return bad("Bad request.");
    const since = q.get("since") ? Number(q.get("since")) : undefined;
    const r = await getChatMessages(s, kind, id, Number.isFinite(since) ? since : undefined, false);
    return r ? NextResponse.json(r) : bad("Couldn't load the chat.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/chat", error: e, session: s });
    return bad("Couldn't load the chat just now.", 502);
  }
}

export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ kind?: ChatKind; id?: string; messageId?: string; text?: string; messageKind?: number }>(req);
  const kind = body?.kind as ChatKind, id = (body?.id ?? "").toLowerCase(), messageId = (body?.messageId ?? "").toLowerCase();
  const text = (body?.text ?? "").trim();
  const messageKind = (body?.messageKind ?? CHAT_KIND_TEXT) as ChatMessageKind;
  if (!KINDS.includes(kind) || !okId(kind, id) || !GUID.test(messageId) || !text || !MESSAGE_KINDS.includes(messageKind)) return bad("Bad request.");
  // Refused, not sliced: a silent cut is how the first admin-room announcement
  // lost its second half (2026-09-23). The SPs enforce the same 4,000.
  if (text.length > CHAT_MESSAGE_MAX) return bad(`Messages can be up to ${CHAT_MESSAGE_MAX.toLocaleString()} characters; this one is ${text.length.toLocaleString()}.`);
  // HC6.ChatMessageKindError is the rule; this only saves a round trip.
  if (messageKind === CHAT_KIND_PHOTO && !isChatPhotoUrl(text)) return bad("That photo could not be sent. Please try again.");
  if (messageKind === CHAT_KIND_LOCATION && !parseChatLocation(text)) return bad("That location could not be sent. Please try again.");
  try {
    const r = await sendChatMessage(s, kind, id, messageId, text, messageKind);
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "Couldn't send.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/chat", error: e, session: s });
    return bad("Couldn't send just now.", 502);
  }
}

export async function DELETE(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ messageId?: string }>(req);
  const messageId = (body?.messageId ?? "").toLowerCase();
  if (!GUID.test(messageId)) return bad("Bad request.");
  try {
    const r = await deleteChatMessage(s, messageId);
    // 403, not 502: a refusal is an answer, and the page shows its message.
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "That message could not be deleted.", 403);
  } catch (e) {
    await logWebError({ source: "/api/member/chat DELETE", error: e, session: s });
    return bad("Couldn't delete just now.", 502);
  }
}
