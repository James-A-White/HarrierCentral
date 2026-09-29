import type { Metadata } from "next";
import Link from "next/link";
import { getChatThreads, getDirectMessageRequests, type ChatThreadRow } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { chatHref, dmHref } from "@/lib/chat-links";
import { HC_RED } from "@/components/member/app-look";
import { DmRequests } from "@/components/member/DmRequests";
import { HasherPhoto } from "@/components/member/HasherPhoto";

export const metadata: Metadata = { title: "Chats" };

/**
 * The app's chat list (E9.F7.S15): requests to message me (E9.F1.S19), then
 * the rooms I may enter, then my direct messages (E9.F1.S7) and every run
 * and kennel thread with messages — unread first, with the red badge.
 */
export default async function ChatListPage() {
  const s = await requireMember();
  const [{ threads }, requests] = await Promise.all([
    getChatThreads(s).catch(() => ({ me: "", threads: [] as ChatThreadRow[] })),
    getDirectMessageRequests(s).catch(() => []),
  ]);
  const byRecent = (a: ChatThreadRow, b: ChatThreadRow) =>
    (b.BadgeCount > 0 ? 1 : 0) - (a.BadgeCount > 0 ? 1 : 0) || (b.LastMessageAt ?? "").localeCompare(a.LastMessageAt ?? "");
  const rooms = threads.filter((t) => t.RoomType != null);
  // A DM row names its thread and nothing else; an accepted request with no
  // message yet is listed too, so it has somewhere to go.
  const dms = threads.filter((t) => t.ThreadId).sort(byRecent);
  const others = threads
    .filter((t) => t.RoomType == null && !t.ThreadId && (t.PublicEventId || t.PublicKennelId) && (t.MessageCount > 0 || t.BadgeCount > 0))
    .sort(byRecent);

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href="/me/runs" aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">Chats</h2>
        <span className="w-4" />
      </div>

      <DmRequests initial={requests} />

      {rooms.length > 0 && (
        <>
          <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Chat rooms</h3>
          <ul className="space-y-2 px-2">
            {rooms.map((t) => (
              <Row key={`room-${t.RoomType}`} href={chatHref("room", String(t.RoomType), t.EventName ?? "Room", "/me/chat")} title={t.EventName ?? "Room"} sub={`${t.MessageCount} message${t.MessageCount === 1 ? "" : "s"}`} badge={t.BadgeCount} logo={t.RoomIcon} />
            ))}
          </ul>
        </>
      )}

      {dms.length > 0 && (
        <>
          <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Messages</h3>
          <ul className="space-y-2 px-2">
            {dms.map((t) => (
              <Row key={`dm-${t.ThreadId}`} href={dmHref(t.ThreadId!)}
                title={t.OtherDisplayName ?? t.EventName ?? "Hasher"}
                sub={t.MessageCount > 0 ? `${t.MessageCount} message${t.MessageCount === 1 ? "" : "s"} · ${whenLast(t.LastMessageAt)}` : "No messages yet"}
                badge={t.BadgeCount} photo={t.OtherPhoto ?? t.KennelLogo} />
            ))}
          </ul>
        </>
      )}

      <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Runs and kennels</h3>
      {others.length === 0 && <p className="px-3 py-6 text-center text-white/90">No chats yet. The chat bubble on a run or kennel card opens its thread.</p>}
      <ul className="space-y-2 px-2">
        {others.map((t) => t.PublicEventId ? (
          <Row key={`run-${t.PublicEventId}`} href={chatHref("run", t.PublicEventId, t.EventName ?? "Run", "/me/chat", t.PublicKennelId)}
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

/** "14:05" today, "Tue" this week, "12 Mar" otherwise — the app's list shorthand. Rendered on the server, so it is UTC-ish; a chat list wears that fine. */
function whenLast(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const age = Date.now() - d.getTime();
  if (age < 24 * 3600_000) return d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  if (age < 7 * 24 * 3600_000) return d.toLocaleDateString("en-GB", { weekday: "short" });
  return d.toLocaleDateString("en-GB", { day: "numeric", month: "short" });
}

function Row({ href, title, sub, badge, logo, photo }: { href: string; title: string; sub: string; badge: number; logo?: string | null; photo?: string | null }) {
  return (
    <li>
      <Link href={href} className="flex items-center gap-3 rounded-md bg-white px-3 py-2.5 text-zinc-900 shadow">
        {photo !== undefined ? (
          // A hasher's photo is a portrait: it keeps the circle.
          <HasherPhoto url={photo} className="h-12 w-12" />
        ) : logo?.startsWith("https://") ? (
          // Contained, never masked: a kennel logo must not be cropped, and a
          // room's coin is already a circle whose raised rim is what makes it
          // readable at 48px — a circular mask shaves it off.
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
