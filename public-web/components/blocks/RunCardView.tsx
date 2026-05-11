"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock, Calendar } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { EnrichedRun, DisplayOptions } from "./RunListBlock";

const LOGO_PX: Record<string, number> = { sm: 16, md: 24, lg: 36, xl: 52 };

interface RunCardViewProps {
  runs: EnrichedRun[];
  slug: string;
  display: DisplayOptions;
  flat?: boolean;
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

export function RunCardView({ runs, slug, display, flat = false }: RunCardViewProps) {
  if (runs.length === 0) {
    return (
      <p className="text-base py-4" style={{ color: "var(--kennel-text-body)" }}>
        No runs to display.
      </p>
    );
  }

  const showLeftCol     = display.showRunNumber;
  const showKennelBadge = display.showKennelLogo || display.showKennelName;

  return (
    <div className={flat ? "" : "space-y-3"}>
      {runs.map((entry, i) => {
        const run = entry.event;
        const { shortDate, weekday, time } = formatDateParts(entry);
        const kennelColor = entry.kennel.primaryColor ?? "var(--kennel-accent, var(--kennel-primary))";
        const isGuestRun = entry.kennel.slug !== slug;
        const href = isGuestRun
          ? display.isCustomDomain
            ? `/guest/${entry.kennel.slug}/${run.EventNumber}`
            : `/${slug}/guest/${entry.kennel.slug}/${run.EventNumber}`
          : `/${slug}/${run.EventNumber}`;
        const dateLabel = display.showDate ? `${weekday}, ${shortDate}` : null;

        // Shared inner content — identical in card and flat modes
        const inner = (
          <>
            {/* Run number badge */}
            {showLeftCol && (
              <div className="flex shrink-0 flex-col items-center">
                <div
                  className="flex min-w-[48px] items-center justify-center rounded-xl px-2 py-1.5 text-sm font-bold"
                  style={{ backgroundColor: kennelColor, color: "var(--kennel-primary-fg)" }}
                >
                  #{run.EventNumber}
                </div>
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
              {/* Name + kennel badge row */}
              <div className="flex min-w-0 items-start justify-between gap-2">
                {display.showRunName && (
                  <div
                    className="text-base font-semibold truncate transition-colors group-hover:text-[var(--kennel-primary)]"
                    style={{ color: display.nameColor }}
                  >
                    {run.EventName}
                  </div>
                )}
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

              {/* Date */}
              {dateLabel && (
                <div
                  className="mt-1 flex items-center gap-1 text-sm"
                  style={{ color: display.detailColor }}
                  suppressHydrationWarning
                >
                  <Calendar className="h-3 w-3 shrink-0" />
                  <span>{dateLabel}</span>
                </div>
              )}

              {/* Time */}
              {display.showTime && (
                <div
                  className="mt-0.5 flex items-center gap-1 text-sm"
                  style={{ color: display.detailColor }}
                  suppressHydrationWarning
                >
                  <Clock className="h-3 w-3 shrink-0" />
                  <span>{time}</span>
                </div>
              )}

              {/* Location */}
              {display.showLocation && (run.LocationOneLineDesc ?? run.LocationCity) && (
                <div
                  className="mt-0.5 flex min-w-0 items-center gap-1 text-sm"
                  style={{ color: display.detailColor }}
                >
                  <MapPin className="h-3 w-3 shrink-0" />
                  <span className="min-w-0 truncate">
                    {run.LocationOneLineDesc ?? run.LocationCity}
                  </span>
                </div>
              )}

              {/* Hares */}
              {display.showHares && run.Hares && (
                <div
                  className="mt-0.5 flex min-w-0 items-center gap-1 text-sm"
                  style={{ color: display.detailColor }}
                >
                  <span className="shrink-0 uppercase tracking-[0.1em]">Hares:</span>
                  <span className="min-w-0 truncate">{run.Hares}</span>
                </div>
              )}
            </div>
          </>
        );

        return (
          <motion.div
            key={run.PublicEventId}
            className="min-w-0"
            initial={{ opacity: 0, y: 8 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: i * 0.07, ease: [0.19, 1, 0.22, 1] }}
          >
            {i > 0 && display.showDivider && (
              <hr
                className="border-0 my-0"
                style={{
                  borderTopWidth: `${display.dividerWidth}px`,
                  borderTopStyle: "solid",
                  borderTopColor: display.dividerColor,
                }}
              />
            )}

            <Link className="block min-w-0" href={href}>
              {flat ? (
                <div className="group flex items-center gap-4 rounded-xl px-1 py-3 transition-colors hover:bg-white/5 cursor-pointer">
                  {inner}
                </div>
              ) : (
                <Card
                  className="w-full max-w-full rounded-2xl gap-0 py-0 dark:border-white/25 border-zinc-200 shadow-lg dark:shadow-black/50 hover:shadow-xl transition-shadow cursor-pointer group"
                  style={{ backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))" }}
                >
                  <CardContent className="flex items-center gap-4 p-4">
                    {inner}
                  </CardContent>
                </Card>
              )}
            </Link>
          </motion.div>
        );
      })}
    </div>
  );
}
