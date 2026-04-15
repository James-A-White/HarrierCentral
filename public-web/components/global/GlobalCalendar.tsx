"use client";

import { useState, useEffect, useRef, useCallback, useMemo } from "react";
import type { GlobalCalendarRow } from "@/lib/api";

// ─── Constants ────────────────────────────────────────────────────────────────

const DAYS_PER_PAGE = 30;
const MAX_DAYS_AHEAD = 365;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Adds `days` to a YYYY-MM-DD string, returns a new YYYY-MM-DD string. */
function addDays(dateStr: string, days: number): string {
  const d = new Date(dateStr + "T12:00:00Z");
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Today's date in YYYY-MM-DD format, in the browser's local timezone. */
function getTodayStr(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Returns an array of `count` consecutive YYYY-MM-DD strings starting from `fromDate`. */
function generateDateRange(fromDate: string, count: number): string[] {
  return Array.from({ length: count }, (_, i) => addDays(fromDate, i));
}

/** Builds a Map from date string → kennel rows for O(1) lookup while rendering. */
function buildRunsMap(rows: GlobalCalendarRow[]): Map<string, GlobalCalendarRow[]> {
  const map = new Map<string, GlobalCalendarRow[]>();
  for (const row of rows) {
    const key = row.EventDate.slice(0, 10);
    if (!map.has(key)) map.set(key, []);
    map.get(key)!.push(row);
  }
  return map;
}

/** "Tue", "Wed", etc. */
function formatDayOfWeek(dateStr: string): string {
  return new Date(dateStr + "T12:00:00Z").toLocaleDateString("en-GB", {
    weekday: "short",
    timeZone: "UTC",
  });
}

/** "Apr 7", "Dec 25", etc. — no year. */
function formatShortDate(dateStr: string): string {
  return new Date(dateStr + "T12:00:00Z").toLocaleDateString("en-GB", {
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  });
}

// ─── KennelLogo ───────────────────────────────────────────────────────────────

function KennelLogo({ kennel }: { kennel: GlobalCalendarRow }) {
  const hasImage = kennel.KennelLogo?.startsWith("https://");
  const href =
    kennel.EventNumber > 0
      ? `/${kennel.KennelSlug}/${kennel.EventNumber}`
      : `/${kennel.KennelSlug}/`;
  const initial = kennel.KennelName.charAt(0).toUpperCase();
  const bg = kennel.PrimaryColor ?? "#dc2626";

  if (hasImage) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <a href={href} title={kennel.KennelName} className="block flex-shrink-0 transition-transform duration-150 hover:scale-105">
        <img
          src={kennel.KennelLogo!}
          alt={kennel.KennelName}
          className="h-12 w-12 object-contain"
        />
      </a>
    );
  }

  return (
    <a
      href={href}
      title={kennel.KennelName}
      className="block h-12 w-12 flex-shrink-0 overflow-hidden rounded-full ring-2 ring-white/10 transition-all duration-150 hover:ring-white/50 hover:scale-105"
    >
      <span
        className="flex h-full w-full items-center justify-center text-lg font-bold text-white"
        style={{ backgroundColor: bg }}
      >
        {initial}
      </span>
    </a>
  );
}

// ─── CalendarRow ──────────────────────────────────────────────────────────────

function CalendarRow({
  date,
  kennels,
  isToday,
}: {
  date: string;
  kennels: GlobalCalendarRow[] | undefined;
  isToday: boolean;
}) {
  const hasRuns = kennels && kennels.length > 0;

  return (
    <tr
      className={[
        "border-b border-white/8 transition-colors duration-100",
        isToday ? "bg-white/[0.06]" : "hover:bg-white/[0.03]",
      ].join(" ")}
    >
      {/* Date column */}
      <td className="w-20 px-4 py-4 align-middle">
        <div className="flex flex-col leading-none">
          <span className="flex items-center gap-2">
            <span
              className={`text-base font-semibold ${
                isToday ? "text-white" : "text-zinc-300"
              }`}
            >
              {formatDayOfWeek(date)}
            </span>
            {isToday && (
              <span className="rounded-full bg-red-600 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-white">
                Today
              </span>
            )}
          </span>
          <span className="mt-1 text-xs text-zinc-500">
            {formatShortDate(date)}
          </span>
        </div>
      </td>

      {/* Kennel logos — or empty day message */}
      <td className="px-4 py-3 align-middle">
        {hasRuns ? (
          <div className="flex min-w-0 flex-wrap gap-2">
            {kennels.map((kennel) => (
              <KennelLogo key={kennel.PublicKennelId} kennel={kennel} />
            ))}
          </div>
        ) : (
          <span className="text-sm text-zinc-600 italic">
            No runs yet for today.
          </span>
        )}
      </td>
    </tr>
  );
}

// ─── GlobalCalendar ───────────────────────────────────────────────────────────

interface GlobalCalendarProps {
  initialRows: GlobalCalendarRow[];
  /** The date used for the initial server fetch (YYYY-MM-DD). */
  initialFromDate: string;
}

export function GlobalCalendar({
  initialRows,
  initialFromDate,
}: GlobalCalendarProps) {
  const todayStr = getTodayStr();
  const maxDate = useMemo(
    () => addDays(initialFromDate, MAX_DAYS_AHEAD),
    [initialFromDate]
  );

  // Full sequence of dates to render — grows as the user scrolls
  const [dateRange, setDateRange] = useState<string[]>(() =>
    generateDateRange(initialFromDate, DAYS_PER_PAGE)
  );

  // Map of date → kennel rows for O(1) lookup while rendering
  const [runsByDate, setRunsByDate] = useState<Map<string, GlobalCalendarRow[]>>(
    () => buildRunsMap(initialRows)
  );

  const [nextFromDate, setNextFromDate] = useState(() =>
    addDays(initialFromDate, DAYS_PER_PAGE)
  );
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(
    () => addDays(initialFromDate, DAYS_PER_PAGE) < maxDate
  );
  const sentinelRef = useRef<HTMLDivElement>(null);

  const loadMore = useCallback(async () => {
    if (loading || !hasMore) return;
    if (nextFromDate >= maxDate) {
      setHasMore(false);
      return;
    }
    setLoading(true);
    try {
      const res = await fetch(
        `/api/global-calendar?fromDate=${nextFromDate}&daysLimit=${DAYS_PER_PAGE}`
      );
      if (!res.ok) throw new Error("Failed to fetch");
      const newRows: GlobalCalendarRow[] = await res.json();

      // Extend the date range to cover the newly loaded window
      const newDates = generateDateRange(nextFromDate, DAYS_PER_PAGE);
      setDateRange((prev) => [...prev, ...newDates]);

      // Merge new run rows into the lookup map
      if (newRows.length > 0) {
        setRunsByDate((prev) => {
          const next = new Map(prev);
          for (const row of newRows) {
            const key = row.EventDate.slice(0, 10);
            if (!next.has(key)) next.set(key, []);
            next.get(key)!.push(row);
          }
          return next;
        });
      }

      const newNextDate = addDays(nextFromDate, DAYS_PER_PAGE);
      setNextFromDate(newNextDate);
      if (newNextDate >= maxDate) setHasMore(false);
    } catch {
      // Silently swallow — IntersectionObserver will retry on the next scroll
    } finally {
      setLoading(false);
    }
  }, [loading, hasMore, nextFromDate, maxDate]);

  // Attach IntersectionObserver to the sentinel div
  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel || !hasMore) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) loadMore();
      },
      { rootMargin: "400px" }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [loadMore, hasMore]);

  return (
    <div className="overflow-hidden rounded-xl border border-white/10">
      <table className="w-full border-collapse">
        <tbody>
          {dateRange.map((date) => (
            <CalendarRow
              key={date}
              date={date}
              kennels={runsByDate.get(date)}
              isToday={date === todayStr}
            />
          ))}
        </tbody>
      </table>

      {/* Scroll sentinel + loading indicator */}
      <div ref={sentinelRef} className="flex justify-center py-6">
        {loading && (
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/20 border-t-white/60" />
        )}
        {!hasMore && (
          <p className="text-xs text-zinc-600">No more upcoming runs</p>
        )}
      </div>
    </div>
  );
}
