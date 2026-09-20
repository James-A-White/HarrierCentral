"use client";

/**
 * The app's bottom tab bar, as the member area's top bar: Runs · Kennels ·
 * Map · History · Songs (E9.F7). Same segmented control as GlobalTabBar so
 * the two halves of hashruns.org read as one site.
 */
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { LayoutList, Users, Map as MapIcon, History, Music, MessageSquare, KeyRound } from "lucide-react";

const TABS = [
  { label: "Runs",    title: "Hash Runs", href: "/me/runs",    icon: LayoutList },
  { label: "Kennels", title: "Kennels",   href: "/me/kennels", icon: Users },
  { label: "Map",     title: "Map",       href: "/me/map",     icon: MapIcon },
  { label: "History", title: "Run Counts", href: "/me/history", icon: History },
  { label: "Songs",   title: "Songs",     href: "/me/songs",   icon: Music },
] as const;

export function MemberTabBar({ hashName }: { hashName: string }) {
  const pathname = usePathname();
  const router = useRouter();
  const [unread, setUnread] = useState(0);

  // The app's chat bubble with the global badge: the sum of unread across threads.
  useEffect(() => {
    fetch("/api/member/chat?threads=1", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : null))
      .then((j: { threads?: { BadgeCount: number }[] } | null) => { if (j?.threads) setUnread(j.threads.reduce((n, t) => n + (t.BadgeCount || 0), 0)); })
      .catch(() => undefined);
  }, [pathname]);

  async function signOut() {
    await fetch("/api/member/logout", { method: "POST" });
    router.push("/");
    router.refresh();
  }

  const current = TABS.find((t) => pathname.startsWith(t.href));
  const title = current?.title ?? "Harrier Central";

  return (
    <>
      {/* The app's purple app bar, with the tab's title. Fixed, not sticky:
          the body's overflow-x: hidden makes sticky slide away on desktop. */}
      <div className="fixed inset-x-0 top-0 z-50 text-white" style={{ backgroundColor: "#580438" }}>
        <div className="relative mx-auto flex h-12 max-w-[90rem] items-center justify-center px-3">
          {/* The app puts the chat balloon on the LEFT of the bar, beside the
              menu, and draws it as Icons.chat_bubble_outline — a squared
              balloon, not a circle (James, 2026-09-17). */}
          <div className="absolute left-3 flex items-center gap-3">
            <Link href="/" className="text-xs font-semibold uppercase tracking-widest text-white/70 hover:text-white">hashruns.org</Link>
            <Link href="/me/chat" aria-label={unread ? `Chats, ${unread} unread` : "Chats"} className="relative text-white">
              <MessageSquare className="h-6 w-6" />
              {unread > 0 && <span className="absolute -right-2 -top-2 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-600 px-1 text-[11px] font-bold text-white">{unread}</span>}
            </Link>
          </div>
          <h1 className="text-lg font-semibold">{title}</h1>
          <div className="absolute right-3 flex items-center gap-3 text-xs text-white/80">
            <span className="hidden max-w-[12rem] truncate text-2xl font-semibold text-white sm:inline">{hashName}</span>
            {/* Passkeys live beside Sign out because they are the same kind of
                thing — how you get in — and an icon keeps the bar usable on a
                phone, where the hash name is already hidden. */}
            <Link href="/me/passkeys" aria-label="Passkeys" title="Passkeys" className="text-white/80 hover:text-white">
              <KeyRound className="h-5 w-5" />
            </Link>
            <button type="button" onClick={signOut} className="underline underline-offset-2 hover:text-white">Sign out</button>
          </div>
        </div>
      </div>

      {/* The app's bottom tab bar: light, green icons, label under each. */}
      <nav className="fixed inset-x-0 bottom-0 z-50 border-t border-zinc-300 bg-[#f6eef2]" style={{ paddingBottom: "env(safe-area-inset-bottom)" }}>
        <ul className="mx-auto flex h-16 max-w-3xl items-stretch justify-around">
          {TABS.map((tab) => {
            const isActive = pathname.startsWith(tab.href);
            const Icon = tab.icon;
            return (
              <li key={tab.href} className="flex-1">
                <Link
                  href={tab.href}
                  className="flex h-full flex-col items-center justify-center gap-0.5 text-[12px] font-semibold"
                  style={{ color: isActive ? "#0D4701" : "#3f3f46", opacity: isActive ? 1 : 0.8 }}
                  aria-current={isActive ? "page" : undefined}
                >
                  <Icon className="h-6 w-6 shrink-0" strokeWidth={isActive ? 2.5 : 1.75} fill={isActive ? "rgba(13,71,1,0.15)" : "none"} />
                  <span>{tab.label}</span>
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </>
  );
}
