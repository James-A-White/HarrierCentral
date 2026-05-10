"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { EnrichedRun, DisplayOptions } from "./RunListBlock";

const LOGO_PX: Record<string, number> = { sm: 16, md: 24, lg: 36, xl: 52 };

interface RunCardViewProps {
  runs: EnrichedRun[];
  slug: string;
  display: DisplayOptions;
}

function formatDateParts(run: EnrichedRun): { shortDate: string; weekday: string; time: string } {
  const gmt = run.event.EventStartDatetimeGmt;
  const tz   = run.kennel.ianaTimezone ?? run.event.KennelIANATimezone;
  const src  = gmt && tz ? new Date(gmt) : new Date(run.event.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  return {
    shortDate: src.toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: displayTz }),
    weekday:   src.toLocaleDateString("en-GB", { weekday: "short", timeZone: displayTz }),
    time:      src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz }),
  };
}

export function RunCardView({ runs, slug, display }: RunCardViewProps) {
  if (runs.length === 0) {
    return (
      <p className="text-xl py-4" style={{ color: "var(--kennel-text-body)" }}>
        No runs to display.
      </p>
    );
  }

  const showLeftCol = display.showDate || display.showRunNumber;
  const showKennelBadge = display.showKennelLogo || display.showKennelName;

  return (
    <div className="space-y-3">
      {runs.map((entry, i) => {
        const run = entry.event;
        const { shortDate, weekday, time } = formatDateParts(entry);
        const kennelColor = entry.kennel.primaryColor ?? "var(--kennel-accent, var(--kennel-primary))";
        const href = showKennelBadge
          ? `/${entry.kennel.slug}/${run.EventNumber}`
          : `/${slug}/${run.EventNumber}`;

        // Build the time/weekday display string
        const timeParts: string[] = [];
        if (display.showDate) timeParts.push(weekday);
        if (display.showTime) timeParts.push(time);
        const timeStr = timeParts.join(" · ");

        return (
          <motion.div
            key={run.PublicEventId}
            className="min-w-0"
            initial={{ opacity: 0, y: 8 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: i * 0.07, ease: [0.19, 1, 0.22, 1] }}
          >
            <Link className="block min-w-0" href={href}>
              <Card
                className="w-full max-w-full rounded-2xl gap-0 py-0 dark:border-white/25 border-zinc-200 shadow-lg dark:shadow-black/50 hover:shadow-xl transition-shadow cursor-pointer group"
                style={{ backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))" }}
              >
                <CardContent className="flex items-center gap-4 p-4">

                  {/* Left column: date + run number */}
                  {showLeftCol && (
                    <div className="flex shrink-0 flex-col items-center gap-1.5">
                      {display.showDate && (
                        <div
                          className="text-sm font-semibold text-center"
                          style={{ color: "var(--kennel-text-muted)" }}
                          suppressHydrationWarning
                        >
                          {shortDate}
                        </div>
                      )}
                      {display.showRunNumber && (
                        <div
                          className="flex min-w-[48px] items-center justify-center rounded-xl px-2 py-1.5 text-sm font-bold"
                          style={{ backgroundColor: kennelColor, color: "var(--kennel-primary-fg)" }}
                        >
                          #{run.EventNumber}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Run image thumbnail */}
                  {display.showImage && run.EventImage && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={run.EventImage}
                      alt={run.EventName}
                      className="shrink-0 w-20 h-20 rounded-xl object-cover"
                      loading="lazy"
                    />
                  )}

                  {/* Details */}
                  <div className="min-w-0 flex-1">
                    <div className="flex min-w-0 items-start justify-between gap-2">
                      {display.showRunName && (
                        <div
                          className="text-2xl font-semibold truncate transition-colors group-hover:text-[var(--kennel-primary)]"
                          style={{ color: "var(--kennel-text-title)" }}
                        >
                          {run.EventName}
                        </div>
                      )}

                      {/* Kennel badge — top right of details */}
                      {showKennelBadge && (
                        <div className="flex shrink-0 items-center gap-1.5 rounded-full border dark:border-white/20 border-zinc-200 px-2 py-0.5">
                          {display.showKennelLogo && entry.kennel.logo && (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={entry.kennel.logo}
                              alt={entry.kennel.shortName}
                              className="object-contain"
                              style={{ width: LOGO_PX[display.kennelLogoSize] ?? 24, height: LOGO_PX[display.kennelLogoSize] ?? 24 }}
                            />
                          )}
                          {display.showKennelName && (
                            <span className="text-xs font-medium" style={{ color: "var(--kennel-text-muted)" }}>
                              {entry.kennel.shortName}
                            </span>
                          )}
                        </div>
                      )}
                    </div>

                    {timeStr && (
                      <div
                        className="mt-1 flex min-w-0 flex-wrap gap-x-3 gap-y-0.5 text-xl"
                        style={{ color: "var(--kennel-text-body)" }}
                      >
                        <span className="flex items-center gap-1" suppressHydrationWarning>
                          <Clock className="h-3 w-3" />
                          {timeStr}
                        </span>
                        {display.showLocation && (run.LocationOneLineDesc ?? run.LocationCity) && (
                          <span className="flex min-w-0 max-w-full items-center gap-1">
                            <MapPin className="h-3 w-3 shrink-0" />
                            <span className="min-w-0 truncate">
                              {run.LocationOneLineDesc ?? run.LocationCity}
                            </span>
                          </span>
                        )}
                      </div>
                    )}

                    {!timeStr && display.showLocation && (run.LocationOneLineDesc ?? run.LocationCity) && (
                      <div
                        className="mt-1 flex min-w-0 items-center gap-1 text-xl"
                        style={{ color: "var(--kennel-text-body)" }}
                      >
                        <MapPin className="h-3 w-3 shrink-0" />
                        <span className="min-w-0 truncate">
                          {run.LocationOneLineDesc ?? run.LocationCity}
                        </span>
                      </div>
                    )}

                    {display.showHares && run.Hares && (
                      <div
                        className="mt-0.5 flex min-w-0 items-center gap-1.5 text-xl"
                        style={{ color: "var(--kennel-text-muted)" }}
                      >
                        <span className="shrink-0 text-sm uppercase tracking-[0.12em]">Hares:</span>
                        <span className="min-w-0 truncate font-medium" style={{ color: "var(--kennel-text-body)" }}>
                          {run.Hares}
                        </span>
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
  );
}
