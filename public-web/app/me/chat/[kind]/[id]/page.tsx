import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getChatMessages, markChatRead, type ChatKind } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { ChatThread } from "@/components/member/ChatThread";

export const metadata: Metadata = { title: "Chat" };

const KINDS: ChatKind[] = ["run", "kennel", "room"];

/**
 * One chat thread — a run's, a kennel's, or a room's (E9.F7.S15). Opening
 * it marks it read, as the app does: rooms through the read SP's own
 * flag, runs and kennels through the mark-read SPs.
 */
export default async function ChatPage({ params, searchParams }: { params: Promise<{ kind: string; id: string }>; searchParams: Promise<{ title?: string; back?: string }> }) {
  const [{ kind, id }, { title, back }] = await Promise.all([params, searchParams]);
  const k = kind as ChatKind;
  const okId = k === "room" ? /^\d{1,6}$/.test(id) : /^[0-9a-f-]{36}$/i.test(id);
  if (!KINDS.includes(k) || !okId) notFound();
  const s = await requireMember();
  const r = await getChatMessages(s, k, id.toLowerCase(), undefined, true).catch(() => null);
  if (!r) notFound();
  if (k !== "room") void markChatRead(s, k, id.toLowerCase());
  const safeBack = back && back.startsWith("/") && !back.startsWith("//") ? back : "/me/chat";
  return <ChatThread kind={k} id={id.toLowerCase()} title={(title ?? "").slice(0, 80) || "Chat"} me={r.me} initial={r.messages} back={safeBack} />;
}
