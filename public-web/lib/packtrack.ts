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
  /** Per-kennel trail-type config JSON, bundled by GetPositions on the full fetch. */
  trailTypesConfigJson?: string;
  users: UserTrack[];
}

// ── Trail marks ────────────────────────────────────────────────────────────────
// A track point's `type` field is one of (see docs/trail_markers/SPEC.md §3):
//   • null/empty          → a continuous GPS point (drawn as the polyline)
//   • "GLY::<glyphId>"    → a glyph mark; optional "::L=label" "::A=action" attrs
//   • "TXT::<text>"       → a text mark (text may contain spaces = newlines)
//   • a slot icon filename → legacy "I-100.png"; the type IS the icon filename
//   • a HashRunPointTypes  → legacy key e.g. "CHK", "CAU::watch the road"
//   • "PHO::<blobId>"      → a run-photo marker (member-only; skipped on public web)
// Mirrors run_tracker_map_controller._parseCheckpointType in the mobile app.

const ICON_BASE = "/images/live_run_map_markers";
const GLYPH_BASE = "/images/trail_glyphs";

// Canonical glyph library — mirrors docs/trail_markers/glyph_registry.json.
const GLYPHS: Record<string, { file: string; fixed: boolean }> = {
  check: { file: "check.mono.png", fixed: false },
  whichyway: { file: "whichyway.mono.png", fixed: false },
  fishhook: { file: "fishhook.mono.png", fixed: false },
  regroup: { file: "regroup.mono.png", fixed: false },
  hashview: { file: "hashview.mono.png", fixed: false },
  label: { file: "label.mono.png", fixed: false },
  drinkstop: { file: "drinkstop.mono.png", fixed: false },
  oninn: { file: "oninn.mono.png", fixed: false },
  caution: { file: "caution.fixed.png", fixed: true },
};

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
  /** Legacy flat-icon PNG URL (circular badge), or null. */
  iconUrl: string | null;
  /** New glyph asset URL, or null. */
  glyphUrl: string | null;
  /** Whether the glyph is fixed-colour (rendered as-is, never tinted). */
  glyphFixed: boolean;
  /** New text mark (may contain spaces = newlines), or null. */
  text: string | null;
  /** Optional display label (L= / LAB / CAU / slot "addText" marks). */
  label: string | null;
  /** Placement action (A=), e.g. "endRun". */
  action: string | null;
  /** Ends the drawn track (endRun action, or legacy On Inn). */
  isOnInn: boolean;
  isCaution: boolean;
  isPhoto: boolean;
}

const EMPTY_MARK: ParsedMark = {
  iconUrl: null,
  glyphUrl: null,
  glyphFixed: false,
  text: null,
  label: null,
  action: null,
  isOnInn: false,
  isCaution: false,
  isPhoto: false,
};

// Strip the retired mark-multiplication diagnostic suffix ("~<tapId>") still
// present on marks stored Jun–Jul 2026, and map empty → null.
function cleanLabel(raw: string): string | null {
  const cleaned = raw.replace(/~\d+$/, "").trim();
  return cleaned.length > 0 ? cleaned : null;
}

/** Resolve a track point's `type` to a renderable mark, or null for GPS points. */
export function parseMark(rawType: string | null | undefined): ParsedMark | null {
  const value = rawType?.trim();
  if (!value) return null;

  const parts = value.split("::");
  const key = parts[0].trim();

  // Trail-type declaration — metadata, not a drawable mark.
  if (key === "TRL") return null;

  // New grammar: GLY::<id> / TXT::<text> with order-independent ::L= / ::A=
  // attributes (unknown attrs ignored).
  if (key === "GLY" || key === "TXT") {
    const primary = parts.length > 1 ? parts[1] : "";
    let label: string | null = null;
    let action: string | null = null;
    for (const seg of parts.slice(2)) {
      const s = seg.trim();
      if (s.startsWith("L=")) label = cleanLabel(s.slice(2));
      else if (s.startsWith("A=")) action = s.slice(2);
    }
    const terminates = action === "endRun";
    if (key === "GLY") {
      const g = GLYPHS[primary];
      if (!g) return null; // unknown glyph id — nothing to draw
      return {
        ...EMPTY_MARK,
        glyphUrl: `${GLYPH_BASE}/${g.file}`,
        glyphFixed: g.fixed,
        label,
        action,
        isOnInn: terminates,
        isCaution: primary === "caution",
      };
    }
    if (!primary.trim()) return null;
    return { ...EMPTY_MARK, text: primary, label, action, isOnInn: terminates };
  }

  const label = cleanLabel(
    parts.length > 1 ? parts.slice(1).join("::").trim() : "",
  );

  // Legacy slot icon — the key is the icon filename itself.
  if (key.startsWith("I-")) {
    return { ...EMPTY_MARK, iconUrl: `${ICON_BASE}/${key}`, label };
  }

  if (key === "PHO") {
    // Photo markers require blob resolution + approval — not shown on public web.
    return { ...EMPTY_MARK, label, isPhoto: true };
  }

  const icon = LEGACY_ICON[key];
  if (!icon) return null;
  return {
    ...EMPTY_MARK,
    iconUrl: `${ICON_BASE}/${icon}`,
    label,
    isOnInn: key === "OIN",
    isCaution: key === "CAU",
  };
}

/** True when this point ends the drawn track (endRun action or legacy On Inn). */
export function isOnInn(rawType: string | null | undefined): boolean {
  return parseMark(rawType)?.isOnInn ?? false;
}

// Points within this span after an On-Inn are straggler queued fixes, not a
// resume — mirrors the mobile read rule.
const ON_INN_GRACE_MS = 120_000;

/**
 * A trail has exactly ONE On-Inn, at the end. An On-Inn followed by later
 * points beyond a short grace means the runner tapped it and then resumed, so
 * it is ignored completely — drawn through, no icon
 * (docs/packtrack_auto_stop_plan.md). Only an On-Inn that is effectively the
 * runner's LAST point terminates the track and renders.
 */
export function isTerminalOnInn(positions: TrackPoint[], p: TrackPoint): boolean {
  if (!isOnInn(p.type)) return false;
  const last = positions[positions.length - 1];
  return !last || last.timestampMs - p.timestampMs <= ON_INN_GRACE_MS;
}

// ── Trail types ──────────────────────────────────────────────────────────────
// A runner declares which trail they ran; it rides on the track as a
// `TRL::<value>` point. Built-ins are values 1–5; kennel-custom start at 100.
// Resolution is merge-by-value over the defaults (mirrors the Dart TrailType).

export interface TrailType {
  value: number;
  label: string;
  emoji: string;
  hidden: boolean;
  sortOrder?: number;
}

/** Undeclared / legacy tracks resolve to this lane. Permanent — never hidden. */
export const TRAIL_NORMAL_VALUE = 3;

const TRAIL_DEFAULTS: TrailType[] = [
  { value: 1, label: "Walkers", emoji: "🚶", hidden: false },
  { value: 2, label: "Short", emoji: "🐔", hidden: false },
  { value: 3, label: "Normal", emoji: "🏃", hidden: false },
  { value: 4, label: "Long", emoji: "🐂", hidden: false },
  { value: 5, label: "Ballbreaker", emoji: "💥", hidden: false },
];

function defaultsMap(): Map<number, TrailType> {
  return new Map(TRAIL_DEFAULTS.map(t => [t.value, { ...t }]));
}

/** Full value→type map after merging the kennel config over the defaults
 *  (includes hidden lanes; guarantees Normal present & not hidden). */
export function resolveTrailTypeMap(configJson: string | null | undefined): Map<number, TrailType> {
  const byValue = defaultsMap();

  if (configJson && configJson.trim()) {
    try {
      const list = JSON.parse(configJson) as Array<Record<string, unknown>>;
      for (const raw of list) {
        if (typeof raw.value !== "number") continue;
        const value = raw.value;
        const label = typeof raw.label === "string" ? raw.label : undefined;
        const emoji = typeof raw.emoji === "string" ? raw.emoji : undefined;
        const hidden =
          raw.hidden === true || raw.hidden === 1 ? true
          : raw.hidden === false || raw.hidden === 0 ? false
          : undefined;
        const sortOrder = typeof raw.sortOrder === "number" ? raw.sortOrder : undefined;

        const existing = byValue.get(value);
        if (existing) {
          byValue.set(value, {
            ...existing,
            ...(label !== undefined ? { label } : {}),
            ...(emoji !== undefined ? { emoji } : {}),
            ...(hidden !== undefined ? { hidden } : {}),
            ...(sortOrder !== undefined ? { sortOrder } : {}),
          });
        } else {
          if (!label) continue; // custom types need a label
          byValue.set(value, { value, label, emoji: emoji ?? "", hidden: hidden ?? false, sortOrder });
        }
      }
    } catch {
      return defaultsMap();
    }
  }

  const normal = byValue.get(TRAIL_NORMAL_VALUE);
  if (!normal) byValue.set(TRAIL_NORMAL_VALUE, { ...TRAIL_DEFAULTS[2] });
  else if (normal.hidden) byValue.set(TRAIL_NORMAL_VALUE, { ...normal, hidden: false });

  return byValue;
}

/** A single lane's display type, falling back to Normal for unknown values. */
export function resolveTrailTypeOne(value: number, configJson: string | null | undefined): TrailType {
  const map = resolveTrailTypeMap(configJson);
  return map.get(value) ?? map.get(TRAIL_NORMAL_VALUE)!;
}

/** The lane a runner declared (latest `TRL::` point), or Normal if none. */
export function trailValueForTrack(positions: TrackPoint[]): number {
  let latest: number | null = null;
  for (const p of positions) {
    const t = (p.type ?? "").trim();
    if (!t.startsWith("TRL::")) continue;
    const body = t.slice(5).split("::")[0].split("~")[0].trim();
    const v = parseInt(body, 10);
    if (!Number.isNaN(v)) latest = v;
  }
  return latest ?? TRAIL_NORMAL_VALUE;
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
    if (isTerminalOnInn(positions, p)) return out; // terminator — no interpolation past it
  }
  if (out.length === 0) return positions.length ? [positions[0]] : [];

  // Interpolate the partial segment to `cutoff`.
  const next = positions[idx + 1];
  const last = out[out.length - 1];
  if (next && cutoff > last.timestampMs && next.timestampMs > last.timestampMs && !isTerminalOnInn(positions, next)) {
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
export interface RunnerIdentity {
  names: Record<string, string>;
  /** Lowercased userId → profile photo URL. Only present for hashers who opted
   *  into the global directory (the public-display consent signal). */
  photos: Record<string, string>;
}

export async function fetchRunnerNames(
  publicEventId: string,
  userIds: string[],
): Promise<RunnerIdentity> {
  const empty: RunnerIdentity = { names: {}, photos: {} };
  if (!publicEventId || userIds.length === 0) return empty;
  try {
    const params = new URLSearchParams({ publicEventId, userIds: userIds.join("|") });
    const res = await fetch(`/api/runner-names?${params.toString()}`);
    if (!res.ok) return empty;
    const data = (await res.json()) as {
      runners?: { userId?: string; displayName?: string; photo?: string | null }[];
    };
    const map: RunnerIdentity = { names: {}, photos: {} };
    for (const r of data.runners ?? []) {
      if (r.userId && r.displayName) map.names[r.userId.toLowerCase()] = r.displayName;
      // Only real URLs — some hashers have app-bundled avatars ("bundle://avatar-NN")
      // that the web can't render.
      if (r.userId && r.photo && /^https?:\/\//i.test(r.photo)) {
        map.photos[r.userId.toLowerCase()] = r.photo;
      }
    }
    return map;
  } catch (err) {
    console.error("[runner-names] client fetch error:", err);
    return empty;
  }
}

/** A Hash Flash-approved public photo, keyed off PHO::<photoId> track marks. */
export interface RunPhoto {
  url: string;
  title: string | null;
  description: string | null;
  uploader: string | null;
}

/** Fetch the run's approved PUBLIC photos as photoId (lowercase) -> RunPhoto. */
export async function fetchRunPhotos(
  publicEventId: string | null,
): Promise<Record<string, RunPhoto>> {
  if (!publicEventId) return {};
  try {
    const res = await fetch(`/api/run-photos?publicEventId=${encodeURIComponent(publicEventId)}`);
    if (!res.ok) return {};
    const data = (await res.json()) as {
      photos?: {
        photoId?: string;
        BlobUrl?: string;
        Title?: string | null;
        Description?: string | null;
        uploaderDisplayName?: string | null;
      }[];
    };
    const map: Record<string, RunPhoto> = {};
    for (const p of data.photos ?? []) {
      if (p.photoId && p.BlobUrl) {
        map[p.photoId.toLowerCase()] = {
          url: p.BlobUrl,
          title: p.Title ?? null,
          description: p.Description ?? null,
          uploader: p.uploaderDisplayName ?? null,
        };
      }
    }
    return map;
  } catch (err) {
    console.error("[run-photos] client fetch error:", err);
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
