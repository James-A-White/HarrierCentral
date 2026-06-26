export interface TrackPoint {
  lat: number;
  lng: number;
  acc: number;
  timestampMs: number;
  type?: string;
}

export interface UserTrack {
  id: string;
  positions: TrackPoint[];
}

export interface PackTrackPayload {
  eventId: string;
  latestServerTimestampMs?: string;
  users: UserTrack[];
}

// ── Trail marks ────────────────────────────────────────────────────────────────
// A track point's `type` field is one of:
//   • null/empty          → a continuous GPS point (drawn as the polyline)
//   • a slot icon filename → e.g. "I-100.png" (new dynamic icon collection); the
//                            type IS the icon filename. Optional "::label" suffix.
//   • a HashRunPointTypes  → legacy key e.g. "CHK", "CAU::watch the road". Resolved
//     key                    to a PNG via LEGACY_ICON below.
//   • "PHO::<blobId>"      → a run-photo marker (member-only; skipped on public web)
// Mirrors run_tracker_map_controller._parseCheckpointType in the mobile app.

const ICON_BASE = "/images/live_run_map_markers";

// Legacy HashRunPointTypes key → PNG icon filename (lib/util/enums.dart).
const LEGACY_ICON: Record<string, string> = {
  CHK: "check.png",
  DRK: "drinkstop.png",
  FHK: "fishhook.png",
  SC: "shortcut.png",
  CB: "checkback.png",
  HV: "hashview.png",
  RG: "regroup.png",
  WW: "whichyway.png",
  FT: "falsetrail.png",
  LAB: "label.png",
  OIN: "oninn.png",
  CAU: "caution.png",
  DDN: "gavel.png",
  // PHO has no flat icon (photo marker) — handled separately and skipped on web.
};

export interface ParsedMark {
  /** Absolute URL of the icon PNG, or null when the mark has no flat icon (photos). */
  iconUrl: string | null;
  /** Optional display label (LAB / CAU / slot "addText" marks). */
  label: string | null;
  isOnInn: boolean;
  isCaution: boolean;
  isPhoto: boolean;
}

/** Resolve a track point's `type` to a renderable mark, or null for GPS points. */
export function parseMark(rawType: string | null | undefined): ParsedMark | null {
  const value = rawType?.trim();
  if (!value) return null;

  const parts = value.split("::");
  const key = parts[0].trim();
  const labelRaw = parts.length > 1 ? parts.slice(1).join("::").trim() : "";
  const label = labelRaw.length > 0 ? labelRaw : null;

  // New-style slot icon — the key is the icon filename itself.
  if (key.startsWith("I-")) {
    return { iconUrl: `${ICON_BASE}/${key}`, label, isOnInn: false, isCaution: false, isPhoto: false };
  }

  if (key === "PHO") {
    // Photo markers require blob resolution + approval — not shown on public web.
    return { iconUrl: null, label, isOnInn: false, isCaution: false, isPhoto: true };
  }

  const icon = LEGACY_ICON[key];
  if (!icon) return null;
  return {
    iconUrl: `${ICON_BASE}/${icon}`,
    label,
    isOnInn: key === "OIN",
    isCaution: key === "CAU",
    isPhoto: false,
  };
}

/** True when this point ends the drawn track (On Inn). */
export function isOnInn(rawType: string | null | undefined): boolean {
  return parseMark(rawType)?.isOnInn ?? false;
}

// ── Geometry / formatting (ported from run_tracker_map_controller) ───────────────

const METERS_TO_MILES = 0.000621371;
export const MARK_DEDUPE_METERS = 25;

// ── GPS noise filter (ported from lib/util/track_point_filter.dart) ─────────────
// Multi-stage clean-up applied to each runner's raw track before rendering:
//   1. drop poor-accuracy points (> 50 m) and near-duplicate timestamps (< 1000 ms)
//   2. drop unrealistic velocities (> 5 m/s) measured against the last good point
//   3. interpolate replacements for dropped points at their original timestamps
// Typed points (hash marks, photos) are intentional and never filtered.

const FILTER_MAX_ACCURACY_M = 50;
const FILTER_MAX_VELOCITY_MPS = 5;
const FILTER_MIN_TIME_DELTA_MS = 1000;

function pointIsTyped(p: TrackPoint): boolean {
  return !!(p.type && p.type.trim().length > 0);
}

function evaluatePointQuality(points: TrackPoint[]): boolean[] {
  const quality = points.map(() => true);

  // Pass 1: accuracy + de-duplication by time delta against the raw previous point.
  for (let i = 0; i < points.length; i++) {
    const p = points[i];
    if (pointIsTyped(p)) continue; // never filter intentional marks
    if (p.acc > FILTER_MAX_ACCURACY_M) { quality[i] = false; continue; }
    if (i > 0 && p.timestampMs - points[i - 1].timestampMs < FILTER_MIN_TIME_DELTA_MS) {
      quality[i] = false;
    }
  }

  // Pass 2: velocity against the last good point (prevents cascading from bad points).
  let lastGood: number | null = null;
  for (let i = 0; i < points.length; i++) {
    if (!quality[i]) continue;
    const p = points[i];
    if (!pointIsTyped(p) && lastGood !== null) {
      const lg = points[lastGood];
      const dtMs = p.timestampMs - lg.timestampMs;
      if (dtMs > 0) {
        const v = haversineMeters(lg.lat, lg.lng, p.lat, p.lng) / (dtMs / 1000);
        if (v > FILTER_MAX_VELOCITY_MPS) { quality[i] = false; continue; }
      }
    }
    lastGood = i;
  }
  return quality;
}

/**
 * Cleans a runner's track: removes inaccurate / impossible GPS points and
 * interpolates replacements at the original timestamps so the path stays
 * continuous. Mirrors TrackPointFilter.filterAndInterpolate. Returns the input
 * unchanged when there are fewer than 2 good points (better to show questionable
 * data than none).
 */
export function filterAndInterpolate(points: TrackPoint[]): TrackPoint[] {
  if (points.length < 2) return points;
  const quality = evaluatePointQuality(points);
  if (quality.filter(Boolean).length < 2) return points;

  const out: TrackPoint[] = [];
  let lastGood: number | null = null;
  for (let i = 0; i < points.length; i++) {
    if (!quality[i]) continue;
    if (lastGood !== null && i > lastGood + 1) {
      // Replace the dropped points between two good ones with interpolated positions.
      const start = points[lastGood];
      const end = points[i];
      const span = end.timestampMs - start.timestampMs;
      if (span > 0) {
        for (let j = lastGood + 1; j < i; j++) {
          const bad = points[j];
          const ratio = Math.min(1, Math.max(0, (bad.timestampMs - start.timestampMs) / span));
          out.push({
            lat: start.lat + (end.lat - start.lat) * ratio,
            lng: start.lng + (end.lng - start.lng) * ratio,
            acc: (start.acc + end.acc) / 2,
            timestampMs: bad.timestampMs,
            type: bad.type,
          });
        }
      }
    }
    out.push(points[i]);
    lastGood = i;
  }
  return out;
}

/** Haversine distance in metres between two lat/lng points. */
export function haversineMeters(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const R = 6371000;
  const dLat = ((bLat - aLat) * Math.PI) / 180;
  const dLng = ((bLng - aLng) * Math.PI) / 180;
  const lat1 = (aLat * Math.PI) / 180;
  const lat2 = (bLat * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** "YYYY-MM-DD HH:mm:ss" in local time, matching the app's timeline label. */
export function formatTrackTimestamp(epochMs: number | null): string {
  if (epochMs == null) return "--:--";
  const d = new Date(epochMs);
  const p = (n: number) => n.toString().padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

/** "X mi / Y km" — 1 dp at/above 10, else 2 dp, matching the app. */
export function formatDistanceLabel(meters: number): string {
  const miles = meters * METERS_TO_MILES;
  const km = meters / 1000;
  const m = miles >= 10 ? miles.toFixed(1) : miles.toFixed(2);
  const k = km >= 10 ? km.toFixed(1) : km.toFixed(2);
  return `${m} mi / ${k} km`;
}

/**
 * Points of a runner's track up to `cutoff` (inclusive), terminating at the first
 * On Inn, with a final interpolated point at exactly `cutoff` for smooth growth.
 * Mirrors _interpolatedTrackPoints. Pass cutoff = Infinity for the full track.
 */
export function trackUpTo(positions: TrackPoint[], cutoff: number): TrackPoint[] {
  const out: TrackPoint[] = [];
  let idx = -1;
  for (let i = 0; i < positions.length; i++) {
    const p = positions[i];
    if (p.timestampMs > cutoff) break;
    out.push(p);
    idx = i;
    if (isOnInn(p.type)) return out; // terminator — no interpolation past it
  }
  if (out.length === 0) return positions.length ? [positions[0]] : [];

  // Interpolate the partial segment to `cutoff`.
  const next = positions[idx + 1];
  const last = out[out.length - 1];
  if (next && cutoff > last.timestampMs && next.timestampMs > last.timestampMs && !isOnInn(next.type)) {
    const ratio = Math.min(1, (cutoff - last.timestampMs) / (next.timestampMs - last.timestampMs));
    out.push({
      lat: last.lat + (next.lat - last.lat) * ratio,
      lng: last.lng + (next.lng - last.lng) * ratio,
      acc: last.acc,
      timestampMs: cutoff,
    });
  }
  return out;
}

/** Total length in metres of a sequence of track points. */
export function sumDistanceMeters(points: TrackPoint[]): number {
  let total = 0;
  for (let i = 1; i < points.length; i++) {
    total += haversineMeters(points[i - 1].lat, points[i - 1].lng, points[i].lat, points[i].lng);
  }
  return total;
}

/**
 * Resolves PackTrack runner ids to display names via the publicWeb_getEventRunners
 * SP. Returns a map of lowercased userId → display name. Never throws — names are
 * optional UI sugar, so any failure yields an empty map (callers fall back to
 * "Runner N").
 */
export async function fetchRunnerNames(
  publicEventId: string,
  userIds: string[],
): Promise<Record<string, string>> {
  if (!publicEventId || userIds.length === 0) return {};
  try {
    const params = new URLSearchParams({ publicEventId, userIds: userIds.join("|") });
    const res = await fetch(`/api/runner-names?${params.toString()}`);
    if (!res.ok) return {};
    const data = (await res.json()) as { runners?: { userId?: string; displayName?: string }[] };
    const map: Record<string, string> = {};
    for (const r of data.runners ?? []) {
      if (r.userId && r.displayName) map[r.userId.toLowerCase()] = r.displayName;
    }
    return map;
  } catch (err) {
    console.error("[runner-names] client fetch error:", err);
    return {};
  }
}

export async function fetchPackTrack(eventId: string): Promise<PackTrackPayload | null> {
  try {
    const res = await fetch(`/api/packtrack?eventId=${encodeURIComponent(eventId)}`);
    if (!res.ok) {
      console.error(`[packtrack] client fetch failed: ${res.status}`, await res.text());
      return null;
    }
    const data = await res.json() as PackTrackPayload;
    console.log(`[packtrack] eventId=${eventId} users=${data.users?.length ?? 0}`, data);
    return data;
  } catch (err) {
    console.error("[packtrack] client fetch error:", err);
    return null;
  }
}
