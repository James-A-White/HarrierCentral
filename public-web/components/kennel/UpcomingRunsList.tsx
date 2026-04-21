"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";

interface UpcomingRunsListProps {
  runs: RunEvent[];
  slug: string;
}

function formatShortDate(iso: string): { dayTime: string; shortDate: string } {
  const d = new Date(iso);
  return {
    dayTime: d.toLocaleDateString("en-GB", { weekday: "short" }) + " · " +
             d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }),
    shortDate: d.toLocaleDateString("en-GB", { day: "numeric", month: "short" }),
  };
}

export function UpcomingRunsList({ runs, slug }: UpcomingRunsListProps) {
  return (
    <div className="min-w-0 w-full max-w-full">
      <div className="mb-4 flex min-w-0 items-center justify-between gap-3">
        <h2 className="min-w-0 text-2xl font-bold dark:text-white text-zinc-900">Upcoming runs</h2>
        <Link
          href={`/${slug}/runs`}
          className="shrink-0 text-xl font-medium dark:text-white text-zinc-900"
        >
          Full calendar →
        </Link>
      </div>
      <div className="space-y-3">
        {runs.length === 0 && (
          <p className="text-xl dark:text-white text-zinc-900 py-4">No upcoming runs scheduled.</p>
        )}
        {runs.map((run, i) => {
          const { dayTime, shortDate } = formatShortDate(run.EventStartDatetime);
          return (
            <motion.div
              key={run.PublicEventId}
              className="min-w-0"
              initial={{ opacity: 0, y: 8 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: i * 0.07, ease: [0.19, 1, 0.22, 1] }}
            >
              <Link className="block min-w-0" href={`/${slug}/${run.EventNumber}`}>
              <Card className="w-full max-w-full rounded-2xl gap-0 py-0 dark:border-white/25 dark:bg-white/[0.12] border-zinc-200 bg-white shadow-lg dark:shadow-black/50 hover:shadow-xl transition-shadow cursor-pointer group">
                <CardContent className="flex items-center gap-4 p-4">
                  {/* Left column: date above run number badge */}
                  <div className="flex shrink-0 flex-col items-center gap-1.5">
                    <div className="text-sm font-semibold dark:text-white/70 text-zinc-500 text-center" suppressHydrationWarning>
                      {shortDate}
                    </div>
                    <div
                      className="flex min-w-[48px] items-center justify-center rounded-xl px-2 py-1.5 text-sm font-bold"
                      style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-menu-text)" }}
                    >
                      #{run.EventNumber}
                    </div>
                  </div>

                  {/* Details — full remaining width */}
                  <div className="min-w-0 flex-1">
                    <div className="text-2xl font-semibold dark:text-white text-zinc-900 truncate transition-colors group-hover:text-[var(--kennel-primary)]">
                      {run.EventName}
                    </div>
                    <div className="mt-1 flex min-w-0 flex-wrap gap-x-3 gap-y-0.5 text-xl dark:text-white text-zinc-900">
                      <span className="flex items-center gap-1" suppressHydrationWarning>
                        <Clock className="h-3 w-3" />
                        {dayTime}
                      </span>
                      {(run.LocationOneLineDesc ?? run.LocationCity) && (
                        <span className="flex min-w-0 max-w-full items-center gap-1">
                          <MapPin className="h-3 w-3 shrink-0" />
                          <span className="min-w-0 truncate">{run.LocationOneLineDesc ?? run.LocationCity}</span>
                        </span>
                      )}
                    </div>
                    {run.Hares && (
                      <div className="mt-0.5 flex min-w-0 items-center gap-1.5 text-xl dark:text-white/80 text-zinc-600">
                        <span className="shrink-0 text-sm uppercase tracking-[0.12em]">Hares:</span>
                        <span className="min-w-0 truncate font-medium dark:text-white text-zinc-900">{run.Hares}</span>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
              </Link>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
