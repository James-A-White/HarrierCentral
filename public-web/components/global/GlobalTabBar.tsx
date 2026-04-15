"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const TABS = [
  { label: "Runs",     href: "/"         },
  { label: "Calendar", href: "/calendar" },
  // Map and Kennels: future tabs — add here when built
] as const;

export function GlobalTabBar() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 px-4 py-3 backdrop-blur-lg">
      <div className="mx-auto max-w-[90rem] flex items-center gap-1">
        {/* Branding */}
        <span className="mr-4 text-sm font-semibold tracking-widest text-zinc-400 uppercase select-none">
          hashruns.org
        </span>

        {/* Tabs */}
        {TABS.map((tab) => {
          const isActive =
            tab.href === "/"
              ? pathname === "/"
              : pathname.startsWith(tab.href);

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={[
                "px-4 py-1.5 rounded-full text-sm font-semibold transition-colors",
                isActive
                  ? "bg-white/10 text-white"
                  : "text-zinc-400 hover:text-white hover:bg-white/5",
              ].join(" ")}
            >
              {tab.label}
            </Link>
          );
        })}
      </div>
    </header>
  );
}
