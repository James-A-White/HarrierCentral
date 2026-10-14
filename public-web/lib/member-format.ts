/** Date helpers for the member pages — the same shapes the global runs list uses.
 *  packOffTime() is shared by every run view (kennel, global and member pages). */
const CURRENT_YEAR = new Date().getFullYear();

export function relativeTime(iso: string): string {
  const diffDays = Math.round((new Date(iso).getTime() - Date.now()) / 86_400_000);
  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Tomorrow";
  if (diffDays > 1 && diffDays < 14) return `in ${diffDays} days`;
  if (diffDays >= 14 && diffDays < 60) return `in ${Math.round(diffDays / 7)} weeks`;
  if (diffDays >= 60) { const m = Math.round(diffDays / 30); return `in ${m} month${m !== 1 ? "s" : ""}`; }
  if (diffDays === -1) return "Yesterday";
  if (diffDays > -14) return `${Math.abs(diffDays)} days ago`;
  if (diffDays > -60) return `${Math.round(Math.abs(diffDays) / 7)} weeks ago`;
  if (diffDays > -365) { const m = Math.round(Math.abs(diffDays) / 30); return `${m} month${m !== 1 ? "s" : ""} ago`; }
  const y = Math.round(Math.abs(diffDays) / 365);
  return `${y} year${y !== 1 ? "s" : ""} ago`;
}

export function formatRunDate(run: { EventStartDatetime: string; EventStartDatetimeGmt?: string | null; KennelIANATimezone?: string | null }) {
  const gmt = run.EventStartDatetimeGmt;
  const tz = run.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  const year = parseInt(src.toLocaleDateString("en-CA", { year: "numeric", timeZone: displayTz }), 10);
  const showYear = year !== CURRENT_YEAR;
  return {
    short: src.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: displayTz, ...(showYear && { year: "numeric" }) }),
    time: src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz }),
  };
}

/** Local wall-clock date only — for history rows, where the kennel timezone is not carried. */
export function formatLocalDate(local: string): string {
  const d = new Date(local);
  const showYear = d.getUTCFullYear() !== CURRENT_YEAR;
  return d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC", ...(showYear && { year: "numeric" }) });
}

/** The next round number worth a badge: 25, 50, 100, 150, 200… */
export function nextMilestone(runs: number): number {
  if (runs < 25) return 25;
  if (runs < 50) return 50;
  if (runs < 100) return 100;
  return (Math.floor(runs / 50) + 1) * 50;
}

/**
 * A run's pack-off clock time (E3.F1.S6): the gather's displayed wall-clock
 * time, exactly as the run view already formats it ("12:00", "12:00 BST" or
 * "12:00 PM"), plus the effective pack-off minutes. Pure wall-clock arithmetic
 * — no time-zone conversion — so the result is in the same local clock as the
 * gather it is shown beside, and in the same 24h/12h style (the zone label,
 * if any, is left to the caller). Returns null when there is no pack-off
 * (null, absent or <= 0 minutes) or the time cannot be read, so callers
 * render exactly as before.
 */
export function packOffTime(gatherTime: string | null | undefined, minutes: number | null | undefined): string | null {
  if (!gatherTime || minutes == null || !(minutes > 0)) return null;
  const m = /^(\d{1,2}):(\d{2})(?:(\s*)([AaPp])\.?\s*[Mm]\.?)?/.exec(gatherTime.trim());
  if (!m) return null;
  let hour = Number(m[1]);
  const meridiem = m[4]?.toUpperCase();
  if (meridiem) hour = (hour % 12) + (meridiem === "P" ? 12 : 0);
  const total = (hour * 60 + Number(m[2]) + Math.round(minutes)) % 1440;
  const h24 = Math.floor(total / 60);
  const mm = String(total % 60).padStart(2, "0");
  if (meridiem) {
    // Keep the original's spacing (Intl uses a narrow no-break space) and case.
    const h12 = h24 % 12 === 0 ? 12 : h24 % 12;
    const suffix = h24 < 12 ? "AM" : "PM";
    return `${h12}:${mm}${m[3]}${m[4] === m[4].toLowerCase() ? suffix.toLowerCase() : suffix}`;
  }
  return `${m[1].length === 2 ? String(h24).padStart(2, "0") : h24}:${mm}`;
}
