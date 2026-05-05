"use client";

import { CalendarDays } from "lucide-react";

export function EventsListBlock() {
  return (
    <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] p-12 flex flex-col items-center gap-3 text-center">
      <CalendarDays className="h-8 w-8" style={{ color: "var(--kennel-text-muted)" }} />
      <h2 className="text-2xl font-bold" style={{ color: "var(--kennel-text-title)" }}>
        Events
      </h2>
      <p className="text-lg" style={{ color: "var(--kennel-text-muted)" }}>
        Coming soon.
      </p>
    </div>
  );
}
