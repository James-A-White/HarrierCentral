import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getChatMessages } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { ChatThread } from "@/components/member/ChatThread";

export const metadata: Metadata = { title: "Message" };

const GUID = /^[0-9a-f-]{36}$/i;

/**
 * One direct message thread (E9.F1.S7) — the chat page with kind `dm`.
 * The other hasher's name and photo come from the thread SP, never from
 * the URL; opening it marks it read through the reader's own flag, as a
 * room does. A thread this member holds no row in is not found. The photo
 * carousel gets the jungle: a DM belongs to no kennel.
 */
export default async function DirectMessagePage({ params, searchParams }: { params: Promise<{ threadId: string }>; searchParams: Promise<{ back?: string }> }) {
  const [{ threadId }, { back }] = await Promise.all([params, searchParams]);
  if (!GUID.test(threadId)) notFound();
  const s = await requireMember();
  const id = threadId.toLowerCase();
  const r = await getChatMessages(s, "dm", id, undefined, true).catch(() => null);
  if (!r?.dm) notFound();
  const safeBack = back && back.startsWith("/") && !back.startsWith("//") ? back : "/me/chat";
  return <ChatThread kind="dm" id={id} title={r.dm.otherDisplayName || "Message"} me={r.me} initial={r.messages} back={safeBack} kennel={null} dm={r.dm} />;
}
