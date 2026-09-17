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

// ── Distance, as the app (Utilities.getDistance) ─────────────────────────────

/** Kennel / country DistancePreference: bit 0 clear = metric. */
export function isMetric(pref: number): boolean { return (pref & 0x01) === 0; }

export function formatDistance(meters: number, metric: boolean): string {
  if (metric) {
    const km = meters / 1000;
    return km < 10 ? `${km.toFixed(1)} km` : `${Math.round(km)} km`;
  }
  const miles = meters * 0.000621371;
  return miles < 10 ? `${miles.toFixed(1)} miles` : `${Math.round(miles)} miles`;
}

/** Great-circle distance in metres. */
export function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000, toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1), dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

// ── The bell and the envelope (run_list_item / kennel_list_item) ─────────────

/** _getNotificationWidget: bell by notification preference (1 on · 2 ignore · 3 mute · 4 before the run). */
export function bellIcon(pref: number): string {
  switch (pref) {
    case 1: return "bell_gold_50px";
    case 2: return "bell_silver_strike_out_50px";
    case 4: return "bell_time_50px";
    default: return "bell_silver_50px";
  }
}
/** _getEmailWidget: envelope by email-alert preference (1 on · 2 off). */
export function envelopeIcon(pref: number): string {
  return pref === 1 ? "envelope_gold_50px" : pref === 2 ? "envelope_silver_strike_out_50px" : "envelope_silver_50px";
}

/** The app's money format: the symbol carries a ^ where the amount goes ("£^", "^ kr"). */
export function money(v: number, symbol: string | null, digits: number): string {
  const amount = (Number(v) || 0).toFixed(Math.max(0, Math.min(4, digits)));
  const t = symbol && symbol.includes("^") ? symbol : `${symbol ?? ""}^`;
  return t.replace("^", amount);
}
