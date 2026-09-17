import { NextRequest, NextResponse } from "next/server";
import { getChatMessages, getChatThreads, sendChatMessage, type ChatKind } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const KINDS: ChatKind[] = ["run", "kennel", "room"];
const okId = (kind: ChatKind, id: string) => kind === "room" ? /^\d{1,6}$/.test(id) : /^[0-9a-f-]{36}$/.test(id);

/**
 * GET ?threads=1 → { me, threads }   (the app's Unseen Chats list + badges)
 * GET ?kind=&id=&since= → { me, messages }   (a thread, or just what is new)
 * POST { kind, id, messageId, text } → { ok }
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
  const body = await jsonBody<{ kind?: ChatKind; id?: string; messageId?: string; text?: string }>(req);
  const kind = body?.kind as ChatKind, id = (body?.id ?? "").toLowerCase(), messageId = (body?.messageId ?? "").toLowerCase();
  const text = (body?.text ?? "").trim().slice(0, 500);
  if (!KINDS.includes(kind) || !okId(kind, id) || !/^[0-9a-f-]{36}$/.test(messageId) || !text) return bad("Bad request.");
  try {
    const r = await sendChatMessage(s, kind, id, messageId, text);
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "Couldn't send.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/chat", error: e, session: s });
    return bad("Couldn't send just now.", 502);
  }
}
