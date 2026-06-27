"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import { createPortal } from "react-dom";
import { MapContainer, TileLayer, Polyline, Marker, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";
import { Play, Pause, X, LocateFixed } from "lucide-react";
import {
  fetchPackTrack, fetchRunnerNames, parseMark, trackUpTo, sumDistanceMeters,
  haversineMeters, formatTrackTimestamp, formatDistanceLabel, filterAndInterpolate,
  MARK_DEDUPE_METERS, resolveTrailTypeMap, trailValueForTrack,
} from "@/lib/packtrack";
import type { UserTrack, TrackPoint } from "@/lib/packtrack";

// ── Constants matching the mobile app ─────────────────────────────────────────

// Playback duration scales with the trail's length, not a fixed wall-clock time:
// the zoomed-out rate is 1 s/km (a 28 km run plays in 28 s, a 5 km run in 5 s),
// and zooming in slows that down toward 8 s/km so detail is watchable. The rate
// is interpolated by zoom between ZOOM_FAST and ZOOM_SLOW.
const ZOOM_FAST = 15;
const ZOOM_SLOW = 22;
const MS_PER_KM_FAST = 1_000;   // 1 s/km — fully zoomed out (zoom ≤ 15)
const MS_PER_KM_SLOW = 8_000;   // 8 s/km — fully zoomed in (zoom ≥ 22)
const MIN_DURATION_MS = 3_000;  // floor so a very short trail doesn't flash past

const TRACK_COLORS = [
  "#ef4444", "#3b82f6", "#22c55e", "#f59e0b",
  "#a855f7", "#ec4899", "#06b6d4", "#f97316",
];

const ICON_PX = 40; // checkpoint icon size (app uses 72; scaled down for web embed)

const PIN_ICON = L.icon({
  iconUrl: "/images/map_pin_foot.png",
  iconSize: [74, 88],
  iconAnchor: [37, 88],
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function durationFor(zoom: number, trailMeters: number): number {
  const km = trailMeters / 1000;
  const t = Math.max(0, Math.min(1, (zoom - ZOOM_FAST) / (ZOOM_SLOW - ZOOM_FAST)));
  const msPerKm = MS_PER_KM_FAST + t * (MS_PER_KM_SLOW - MS_PER_KM_FAST);
  return Math.max(MIN_DURATION_MS, km * msPerKm);
}

// Icons are cached by their visual identity. Playback re-renders ~60×/s; without
// a cache a fresh L.divIcon each render makes React-Leaflet rebuild every marker's
// DOM every frame, which flickers and reads as "jumpy".
const dotIconCache = new Map<string, L.DivIcon>();
function userDotIcon(color: string, big: boolean): L.DivIcon {
  const key = `${color}|${big}`;
  const cached = dotIconCache.get(key);
  if (cached) return cached;
  const s = big ? 18 : 13;
  const icon = L.divIcon({
    html: `<div style="width:${s}px;height:${s}px;border-radius:50%;background:${color};border:2.5px solid white;box-shadow:0 1px 5px rgba(0,0,0,0.7)"></div>`,
    className: "",
    iconSize: [s, s],
    iconAnchor: [s / 2, s / 2],
  });
  dotIconCache.set(key, icon);
  return icon;
}

// Checkpoint icon — PNG from the dynamic icon collection, with an optional
// label badge floated above (yellow, or red for Caution), matching the app.
const checkpointIconCache = new Map<string, L.DivIcon>();
function checkpointIcon(iconUrl: string, label: string | null, isCaution: boolean): L.DivIcon {
  const key = `${iconUrl}|${label ?? ""}|${isCaution}`;
  const cached = checkpointIconCache.get(key);
  if (cached) return cached;
  const badge = label
    ? `<div style="position:absolute;bottom:${ICON_PX + 4}px;left:50%;transform:translateX(-50%);` +
      `background:${isCaution ? "#dc2626" : "#fef9c3"};color:${isCaution ? "#fff" : "#000"};` +
      `border:1.6px solid ${isCaution ? "#991b1b" : "#dc2626"};border-radius:6px;` +
      `padding:3px 6px;font:700 11px system-ui,sans-serif;line-height:1.25;white-space:normal;` +
      `max-width:140px;text-align:center;box-shadow:0 1px 4px rgba(0,0,0,0.4)">${label}</div>`
    : "";
  const icon = L.divIcon({
    html: `<div style="position:relative;width:${ICON_PX}px;height:${ICON_PX}px">` +
      `<img src="${iconUrl}" style="width:100%;height:100%;object-fit:contain;` +
      `filter:drop-shadow(0 1px 3px rgba(0,0,0,0.5))"/>${badge}</div>`,
    className: "",
    iconSize: [ICON_PX, ICON_PX],
    iconAnchor: [ICON_PX / 2, ICON_PX / 2],
  });
  checkpointIconCache.set(key, icon);
  return icon;
}

interface MarkEntry {
  point: TrackPoint;
  rawType: string;
  iconUrl: string;
  label: string | null;
  isCaution: boolean;
}

// Gather visible (≤ cutoff) checkpoint marks across all runners, collapsing
// same-type marks within MARK_DEDUPE_METERS so multiple runners marking the same
// physical point render once. Photos are skipped (member-only on public web).
function visibleMarks(users: UserTrack[], cutoff: number): MarkEntry[] {
  const kept: MarkEntry[] = [];
  for (const user of users) {
    for (const p of user.positions) {
      if (p.timestampMs > cutoff) break;
      const parsed = parseMark(p.type);
      if (!parsed || parsed.isPhoto || !parsed.iconUrl) continue;
      const rawType = (p.type ?? "").trim();
      const dup = kept.some(
        k => k.rawType === rawType &&
          haversineMeters(k.point.lat, k.point.lng, p.lat, p.lng) <= MARK_DEDUPE_METERS,
      );
      if (dup) continue;
      kept.push({ point: p, rawType, iconUrl: parsed.iconUrl, label: parsed.label, isCaution: parsed.isCaution });
    }
  }
  return kept;
}

// ── Sub-components (must be inside MapContainer) ───────────────────────────────

function ZoomWatcher({ zoomRef }: { zoomRef: React.MutableRefObject<number> }) {
  useMapEvents({ zoom: (e) => { zoomRef.current = e.target.getZoom(); } });
  return null;
}

function BoundsFitter({ points }: { points: [number, number][] }) {
  const map = useMap();
  const fitted = useRef(false);
  useEffect(() => {
    if (!fitted.current && points.length > 1) {
      fitted.current = true;
      map.fitBounds(L.latLngBounds(points), { padding: [40, 40] });
    }
  }, [map, points]);
  return null;
}

// Leaflet must recompute its size after the container is laid out — important for
// the full-screen instance, which mounts into a freshly-sized fixed overlay.
function InvalidateOnMount() {
  const map = useMap();
  useEffect(() => {
    const id = setTimeout(() => map.invalidateSize(), 0);
    return () => clearTimeout(id);
  }, [map]);
  return null;
}

// Follow mode (app-style): while enabled, the camera keeps the selected runner
// centred at all times — during playback, scrubbing, and after picking a
// different runner. It flies in once on engage (and again when the runner
// changes), then pans frame-by-frame with animate:false so the interpolated
// position glides smoothly. Zoom stays user-adjustable while following (pan
// only, never re-zoom). Switching follow off hands the camera back to the
// whole-track overview (BoundsFitter).
const FOLLOW_ZOOM = 16;

function FollowController({
  target, follow, selectedId,
}: {
  target: [number, number] | null;
  follow: boolean;
  selectedId: string | null;
}) {
  const map = useMap();
  const engagedRunner = useRef<string | null>(null);
  const settling = useRef(false);

  // Reset engagement when follow is switched off (the overview fit is handled
  // by BoundsFitter, which remounts whenever follow turns off).
  useEffect(() => {
    if (!follow) engagedRunner.current = null;
  }, [follow]);

  // Keep the selected runner centred whenever follow is on.
  useEffect(() => {
    if (!follow || !target || !selectedId) return;
    if (engagedRunner.current !== selectedId) {
      // (Re)engage — smooth fly-in to the runner; suppress per-frame panning
      // until the fly settles so it isn't interrupted.
      engagedRunner.current = selectedId;
      settling.current = true;
      map.flyTo(target, Math.max(map.getZoom(), FOLLOW_ZOOM), { duration: 0.6 });
      map.once("moveend", () => { settling.current = false; });
      return;
    }
    if (settling.current) return;
    map.panTo(target, { animate: false });
  }, [map, follow, target, selectedId]);

  return null;
}

// ── Map + controls view ────────────────────────────────────────────────────────
// Self-contained playback view: owns its own animation/selection state so the
// embedded and full-screen instances are independent. Fills its parent container.

interface PackTrackViewProps {
  lat: number;
  lon: number;
  users: UserTrack[];
  minTs: number;
  maxTs: number;
  hasTrack: boolean;
  /** Lowercased userId → display name. Missing ids fall back to "Runner N". */
  names: Record<string, string>;
  /** Per-kennel trail-type config JSON (from the packtrack payload), or null. */
  trailTypesConfigJson?: string | null;
}

function PackTrackView({ lat, lon, users, minTs, maxTs, hasTrack, names, trailTypesConfigJson }: PackTrackViewProps) {
  const [progress, setProgress] = useState(0);    // 0.0 → 1.0
  const [playing, setPlaying] = useState(false);
  const [pickedId, setPickedId] = useState<string | null>(null);
  const [follow, setFollow] = useState(true);

  // ── Trail-type filtering ──────────────────────────────────────────────────
  const trailTypeMap = useMemo(
    () => resolveTrailTypeMap(trailTypesConfigJson),
    [trailTypesConfigJson],
  );
  // Stable per-runner colour & lane keyed by id, so filtering never reshuffles
  // colours (track colour = runner identity).
  const colorById = useMemo(() => {
    const m = new Map<string, string>();
    users.forEach((u, i) => m.set(u.id, TRACK_COLORS[i % TRACK_COLORS.length]));
    return m;
  }, [users]);
  const laneById = useMemo(() => {
    const m = new Map<string, number>();
    for (const u of users) m.set(u.id, trailValueForTrack(u.positions));
    return m;
  }, [users]);
  // Distinct lanes present in the data, ordered by the kennel's trail order.
  const presentLanes = useMemo(() => {
    const present = new Set<number>(laneById.values());
    const order = new Map<number, number>();
    let i = 0;
    for (const t of [...trailTypeMap.values()].sort(
      (a, b) => (a.sortOrder ?? a.value) - (b.sortOrder ?? b.value),
    )) order.set(t.value, i++);
    return [...present].sort(
      (a, b) => (order.get(a) ?? 1000 + a) - (order.get(b) ?? 1000 + b),
    );
  }, [laneById, trailTypeMap]);

  // Selected lanes: all present by default; newly-appearing lanes default on,
  // user deselections persist. Mirrors the app's _refreshTrailFilter.
  const [selectedLanes, setSelectedLanes] = useState<Set<number>>(new Set());
  const knownLanesRef = useRef<Set<number>>(new Set());
  const [filterWarn, setFilterWarn] = useState(false);
  useEffect(() => {
    setSelectedLanes(prev => {
      let changed = false;
      const next = new Set(prev);
      for (const v of presentLanes) {
        if (!knownLanesRef.current.has(v)) {
          knownLanesRef.current.add(v);
          next.add(v);
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [presentLanes]);

  function toggleLane(value: number) {
    setSelectedLanes(prev => {
      if (prev.has(value)) {
        if (prev.size <= 1) {
          setFilterWarn(true);
          window.setTimeout(() => setFilterWarn(false), 2500);
          return prev;
        }
        const next = new Set(prev);
        next.delete(value);
        return next;
      }
      const next = new Set(prev);
      next.add(value);
      return next;
    });
  }

  const visibleUsers = useMemo(
    () => users.filter(u => selectedLanes.size === 0 || selectedLanes.has(laneById.get(u.id) ?? 3)),
    [users, selectedLanes, laneById],
  );

  // Refs used inside rAF loop — updated without triggering re-renders
  const progressRef = useRef(0);
  const playingRef  = useRef(false);
  const zoomRef     = useRef(15);
  const rafIdRef    = useRef<number | null>(null);
  const lastRafTs   = useRef<number | null>(null);
  const trailMetersRef = useRef(0);

  // Selected runner: the picked one if still visible under the filter, else the
  // first visible runner (never points the camera at a hidden track).
  const selectedId =
    (pickedId && visibleUsers.some(u => u.id === pickedId))
      ? pickedId
      : (visibleUsers[0]?.id ?? null);

  // Total trail length = the longest single runner's full track (OIN-terminated).
  // Drives playback duration (1 s/km zoomed out → 8 s/km zoomed in) and is stable
  // regardless of which runner is selected. Mirrored into a ref for the rAF loop.
  const trailMeters = useMemo(() => {
    let max = 0;
    for (const u of users) {
      const d = sumDistanceMeters(trackUpTo(u.positions, Infinity));
      if (d > max) max = d;
    }
    return max;
  }, [users]);
  useEffect(() => { trailMetersRef.current = trailMeters; }, [trailMeters]);

  const currentTs = minTs + (maxTs - minTs) * progress;

  // ── rAF animation loop ───────────────────────────────────────────────────────
  useEffect(() => {
    playingRef.current = playing;
    if (!playing) {
      if (rafIdRef.current !== null) cancelAnimationFrame(rafIdRef.current);
      lastRafTs.current = null;
      return;
    }
    const tick = (rafTime: number) => {
      if (!playingRef.current) return;
      if (lastRafTs.current !== null) {
        const elapsed = rafTime - lastRafTs.current;
        const duration = durationFor(zoomRef.current, trailMetersRef.current);
        const next = Math.min(progressRef.current + elapsed / duration, 1);
        progressRef.current = next;
        setProgress(next);
        if (next >= 1) {
          playingRef.current = false;
          setPlaying(false);
          lastRafTs.current = null;
          return;
        }
      }
      lastRafTs.current = rafTime;
      rafIdRef.current = requestAnimationFrame(tick);
    };
    rafIdRef.current = requestAnimationFrame(tick);
    return () => { if (rafIdRef.current !== null) cancelAnimationFrame(rafIdRef.current); };
  }, [playing]);

  function handleScrub(e: React.ChangeEvent<HTMLInputElement>) {
    const val = Number(e.target.value) / 10000;
    progressRef.current = val;
    setProgress(val);
  }

  function togglePlay() {
    if (progress >= 1) { progressRef.current = 0; setProgress(0); lastRafTs.current = null; }
    const next = !playing;
    playingRef.current = next;
    setPlaying(next);
  }

  // ── Derived render data ────────────────────────────────────────────────────────
  const allPoints: [number, number][] = hasTrack
    ? users.flatMap(u => u.positions.map(p => [p.lat, p.lng] as [number, number]))
    : [[lat, lon]];

  // Per-runner visible track (capped at On Inn), current position, colour.
  // Iterates the filtered set; colour is keyed by id so it stays stable.
  const runnerTracks = useMemo(() => visibleUsers.map((u) => {
    const pts = trackUpTo(u.positions, currentTs);
    const last = pts[pts.length - 1] ?? null;
    return { id: u.id, color: colorById.get(u.id) ?? TRACK_COLORS[0], pts, last };
  }), [visibleUsers, currentTs, colorById]);

  const marks = useMemo(() => visibleMarks(users, currentTs), [users, currentTs]);

  const selected = runnerTracks.find(r => r.id === selectedId) ?? runnerTracks[0] ?? null;
  const followTarget: [number, number] | null =
    selected?.last ? [selected.last.lat, selected.last.lng] : null;

  const distanceMeters = selected ? sumDistanceMeters(selected.pts) : 0;
  const distanceLabel = selected ? formatDistanceLabel(distanceMeters) : "";

  const selectedIdx = selected ? users.findIndex(u => u.id === selected.id) : -1;

  const runnerName = (id: string) =>
    names[id.toLowerCase()] ?? `Runner ${users.findIndex(u => u.id === id) + 1}`;
  const runnerEmoji = (id: string) =>
    (trailTypeMap.get(laneById.get(id) ?? 3)?.emoji) ?? "";

  return (
    <>
      <MapContainer
        center={[lat, lon]}
        zoom={15}
        style={{ height: "100%", width: "100%" }}
        zoomControl
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <InvalidateOnMount />
        <ZoomWatcher zoomRef={zoomRef} />
        {/* Overview fit owns the camera only when not actively following. */}
        {(!hasTrack || !follow) && <BoundsFitter points={allPoints} />}

        {hasTrack ? (
          <>
            <FollowController
              target={followTarget}
              follow={follow}
              selectedId={selectedId}
            />

            {/* Runner trails */}
            {runnerTracks.map(r => {
              const dimmed = selectedId != null && r.id !== selectedId;
              return r.pts.length > 1 ? (
                <Polyline
                  key={`${r.id}-trail`}
                  positions={r.pts.map(p => [p.lat, p.lng] as [number, number])}
                  pathOptions={{
                    color: r.color,
                    weight: dimmed ? 3 : 4,
                    opacity: dimmed ? 0.4 : 0.9,
                  }}
                />
              ) : null;
            })}

            {/* Checkpoint marks — dynamic icon collection */}
            {marks.map((m, i) => (
              <Marker
                key={`mark-${i}-${m.rawType}`}
                position={[m.point.lat, m.point.lng]}
                icon={checkpointIcon(m.iconUrl, m.label, m.isCaution)}
              />
            ))}

            {/* Current position of each runner */}
            {runnerTracks.map(r => r.last ? (
              <Marker
                key={`${r.id}-dot`}
                position={[r.last.lat, r.last.lng]}
                icon={userDotIcon(r.color, r.id === selectedId)}
                zIndexOffset={r.id === selectedId ? 1000 : 0}
              />
            ) : null)}
          </>
        ) : (
          <Marker position={[lat, lon]} icon={PIN_ICON} />
        )}
      </MapContainer>

      {/* PackTrack control panel */}
      {hasTrack && (
        <div className="absolute bottom-2 left-2 right-2 z-[1000] rounded-xl px-3 pt-2 pb-2.5"
          style={{ background: "rgba(0,0,0,0.65)" }}
        >
          {/* Runner selector */}
          {visibleUsers.length > 1 && (
            <div className="flex items-center justify-center gap-2 flex-wrap pb-1.5">
              {visibleUsers.map((u) => {
                const active = u.id === selectedId;
                const emoji = runnerEmoji(u.id);
                return (
                  <button
                    key={u.id}
                    onClick={() => setPickedId(u.id)}
                    className="flex items-center gap-1.5 rounded-full pl-1 pr-2.5 py-1 transition-colors"
                    style={{ background: active ? "rgba(255,255,255,0.16)" : "transparent" }}
                    aria-pressed={active}
                  >
                    <span
                      className="w-3.5 h-3.5 rounded-full border"
                      style={{
                        backgroundColor: colorById.get(u.id) ?? TRACK_COLORS[0],
                        borderColor: active ? "#fff" : "rgba(255,255,255,0.4)",
                        borderWidth: active ? 2 : 1,
                      }}
                    />
                    <span className="text-xs font-semibold max-w-[10rem] truncate" style={{ color: active ? "#fff" : "rgba(255,255,255,0.6)" }}>
                      {emoji ? `${emoji} ` : ""}{runnerName(u.id)}
                    </span>
                  </button>
                );
              })}
            </div>
          )}

          {/* Trail-type filter chips — present lanes only; can't clear all */}
          {presentLanes.length > 1 && (
            <div className="flex items-center justify-center gap-1.5 flex-wrap pb-1.5">
              {presentLanes.map((v) => {
                const t = trailTypeMap.get(v);
                const on = selectedLanes.has(v);
                return (
                  <button
                    key={`lane-${v}`}
                    onClick={() => toggleLane(v)}
                    aria-pressed={on}
                    className="flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold transition-colors border"
                    style={{
                      background: on ? "#1d4ed8" : "rgba(255,255,255,0.08)",
                      borderColor: on ? "#fff" : "rgba(255,255,255,0.2)",
                      color: on ? "#fff" : "rgba(255,255,255,0.6)",
                    }}
                  >
                    {t?.emoji ? <span>{t.emoji}</span> : null}
                    <span>{t?.label ?? `Trail ${v}`}</span>
                  </button>
                );
              })}
            </div>
          )}
          {filterWarn && (
            <div className="text-center text-amber-300 text-xs pb-1.5">
              Please select at least one trail type
            </div>
          )}

          {/* Selected runner heading */}
          {selected && (
            <div className="text-center text-white font-semibold text-base leading-tight truncate" suppressHydrationWarning>
              {names[selected.id.toLowerCase()] ?? (users.length > 1 ? `Runner ${selectedIdx + 1}` : "Track")}
            </div>
          )}

          {/* Timestamp + distance */}
          <div className="text-center text-white/90 text-sm tabular-nums leading-snug" suppressHydrationWarning>
            {formatTrackTimestamp(currentTs)}
          </div>
          {distanceLabel && (
            <div className="text-center text-white/70 text-sm tabular-nums leading-snug" suppressHydrationWarning>
              {distanceLabel}
            </div>
          )}

          {/* Play / scrubber */}
          <div className="flex items-center gap-3 pt-1">
            <button
              onClick={togglePlay}
              className="shrink-0 flex items-center justify-center w-9 h-9 rounded-full bg-white/15 hover:bg-white/25 transition-colors border border-white/20"
              aria-label={playing ? "Pause" : "Play"}
            >
              {playing ? <Pause className="h-4 w-4 text-white" /> : <Play className="h-4 w-4 text-white" />}
            </button>
            <input
              type="range"
              min={0}
              max={10000}
              step={1}
              value={Math.round(progress * 10000)}
              onChange={handleScrub}
              className="flex-1 h-1.5 cursor-pointer"
              style={{ accentColor: "#3b82f6" }}
            />
            <button
              onClick={() => setFollow(f => !f)}
              aria-pressed={follow}
              title={follow ? "Following selected runner" : "Follow selected runner"}
              className="shrink-0 flex items-center justify-center w-8 h-8 rounded-full border transition-colors"
              style={{
                backgroundColor: follow ? "#3b82f6" : "rgba(255,255,255,0.12)",
                borderColor: follow ? "#3b82f6" : "rgba(255,255,255,0.2)",
              }}
            >
              <LocateFixed className="h-4 w-4 text-white" />
            </button>
            <span className="text-[10px] font-semibold tracking-wider text-white/40 uppercase shrink-0">PackTrack</span>
          </div>
        </div>
      )}
    </>
  );
}

// ── Full-screen overlay ─────────────────────────────────────────────────────────

interface PackTrackFullscreenProps extends PackTrackViewProps {
  onClose: () => void;
}

function PackTrackFullscreen({ onClose, ...viewProps }: PackTrackFullscreenProps) {
  useEffect(() => {
    function onKey(e: KeyboardEvent) { if (e.key === "Escape") onClose(); }
    window.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [onClose]);

  return createPortal(
    <div className="fixed inset-0 z-[2000] bg-black">
      <div className="relative h-full w-full">
        <PackTrackView {...viewProps} />
        <button
          onClick={onClose}
          aria-label="Close PackTrack"
          className="absolute top-3 right-3 z-[1001] flex items-center justify-center w-10 h-10 rounded-full bg-black/55 hover:bg-black/75 transition-colors border border-white/25 backdrop-blur-sm"
        >
          <X className="h-5 w-5 text-white" />
        </button>
      </div>
    </div>,
    document.body
  );
}

// ── Main component ─────────────────────────────────────────────────────────────

interface PackTrackMapProps {
  lat: number;
  lon: number;
  eventId: string;
  /** Run's public UUID (HC.Event.PublicEventId) — used to resolve runner names. */
  publicEventId?: string;
  height?: number;
  /** Notified once the track has loaded — `true` when playback data exists. */
  onTrackLoaded?: (hasTrack: boolean) => void;
  /** When `true`, render the full-screen playback overlay. */
  open?: boolean;
  /** Called when the full-screen overlay requests to close. */
  onClose?: () => void;
  /**
   * When `true`, render as a standalone full-viewport page (no embedded card,
   * no portal overlay) — used by the dedicated `/[slug]/[runNumber]/packtrack`
   * route. The close button (top-left) calls `onClose`.
   */
  fullPage?: boolean;
}

export default function PackTrackMap({
  lat, lon, eventId, publicEventId, height = 240, onTrackLoaded, open = false, onClose, fullPage = false,
}: PackTrackMapProps) {
  const [users, setUsers] = useState<UserTrack[]>([]);
  const [minTs, setMinTs] = useState(0);
  const [maxTs, setMaxTs] = useState(0);
  const [loading, setLoading] = useState(true);
  const [hasTrack, setHasTrack] = useState(false);
  const [names, setNames] = useState<Record<string, string>>({});
  const [trailCfg, setTrailCfg] = useState<string | null>(null);

  const onTrackLoadedRef = useRef(onTrackLoaded);
  useEffect(() => { onTrackLoadedRef.current = onTrackLoaded; });

  useEffect(() => {
    fetchPackTrack(eventId).then(data => {
      // Clean each runner's track (drop GPS noise, interpolate gaps) and drop
      // runners left with nothing so they don't show as empty selector chips.
      const live = (data?.users ?? [])
        .map(u => ({ ...u, positions: filterAndInterpolate(u.positions) }))
        .filter(u => u.positions.length > 0);

      if (live.length === 0) {
        setLoading(false);
        onTrackLoadedRef.current?.(false);
        return;
      }
      const allTs = live.flatMap(u => u.positions.map(p => p.timestampMs));
      const mn = Math.min(...allTs);
      const mx = Math.max(...allTs);
      setUsers(live);
      setMinTs(mn);
      setMaxTs(mx);
      setHasTrack(true);
      setLoading(false);
      if (data?.trailTypesConfigJson) setTrailCfg(data.trailTypesConfigJson);
      onTrackLoadedRef.current?.(true);

      // Resolve runner display names (optional — failures fall back to "Runner N").
      if (publicEventId) {
        fetchRunnerNames(publicEventId, live.map(u => u.id)).then(setNames);
      }
    });
  }, [eventId, publicEventId]);

  const viewProps: PackTrackViewProps = { lat, lon, users, minTs, maxTs, hasTrack, names, trailTypesConfigJson: trailCfg };

  // Standalone full-viewport page (dedicated PackTrack route). Fills the screen
  // with the playback view; the close button hands control back to the caller.
  if (fullPage) {
    return (
      <div className="fixed inset-0 bg-black">
        <PackTrackView {...viewProps} />
        {loading && (
          <div className="absolute inset-0 z-[1001] flex items-center justify-center bg-black/30 backdrop-blur-sm">
            <span className="text-sm text-white/60">Loading track…</span>
          </div>
        )}
        {onClose && (
          <button
            onClick={onClose}
            aria-label="Close PackTrack"
            className="absolute top-3 left-3 z-[1001] flex items-center justify-center w-10 h-10 rounded-full bg-black/55 hover:bg-black/75 transition-colors border border-white/25 backdrop-blur-sm"
          >
            <X className="h-5 w-5 text-white" />
          </button>
        )}
      </div>
    );
  }

  return (
    <>
      <div className="relative w-full overflow-hidden rounded-xl" style={{ height }}>
        <PackTrackView {...viewProps} />
        {loading && (
          <div className="absolute inset-0 z-[1001] flex items-center justify-center bg-black/30 backdrop-blur-sm rounded-xl">
            <span className="text-sm text-white/60">Loading track…</span>
          </div>
        )}
      </div>

      {open && hasTrack && onClose && (
        <PackTrackFullscreen {...viewProps} onClose={onClose} />
      )}
    </>
  );
}
