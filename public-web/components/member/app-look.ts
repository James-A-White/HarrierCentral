/**
 * The app's visual language, for the member pages to match it (James,
 * 2026-09-16: "double check that the UI for the web closely matches the UI
 * in the app"). The app draws WHITE cards on the jungle background with
 * dark text, blue (Colors.blue.shade800) for counts and links, red
 * (Colors.red.shade900) for the primary button, green.shade800 for "my run
 * #N" and purple.shade800 for haring — and the RSVP as the three checkbox
 * icons, not words.
 */
export const HC_BLUE = "#1565C0";
export const HC_RED = "#B71C1C";
export const HC_GREEN = "#2E7D32";
export const HC_PURPLE = "#6A1B9A";
export const APP_BAR = "#580438";

export const card = "rounded-xl bg-white text-zinc-900 shadow-md";
export const cardDivider = "border-t border-zinc-300";
export const titleText = "text-[17px] font-bold leading-snug text-zinc-900";
export const bodyText = "text-[15px] text-zinc-800";
export const mutedText = "text-[14px] text-zinc-500";
export const blueText = "text-[15px] font-semibold";

/** The app's date line: "Sat, Sep 19 at 12:00 PM". */
export function appDate(local: string, gmt?: string | null, tz?: string | null): string {
  // A wall-clock string with no zone must not be parsed as the browser's
  // local time (it came out an hour off in BST): pin it to UTC and format
  // in UTC, so it reads back exactly as stored.
  const naive = !/Z$|[+-]\d\d:\d\d$/.test(local);
  const src = gmt && tz ? new Date(gmt) : new Date(naive ? `${local}Z` : local);
  const timeZone = gmt && tz ? tz : "UTC";
  const showYear = parseInt(src.toLocaleDateString("en-CA", { year: "numeric", timeZone }), 10) !== new Date().getFullYear();
  const day = src.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", timeZone, ...(showYear && { year: "numeric" }) });
  const time = src.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", timeZone });
  return `${day} at ${time}`;
}
