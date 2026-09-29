import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getChatMessages, markChatRead, type ChatKind } from "@/lib/member-api";
import { getKennelLandingData, resolveKennelsByUuid } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import type { KennelContext } from "@/lib/types/kennel";
import { requireMember } from "@/lib/member-server";
import { ChatThread } from "@/components/member/ChatThread";

export const metadata: Metadata = { title: "Chat" };

// A direct message has its own page at /me/chat/dm/[threadId] — the static
// segment wins over [kind], so "dm" never reaches here.
const KINDS: ChatKind[] = ["run", "kennel", "room"];
const GUID = /^[0-9a-f-]{36}$/i;

/**
 * The kennel whose artwork sits behind this chat's photo carousel (CLAUDE.md:
 * the web shows a photo on the kennel's own backdrop). A kennel chat is its
 * kennel; a run chat carries its kennel as ?k=; a room has none, and gets the
 * jungle. Best effort — a miss only costs the backdrop, never the chat.
 */
async function backdropKennel(kind: ChatKind, id: string, k: string | undefined): Promise<KennelContext | null> {
  const publicKennelId = kind === "kennel" ? id : kind === "run" && k && GUID.test(k) ? k : null;
  if (!publicKennelId) return null;
  try {
    const slug = (await resolveKennelsByUuid(publicKennelId))[0]?.KennelSlug;
    const data = slug ? await getKennelLandingData(slug) : null;
    return data ? toKennelContext(data) : null;
  } catch {
    return null;
  }
}

/**
 * One chat thread — a run's, a kennel's, or a room's (E9.F7.S15). Opening
 * it marks it read, as the app does: rooms through the read SP's own
 * flag, runs and kennels through the mark-read SPs.
 */
export default async function ChatPage({ params, searchParams }: { params: Promise<{ kind: string; id: string }>; searchParams: Promise<{ title?: string; back?: string; k?: string }> }) {
  const [{ kind, id }, { title, back, k }] = await Promise.all([params, searchParams]);
  const kk = kind as ChatKind;
  const okId = kk === "room" ? /^\d{1,6}$/.test(id) : GUID.test(id);
  if (!KINDS.includes(kk) || !okId) notFound();
  const s = await requireMember();
  const [r, kennel] = await Promise.all([
    getChatMessages(s, kk, id.toLowerCase(), undefined, true).catch(() => null),
    backdropKennel(kk, id.toLowerCase(), k?.toLowerCase()),
  ]);
  if (!r) notFound();
  if (kk === "run" || kk === "kennel") void markChatRead(s, kk, id.toLowerCase());
  const safeBack = back && back.startsWith("/") && !back.startsWith("//") ? back : "/me/chat";
  return <ChatThread kind={kk} id={id.toLowerCase()} title={(title ?? "").slice(0, 80) || "Chat"} me={r.me} initial={r.messages} back={safeBack} kennel={kennel} />;
}
