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
  const k = kind === "run" && kennelId ? `&k=${encodeURIComponent(kennelId.toLowerCase())}` : "";
  return `/me/chat/${kind}/${encodeURIComponent(id.toLowerCase())}?title=${encodeURIComponent(title)}&back=${encodeURIComponent(back)}${k}`;
}
