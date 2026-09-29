import type { ChatKind } from "@/lib/member-api";

/**
 * The web chat thread URL — shared by server pages and client cards.
 *
 * `kennelId` (a run's PublicKennelId) lets the thread show that kennel's own
 * artwork behind its photo carousel. It is a hint for the backdrop only —
 * never an authority on anything — and a kennel chat needs none, since its
 * id already is the kennel.
 */
export function chatHref(kind: ChatKind, id: string, title: string, back: string, kennelId?: string | null): string {
  if (kind === "dm") return dmHref(id, back);
  const k = kind === "run" && kennelId ? `&k=${encodeURIComponent(kennelId.toLowerCase())}` : "";
  return `/me/chat/${kind}/${encodeURIComponent(id.toLowerCase())}?title=${encodeURIComponent(title)}&back=${encodeURIComponent(back)}${k}`;
}

/**
 * A direct message's URL (E9.F1.S7). No title: the page takes the other
 * hasher's name and photo from the thread SP, never from the address bar.
 */
export function dmHref(threadId: string, back = "/me/chat"): string {
  return `/me/chat/dm/${encodeURIComponent(threadId.toLowerCase())}?back=${encodeURIComponent(back)}`;
}
