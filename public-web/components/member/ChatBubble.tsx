"use client";

/**
 * The app's three-state HcChatBubble on run and kennel cards: unread =
 * red solid with the count, read = grey solid, none = grey outline.
 */
import Link from "next/link";
import { MessageCircle } from "lucide-react";
import type { ChatKind, ChatThreadRow } from "@/lib/member-api";
import { HC_RED } from "@/components/member/app-look";
import { chatHref } from "@/lib/chat-links";

export type ThreadIndex = Map<string, ChatThreadRow>;

export function indexThreads(threads: ChatThreadRow[]): ThreadIndex {
  const m: ThreadIndex = new Map();
  for (const t of threads) {
    if (t.PublicEventId) m.set(`run:${t.PublicEventId.toLowerCase()}`, t);
    else if (t.PublicKennelId) m.set(`kennel:${t.PublicKennelId.toLowerCase()}`, t);
    else if (t.RoomType != null) m.set(`room:${t.RoomType}`, t);
  }
  return m;
}


export function ChatBubble({ kind, id, title, back, threads, className = "h-8 w-8" }: {
  kind: ChatKind; id: string; title: string; back: string; threads: ThreadIndex | null; className?: string;
}) {
  const t = threads?.get(`${kind}:${id.toLowerCase()}`);
  const unread = t?.BadgeCount ?? 0;
  const any = (t?.MessageCount ?? 0) > 0;
  return (
    <Link href={chatHref(kind, id, title, back)} aria-label={unread ? `${unread} unread chat messages` : "Chat"} className="relative shrink-0 text-zinc-500">
      <MessageCircle className={className} fill={unread ? HC_RED : any ? "#a1a1aa" : "none"} stroke={unread ? HC_RED : "#a1a1aa"} />
      {unread > 0 && (
        <span className="absolute -right-1.5 -top-1.5 flex h-5 min-w-[20px] items-center justify-center rounded-full px-1 text-[11px] font-bold text-white ring-2 ring-white" style={{ backgroundColor: HC_RED }}>{unread}</span>
      )}
    </Link>
  );
}
