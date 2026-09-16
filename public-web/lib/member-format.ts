/** Date helpers for the member pages — the same shapes the global runs list uses. */
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
