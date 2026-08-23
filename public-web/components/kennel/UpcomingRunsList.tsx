"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";
import ViewerLocalTime from "@/components/ViewerLocalTime";

interface UpcomingRunsListProps {
  runs: RunEvent[];
  slug: string;
}

function formatShortDate(run: RunEvent): { dayTime: string; shortDate: string } {
  const gmt = run.EventStartDatetimeGmt;
  const tz  = run.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  return {
    dayTime: src.toLocaleDateString("en-GB", { weekday: "short", timeZone: displayTz }) + " · " +
             src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz }),
    shortDate: src.toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: displayTz }),
  };
}

export function UpcomingRunsList({ runs, slug }: UpcomingRunsListProps) {
  return (
    <div className="min-w-0 w-full max-w-full">
      <div className="mb-4 flex min-w-0 items-center justify-between gap-3">
        <h2 className="min-w-0 text-2xl font-bold" style={{ color: "var(--kennel-text-title)" }}>Upcoming runs</h2>
        <Link
          href={`/${slug}/runs`}
          className="shrink-0 text-xl font-medium"
          style={{ color: "var(--kennel-text-body)" }}
        >
          Full calendar →
        </Link>
      </div>
      <div className="space-y-3">
        {runs.length === 0 && (
          <p className="text-xl py-4" style={{ color: "var(--kennel-text-body)" }}>No upcoming runs scheduled.</p>
        )}
        {runs.map((run, i) => {
          const { dayTime, shortDate } = formatShortDate(run);
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
              <Card className="w-full max-w-full rounded-2xl gap-0 py-0 dark:border-white/25 border-zinc-200 shadow-lg dark:shadow-black/50 hover:shadow-xl transition-shadow cursor-pointer group" style={{ backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))" }}>
                <CardContent className="flex items-center gap-4 p-4">
                  {/* Left column: date above run number badge */}
                  <div className="flex shrink-0 flex-col items-center gap-1.5">
                    <div className="text-sm font-semibold text-center" style={{ color: "var(--kennel-text-muted)" }} suppressHydrationWarning>
                      {shortDate}
                    </div>
                    <div
                      className="flex min-w-[48px] items-center justify-center rounded-xl px-2 py-1.5 text-sm font-bold"
                      style={{ backgroundColor: "var(--kennel-accent, var(--kennel-primary))", color: "var(--kennel-primary-fg)" }}
                    >
                      #{run.EventNumber}
                    </div>
                  </div>

                  {/* Details — full remaining width */}
                  <div className="min-w-0 flex-1">
                    <div className="text-2xl font-semibold truncate transition-colors group-hover:text-[var(--kennel-primary)]" style={{ color: "var(--kennel-text-title)" }}>
                      {run.EventName}
                    </div>
                    <div className="mt-1 flex min-w-0 flex-wrap gap-x-3 gap-y-0.5 text-xl" style={{ color: "var(--kennel-text-body)" }}>
                      <span className="flex items-center gap-1" suppressHydrationWarning>
                        <Clock className="h-3 w-3" />
                        {dayTime}
                      </span>
                      <ViewerLocalTime
                        gmt={run.EventStartDatetimeGmt}
                        kennelTz={run.KennelIANATimezone}
                        className="text-base italic opacity-70"
                      />
                      {(run.LocationOneLineDesc ?? run.LocationCity) && (
                        <span className="flex min-w-0 max-w-full items-center gap-1">
                          <MapPin className="h-3 w-3 shrink-0" />
                          <span className="min-w-0 truncate">{run.LocationOneLineDesc ?? run.LocationCity}</span>
                        </span>
                      )}
                    </div>
                    {run.Hares && (
                      <div className="mt-0.5 flex min-w-0 items-center gap-1.5 text-xl" style={{ color: "var(--kennel-text-muted)" }}>
                        <span className="shrink-0 text-sm uppercase tracking-[0.12em]">Hares:</span>
                        <span className="min-w-0 truncate font-medium" style={{ color: "var(--kennel-text-body)" }}>{run.Hares}</span>
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
