import type { ChatKind } from "@/lib/member-api";

/** The web chat thread URL — shared by server pages and client cards. */
export function chatHref(kind: ChatKind, id: string, title: string, back: string): string {
  return `/me/chat/${kind}/${encodeURIComponent(id.toLowerCase())}?title=${encodeURIComponent(title)}&back=${encodeURIComponent(back)}`;
}
