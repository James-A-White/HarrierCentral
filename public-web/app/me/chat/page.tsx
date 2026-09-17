import type { Metadata } from "next";
import Link from "next/link";
import { getChatThreads } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { chatHref } from "@/components/member/ChatBubble";
import { HC_RED } from "@/components/member/app-look";

export const metadata: Metadata = { title: "Chats" };

/**
 * The app's chat list (E9.F7.S15): the rooms I may enter, then every run
 * and kennel thread with messages — unread first, with the red badge.
 */
export default async function ChatListPage() {
  const s = await requireMember();
  const { threads } = await getChatThreads(s).catch(() => ({ me: "", threads: [] }));
  const rooms = threads.filter((t) => t.RoomType != null);
  const others = threads
    .filter((t) => t.RoomType == null && (t.MessageCount > 0 || t.BadgeCount > 0))
    .sort((a, b) => (b.BadgeCount > 0 ? 1 : 0) - (a.BadgeCount > 0 ? 1 : 0) || (b.LastMessageAt ?? "").localeCompare(a.LastMessageAt ?? ""));

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href="/me/runs" aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">Chats</h2>
        <span className="w-4" />
      </div>

      {rooms.length > 0 && (
        <>
          <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Chat rooms</h3>
          <ul className="space-y-2 px-2">
            {rooms.map((t) => (
              <Row key={`room-${t.RoomType}`} href={chatHref("room", String(t.RoomType), t.EventName ?? "Room", "/me/chat")} title={t.EventName ?? "Room"} sub={`${t.MessageCount} message${t.MessageCount === 1 ? "" : "s"}`} badge={t.BadgeCount} />
            ))}
          </ul>
        </>
      )}

      <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Runs and kennels</h3>
      {others.length === 0 && <p className="px-3 py-6 text-center text-white/90">No chats yet. The chat bubble on a run or kennel card opens its thread.</p>}
      <ul className="space-y-2 px-2">
        {others.map((t) => t.PublicEventId ? (
          <Row key={`run-${t.PublicEventId}`} href={chatHref("run", t.PublicEventId, t.EventName ?? "Run", "/me/chat")}
            title={t.EventName ?? "Run"} sub={`${t.KennelShortName ?? ""}${t.EventNumber ? ` · Run #${t.EventNumber}` : ""} · ${t.MessageCount} message${t.MessageCount === 1 ? "" : "s"}`}
            badge={t.BadgeCount} logo={t.KennelLogo} />
        ) : (
          <Row key={`kennel-${t.PublicKennelId}`} href={chatHref("kennel", t.PublicKennelId!, `${t.KennelShortName ?? ""} Kennel Chat`, "/me/chat")}
            title={`${t.KennelShortName ?? t.EventName ?? ""} Kennel Chat`} sub={`${t.MessageCount} message${t.MessageCount === 1 ? "" : "s"}`}
            badge={t.BadgeCount} logo={t.KennelLogo} />
        ))}
      </ul>
    </div>
  );
}

function Row({ href, title, sub, badge, logo }: { href: string; title: string; sub: string; badge: number; logo?: string | null }) {
  return (
    <li>
      <Link href={href} className="flex items-center gap-3 rounded-md bg-white px-3 py-2.5 text-zinc-900 shadow">
        {logo?.startsWith("https://") ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={logo} alt="" className="h-12 w-12 shrink-0 object-contain" />
        ) : (
          <div className="h-12 w-12 shrink-0 rounded-full bg-zinc-200" />
        )}
        <div className="min-w-0 flex-1">
          <div className="truncate text-[18px] font-semibold">{title}</div>
          <div className="truncate text-[14px] text-zinc-500">{sub}</div>
        </div>
        {badge > 0 && <span className="flex h-7 min-w-[28px] items-center justify-center rounded-full px-2 text-[13px] font-bold text-white" style={{ backgroundColor: HC_RED }}>{badge}</span>}
      </Link>
    </li>
  );
}
