// Distances as the viewer reads them (James, 2026-09-27). The app's rule,
// in one place for the whole web:
//   metric   — under 1 km whole metres "350 m"; then one decimal "2.4 km";
//              from 100 km whole numbers "5,369 km".
//   imperial — under 1 mile whole yards "440 yd"; then one decimal "1.6 mi";
//              from 100 mi whole numbers "5,369 mi".

const METRES_PER_MILE = 1609.344;
const YARDS_PER_METRE = 1.0936133;

/** Formats [meters] for a metric (true) or imperial (false) viewer. */
export function formatDistance(meters: number, metric: boolean): string {
  const m = Math.max(0, meters);
  if (metric) {
    const whole = Math.round(m);
    if (whole < 1000) return `${whole} m`;
    const km = m / 1000;
    return km < 100 ? `${km.toFixed(1)} km` : `${Math.round(km).toLocaleString("en-US")} km`;
  }
  if (m < METRES_PER_MILE) {
    const yd = Math.round(m * YARDS_PER_METRE);
    return `${yd.toLocaleString("en-US")} yd`;
  }
  const mi = m / METRES_PER_MILE;
  return mi < 100 ? `${mi.toFixed(1)} mi` : `${Math.round(mi).toLocaleString("en-US")} mi`;
}

/** The handful of places that measure road distance in miles. */
export function localeUsesMiles(): boolean {
  if (typeof navigator === "undefined") return false;
  const tag = navigator.language || "";
  let region = "";
  try {
    region = (new Intl.Locale(tag).maximize().region ?? "").toUpperCase();
  } catch {
    region = (tag.split("-")[1] ?? "").toUpperCase();
  }
  return region === "US" || region === "GB" || region === "LR" || region === "MM";
}

/**
 * Whether this viewer wants miles — the app's Utilities.prefersImperial:
 * the hasher's explicit choice (HasherPreferences & 3: 3 = miles, 1/2 = km)
 * wins; Auto (0) follows the kennel's DistancePreference (bit 0: 1 = miles)
 * when there is one, else the browser's region.
 */
export function prefersImperial(
  hasherPrefs?: number | null,
  kennelDistancePref?: number | null,
): boolean {
  const p = (hasherPrefs ?? 0) & 0x03;
  if (p === 3) return true;
  if (p !== 0) return false;
  if (kennelDistancePref != null) return (kennelDistancePref & 0x01) === 1;
  return localeUsesMiles();
}

// ── "Runs within N" — the app's radius ladder, in the hasher's OWN unit ─────
// 50 means 50 km to someone on kilometres and 50 miles to someone on miles.
// 0 is kept so the section can be switched off, but is never the default:
// the preference bitfield is 0 until somebody touches it (James, 2026-09-17).

export const RADII = [0, 10, 25, 50, 75, 100, 150, 200];
export const DEFAULT_RADIUS = 50;
export const MILE_IN_METRES = METRES_PER_MILE;

/** Preferences & 0x3C >> 2 indexes the ladder; rung 0 means "never set". */
export function radiusFromPrefs(prefs: number): number {
  const rung = (prefs & 0x3c) >> 2;
  return RADII[rung] && rung > 0 ? RADII[rung] : DEFAULT_RADIUS;
}

/** The radius this browser chose (Runs page), else the hasher's own rung. */
export function currentRadius(prefs: number): number {
  try {
    if (typeof localStorage !== "undefined") {
      const raw = localStorage.getItem("hc_radius");
      const v = raw === null ? NaN : Number(raw);
      if (Number.isFinite(v) && RADII.includes(v)) return v;
    }
  } catch { /* private window */ }
  return radiusFromPrefs(prefs);
}

/** "50 km" / "50 mi" — a radius label (whole numbers, the ladder's). */
export function radiusLabel(radius: number, metric: boolean): string {
  return `${radius} ${metric ? "km" : "mi"}`;
}
