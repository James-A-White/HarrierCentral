"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock } from "lucide-react";
import type { EnrichedRun, DisplayOptions } from "./RunListBlock";

interface RunCalendarViewProps {
  runs: EnrichedRun[];
  slug: string;
  isFuture: boolean;
  showEmptyDays: boolean;
  days: number;
  display: DisplayOptions;
}

const LOGO_PX: Record<string, number> = { sm: 16, md: 24, lg: 36, xl: 52 };

function getRunDateKey(run: EnrichedRun): string {
  const gmt = run.event.EventStartDatetimeGmt;
  const tz   = run.kennel.ianaTimezone ?? run.event.KennelIANATimezone;
  if (gmt && tz) return new Date(gmt).toLocaleDateString("en-CA", { timeZone: tz });
  return run.event.EventStartDatetime.slice(0, 10);
}

function formatDayHeader(dateKey: string): string {
  const [y, m, d] = dateKey.split("-").map(Number);
  return new Date(y, m - 1, d).toLocaleDateString("en-GB", {
    weekday: "short", day: "numeric", month: "short",
  });
}

function formatTime(run: EnrichedRun): string {
  const gmt = run.event.EventStartDatetimeGmt;
  const tz   = run.kennel.ianaTimezone ?? run.event.KennelIANATimezone;
  const src  = gmt && tz ? new Date(gmt) : new Date(run.event.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  return src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz });
}

function dateRange(fromKey: string, toKey: string): string[] {
  const keys: string[] = [];
  const [fy, fm, fd] = fromKey.split("-").map(Number);
  const [ty, tm, td] = toKey.split("-").map(Number);
  const cur = new Date(fy, fm - 1, fd);
  const end = new Date(ty, tm - 1, td);
  while (cur <= end) {
    keys.push(cur.toLocaleDateString("en-CA"));
    cur.setDate(cur.getDate() + 1);
  }
  return keys;
}

export function RunCalendarView({
  runs, slug, isFuture, showEmptyDays, days, display,
}: RunCalendarViewProps) {
  if (runs.length === 0 && !showEmptyDays) {
    return (
      <p className="text-xl py-4" style={{ color: "var(--kennel-text-body)" }}>
        No runs to display.
      </p>
    );
  }

  // Group runs by date key
  const grouped = new Map<string, EnrichedRun[]>();
  for (const run of runs) {
    const key = getRunDateKey(run);
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key)!.push(run);
  }

  // Build ordered list of date keys
  let orderedKeys: string[];
  const todayKey = new Date().toLocaleDateString("en-CA");

  if (showEmptyDays && days > 0) {
    if (isFuture) {
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + days);
      orderedKeys = dateRange(todayKey, endDate.toLocaleDateString("en-CA"));
    } else {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      orderedKeys = dateRange(startDate.toLocaleDateString("en-CA"), yesterday.toLocaleDateString("en-CA")).reverse();
    }
  } else if (showEmptyDays && runs.length > 0) {
    const runKeys = [...grouped.keys()].sort();
    if (isFuture) {
      orderedKeys = dateRange(todayKey, runKeys[runKeys.length - 1]);
    } else {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      orderedKeys = dateRange(runKeys[0], yesterday.toLocaleDateString("en-CA")).reverse();
    }
  } else {
    orderedKeys = [...grouped.keys()].sort(isFuture ? undefined : (a, b) => b.localeCompare(a));
  }

  const showKennelCol = display.showKennelLogo || display.showKennelName;

  return (
    <div className="min-w-0 w-full">
      {orderedKeys.map((dateKey, dayIdx) => {
        const dayRuns = grouped.get(dateKey) ?? [];
        const isEmpty = dayRuns.length === 0;

        return (
          <motion.div
            key={dateKey}
            initial={{ opacity: 0, y: 6 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.4, delay: Math.min(dayIdx * 0.04, 0.4), ease: [0.19, 1, 0.22, 1] }}
            style={dayIdx > 0 ? { borderTop: "1px solid color-mix(in srgb, var(--kennel-text-muted) 30%, transparent)", marginTop: "4px" } : undefined}
          >
            {/* Day header */}
            <div className="flex items-center gap-3 px-1 py-2">
              <span
                className="text-sm font-semibold uppercase tracking-[0.1em]"
                style={{ color: isEmpty ? "var(--kennel-text-muted)" : "var(--kennel-text-title)" }}
              >
                {formatDayHeader(dateKey)}
              </span>
              {isEmpty && (
                <span className="text-sm" style={{ color: "var(--kennel-text-muted)" }}>—</span>
              )}
            </div>

            {/* Runs for this day — stacked as rows */}
            {dayRuns.map((entry, entryIdx) => {
              const run = entry.event;
              const isGuestRun = entry.kennel.slug !== slug;
              const href = isGuestRun
                ? display.isCustomDomain
                  ? `/guest/${entry.kennel.slug}/${run.EventNumber}`
                  : `/${slug}/guest/${entry.kennel.slug}/${run.EventNumber}`
                : `/${slug}/${run.EventNumber}`;
              const kennelColor = entry.kennel.primaryColor ?? "var(--kennel-accent, var(--kennel-primary))";

              return (
                <div key={run.PublicEventId}>
                {entryIdx > 0 && display.showDivider && (
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
                  <div className="flex min-w-0 items-center gap-3 rounded-xl px-1 py-2 transition-colors hover:bg-white/5">

                    {/* Far-left kennel indicator column */}
                    {showKennelCol && (
                      <div
                        className="flex shrink-0 flex-col items-center gap-0.5"
                        style={{ width: (LOGO_PX[display.kennelLogoSize] ?? 24) + 8 }}
                      >
                        {display.showKennelLogo && entry.kennel.logo && (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={entry.kennel.logo}
                            alt={entry.kennel.shortName}
                            className="object-contain"
                            style={{ width: LOGO_PX[display.kennelLogoSize] ?? 24, height: LOGO_PX[display.kennelLogoSize] ?? 24 }}
                          />
                        )}
                        {display.showKennelLogo && !entry.kennel.logo && (
                          <div
                            className="rounded-full flex items-center justify-center text-[9px] font-bold"
                            style={{
                              width:  LOGO_PX[display.kennelLogoSize] ?? 24,
                              height: LOGO_PX[display.kennelLogoSize] ?? 24,
                              backgroundColor: kennelColor,
                              color: "var(--kennel-primary-fg)",
                            }}
                          >
                            {entry.kennel.shortName.slice(0, 2).toUpperCase()}
                          </div>
                        )}
                        {display.showKennelName && (
                          <span
                            className="text-[10px] font-medium leading-none text-center"
                            style={{ color: "var(--kennel-text-muted)" }}
                          >
                            {entry.kennel.shortName}
                          </span>
                        )}
                      </div>
                    )}

                    {/* Run number badge */}
                    {display.showRunNumber && (
                      <div
                        className="flex shrink-0 min-w-[44px] items-center justify-center rounded-lg px-1.5 py-1 text-xs font-bold"
                        style={{ backgroundColor: kennelColor, color: "var(--kennel-primary-fg)" }}
                      >
                        #{run.EventNumber}
                      </div>
                    )}

                    {/* Name + detail lines */}
                    <div className="min-w-0 flex-1">
                      {(display.showRunName || display.showImage) && (
                        <div className="flex min-w-0 items-center gap-2">
                          {display.showImage && run.EventImage && (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img
                              src={run.EventImage}
                              alt={run.EventName}
                              className="shrink-0 w-8 h-8 rounded-md object-cover"
                              loading="lazy"
                            />
                          )}
                          {display.showRunName && (
                            <span
                              className="block truncate text-base font-semibold"
                              style={{ color: display.nameColor }}
                            >
                              {run.EventName}
                            </span>
                          )}
                        </div>
                      )}

                      {display.showTime && (
                        <div
                          className="flex items-center gap-1 text-sm"
                          style={{ color: display.detailColor }}
                          suppressHydrationWarning
                        >
                          <Clock className="h-3 w-3 shrink-0" />
                          {formatTime(entry)}
                        </div>
                      )}
                      {display.showLocation && (run.LocationOneLineDesc ?? run.LocationCity) && (
                        <div
                          className="flex min-w-0 items-center gap-1 text-sm"
                          style={{ color: display.detailColor }}
                        >
                          <MapPin className="h-3 w-3 shrink-0" />
                          <span className="min-w-0 truncate">
                            {run.LocationOneLineDesc ?? run.LocationCity}
                          </span>
                        </div>
                      )}

                      {display.showHares && run.Hares && (
                        <div
                          className="flex min-w-0 items-center gap-1 text-sm"
                          style={{ color: display.detailColor }}
                        >
                          <span className="shrink-0 text-xs uppercase tracking-[0.1em]">Hares:</span>
                          <span className="min-w-0 truncate">{run.Hares}</span>
                        </div>
                      )}
                    </div>

                  </div>
                </Link>
                </div>
              );
            })}
          </motion.div>
        );
      })}
    </div>
  );
}
