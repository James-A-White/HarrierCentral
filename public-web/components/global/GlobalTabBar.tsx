"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutList, CalendarDays } from "lucide-react";

const TABS = [
  { label: "Runs",     href: "/",         icon: LayoutList  },
  { label: "Calendar", href: "/calendar", icon: CalendarDays },
  // Map and Kennels: future tabs — add here when built
] as const;

export function GlobalTabBar() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 backdrop-blur-lg">
      <div className="relative mx-auto max-w-[90rem] flex items-center justify-center h-14 px-4">

        {/* Branding — pinned left */}
        <span className="absolute left-4 text-sm font-semibold tracking-widest text-zinc-400 uppercase select-none">
          hashruns.org
        </span>

        {/* Segmented control — centred */}
        <div className="flex rounded-full bg-white/10 p-1 gap-1">
          {TABS.map((tab) => {
            const isActive =
              tab.href === "/"
                ? pathname === "/"
                : pathname.startsWith(tab.href);
            const Icon = tab.icon;

            return (
              <Link
                key={tab.href}
                href={tab.href}
                className={[
                  "flex items-center gap-2 px-6 py-2 rounded-full text-sm font-semibold transition-colors",
                  isActive
                    ? "bg-red-600 text-white shadow-sm"
                    : "text-zinc-300 hover:text-white hover:bg-white/10",
                ].join(" ")}
              >
                <Icon className="h-4 w-4 shrink-0" />
                {tab.label}
              </Link>
            );
          })}
        </div>

      </div>
    </header>
  );
}
