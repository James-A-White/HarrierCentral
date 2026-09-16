"use client";

/**
 * The app's bottom tab bar, as the member area's top bar: Runs · Kennels ·
 * Map · History · Songs (E9.F7). Same segmented control as GlobalTabBar so
 * the two halves of hashruns.org read as one site.
 */
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { LayoutList, Users, Map as MapIcon, History, Music } from "lucide-react";

const TABS = [
  { label: "Runs",    href: "/me/runs",    icon: LayoutList },
  { label: "Kennels", href: "/me/kennels", icon: Users },
  { label: "Map",     href: "/me/map",     icon: MapIcon },
  { label: "History", href: "/me/history", icon: History },
  { label: "Songs",   href: "/me/songs",   icon: Music },
] as const;

export function MemberTabBar({ hashName }: { hashName: string }) {
  const pathname = usePathname();
  const router = useRouter();

  async function signOut() {
    await fetch("/api/member/logout", { method: "POST" });
    router.push("/");
    router.refresh();
  }

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 backdrop-blur-lg">
      <div className="relative mx-auto flex h-14 max-w-[90rem] items-center justify-center px-2 sm:px-4">
        <Link href="/" className="absolute left-3 hidden select-none text-sm font-semibold uppercase tracking-widest text-zinc-400 hover:text-white md:block">
          hashruns.org
        </Link>

        <nav className="flex gap-1 rounded-full bg-white/10 p-1">
          {TABS.map((tab) => {
            const isActive = pathname.startsWith(tab.href);
            const Icon = tab.icon;
            return (
              <Link
                key={tab.href}
                href={tab.href}
                className={[
                  "flex items-center gap-2 rounded-full px-3 py-2 text-sm font-semibold transition-colors sm:px-5",
                  isActive ? "bg-red-600 text-white shadow-sm" : "text-zinc-300 hover:bg-white/10 hover:text-white",
                ].join(" ")}
                aria-current={isActive ? "page" : undefined}
              >
                <Icon className="h-4 w-4 shrink-0" />
                <span className="hidden sm:inline">{tab.label}</span>
              </Link>
            );
          })}
        </nav>

        <div className="absolute right-3 hidden items-center gap-3 text-xs text-zinc-400 md:flex">
          <span className="max-w-[10rem] truncate">{hashName}</span>
          <button type="button" onClick={signOut} className="underline underline-offset-2 hover:text-white">Sign out</button>
        </div>
      </div>
    </header>
  );
}
