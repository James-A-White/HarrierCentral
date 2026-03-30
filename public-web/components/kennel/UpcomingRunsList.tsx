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
        <a
          href="#"
          className="shrink-0 text-xl font-medium"
          style={{ color: "var(--kennel-primary)" }}
        >
          Full calendar →
        </a>
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
              <Link className="block min-w-0" href={`/${slug}/runs/${run.EventNumber}`}>
              <Card className="w-full max-w-full rounded-2xl gap-0 py-0 dark:border-white/25 dark:bg-white/[0.12] border-zinc-200 bg-white shadow-lg dark:shadow-black/50 hover:shadow-xl transition-shadow cursor-pointer group">
                <CardContent className="flex items-center gap-4 p-4">
                  {/* Run number badge */}
                  <div
                    className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl text-base font-bold"
                    style={{
                      backgroundColor: `color-mix(in srgb, var(--kennel-primary) 15%, transparent)`,
                      color: "var(--kennel-primary)",
                    }}
                  >
                    #{run.EventNumber}
                  </div>

                  {/* Details */}
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
                  </div>

                  {/* Hares */}
                  {run.Hares && (
                    <div className="hidden shrink-0 text-right md:block">
                      <div className="text-base uppercase tracking-[0.12em] dark:text-white text-zinc-900">Hares</div>
                      <div className="text-xl font-medium dark:text-white text-zinc-900 max-w-[120px] truncate">{run.Hares}</div>
                    </div>
                  )}

                  {/* Date badge */}
                  <div className="shrink-0 rounded-full border px-2.5 py-1 text-xl font-semibold dark:border-white/10 dark:text-white border-zinc-200 text-zinc-900" suppressHydrationWarning>
                    {shortDate}
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
