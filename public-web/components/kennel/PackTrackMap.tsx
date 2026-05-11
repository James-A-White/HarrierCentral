"use client";

import { useState, useEffect, useRef, Fragment } from "react";
import { MapContainer, TileLayer, Polyline, Marker, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";
import { Play, Pause } from "lucide-react";
import { fetchPackTrack } from "@/lib/packtrack";
import type { UserTrack, TrackPoint } from "@/lib/packtrack";

// ── Constants matching the mobile app ─────────────────────────────────────────

const ZOOM_FAST = 15;
const ZOOM_SLOW = 22;
const DURATION_FAST_MS = 10_000;   // real ms for full playback at zoom ≤ 15
const DURATION_SLOW_MS = 480_000;  // real ms for full playback at zoom ≥ 22

const TRACK_COLORS = [
  "#ef4444", "#3b82f6", "#22c55e", "#f59e0b",
  "#a855f7", "#ec4899", "#06b6d4", "#f97316",
];

const PIN_ICON = L.icon({
  iconUrl: "/images/map_pin_foot.png",
  iconSize: [74, 88],
  iconAnchor: [37, 88],
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function durationForZoom(zoom: number): number {
  const t = Math.max(0, Math.min(1, (zoom - ZOOM_FAST) / (ZOOM_SLOW - ZOOM_FAST)));
  return DURATION_FAST_MS + t * (DURATION_SLOW_MS - DURATION_FAST_MS);
}

function formatTime(epochMs: number): string {
  return new Date(epochMs).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
}

function userDotIcon(color: string): L.DivIcon {
  return L.divIcon({
    html: `<div style="width:14px;height:14px;border-radius:50%;background:${color};border:2.5px solid white;box-shadow:0 1px 5px rgba(0,0,0,0.7)"></div>`,
    className: "",
    iconSize: [14, 14],
    iconAnchor: [7, 7],
  });
}

function trailMarkerIcon(label: string): L.DivIcon {
  return L.divIcon({
    html: `<div style="background:rgba(10,15,30,0.88);color:#eab308;font-family:system-ui,sans-serif;font-weight:700;font-size:9px;padding:3px 6px;border-radius:4px;border:1px solid rgba(234,179,8,0.7);white-space:nowrap;line-height:1.3;max-width:80px;overflow:hidden;text-overflow:ellipsis">${label}</div>`,
    className: "",
    iconAnchor: [0, 0],
  });
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

interface TracksLayerProps {
  users: UserTrack[];
  currentTs: number;
  zoomRef: React.MutableRefObject<number>;
  allPoints: [number, number][];
}

function TracksLayer({ users, currentTs, zoomRef, allPoints }: TracksLayerProps) {
  return (
    <>
      <BoundsFitter points={allPoints} />
      <ZoomWatcher zoomRef={zoomRef} />
      {users.map((user, idx) => {
        const color = TRACK_COLORS[idx % TRACK_COLORS.length];
        const visible = user.positions.filter(p => p.timestampMs <= currentTs);
        const trail = visible.filter(p => !p.type);
        const markers = visible.filter(p => !!p.type);
        const last = trail[trail.length - 1];

        return (
          <Fragment key={user.id}>
            {trail.length > 1 && (
              <Polyline
                positions={trail.map(p => [p.lat, p.lng] as [number, number])}
                color={color}
                weight={3}
                opacity={0.85}
              />
            )}
            {markers.map((p: TrackPoint, i: number) => {
              const [key, suffix] = (p.type ?? "").split("::");
              return (
                <Marker
                  key={`${user.id}-tm-${i}`}
                  position={[p.lat, p.lng]}
                  icon={trailMarkerIcon(suffix ?? key)}
                />
              );
            })}
            {last && (
              <Marker
                key={`${user.id}-dot`}
                position={[last.lat, last.lng]}
                icon={userDotIcon(color)}
              />
            )}
          </Fragment>
        );
      })}
    </>
  );
}

// ── Main component ─────────────────────────────────────────────────────────────

interface PackTrackMapProps {
  lat: number;
  lon: number;
  eventId: string;
  height?: number;
}

export default function PackTrackMap({ lat, lon, eventId, height = 240 }: PackTrackMapProps) {
  const [users, setUsers] = useState<UserTrack[]>([]);
  const [minTs, setMinTs] = useState(0);
  const [maxTs, setMaxTs] = useState(0);
  const [progress, setProgress] = useState(0);    // 0.0 → 1.0
  const [playing, setPlaying] = useState(false);
  const [loading, setLoading] = useState(true);
  const [hasTrack, setHasTrack] = useState(false);

  // Refs used inside rAF loop — updated without triggering re-renders
  const progressRef = useRef(0);
  const playingRef  = useRef(false);
  const zoomRef     = useRef(15);
  const minTsRef    = useRef(0);
  const maxTsRef    = useRef(0);
  const rafIdRef    = useRef<number | null>(null);
  const lastRafTs   = useRef<number | null>(null);

  // Derived current timestamp
  const currentTs = minTs + (maxTs - minTs) * progress;

  // ── Fetch track data ─────────────────────────────────────────────────────────
  useEffect(() => {
    fetchPackTrack(eventId).then(data => {
      if (!data || data.users.length === 0 || data.users.every(u => u.positions.length === 0)) {
        setLoading(false);
        return;
      }

      const allTs = data.users.flatMap(u => u.positions.map(p => p.timestampMs));
      const mn = Math.min(...allTs);
      const mx = Math.max(...allTs);

      setUsers(data.users);
      setMinTs(mn);
      setMaxTs(mx);
      minTsRef.current = mn;
      maxTsRef.current = mx;
      setHasTrack(true);
      setLoading(false);
    });
  }, [eventId]);

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
        const duration = durationForZoom(zoomRef.current);
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
    return () => {
      if (rafIdRef.current !== null) cancelAnimationFrame(rafIdRef.current);
    };
  }, [playing]);

  // ── Scrubber drag ────────────────────────────────────────────────────────────
  function handleScrub(e: React.ChangeEvent<HTMLInputElement>) {
    const val = Number(e.target.value) / 10000;
    progressRef.current = val;
    setProgress(val);
  }

  // ── Play / pause ─────────────────────────────────────────────────────────────
  function togglePlay() {
    if (progress >= 1) {
      // Restart from beginning
      progressRef.current = 0;
      setProgress(0);
      lastRafTs.current = null;
    }
    const next = !playing;
    playingRef.current = next;
    setPlaying(next);
  }

  // ── Bounds points (all positions, for BoundsFitter) ──────────────────────────
  const allPoints: [number, number][] = hasTrack
    ? users.flatMap(u => u.positions.map(p => [p.lat, p.lng] as [number, number]))
    : [[lat, lon]];

  // ── Render ────────────────────────────────────────────────────────────────────
  return (
    <div className="relative w-full overflow-hidden rounded-xl" style={{ height }}>
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

        {hasTrack ? (
          <TracksLayer
            users={users}
            currentTs={currentTs}
            zoomRef={zoomRef}
            allPoints={allPoints}
          />
        ) : (
          <>
            <BoundsFitter points={allPoints} />
            <ZoomWatcher zoomRef={zoomRef} />
            <Marker position={[lat, lon]} icon={PIN_ICON} />
          </>
        )}
      </MapContainer>

      {/* PackTrack controls overlay */}
      {hasTrack && (
        <div
          className="absolute bottom-0 left-0 right-0 z-[1000] px-3 py-2 flex flex-col gap-1.5"
          style={{ background: "linear-gradient(to top, rgba(0,0,0,0.72) 0%, rgba(0,0,0,0.0) 100%)" }}
        >
          {/* Scrubber */}
          <input
            type="range"
            min={0}
            max={10000}
            step={1}
            value={Math.round(progress * 10000)}
            onChange={handleScrub}
            className="w-full h-1.5 cursor-pointer accent-yellow-400"
            style={{ accentColor: "#eab308" }}
          />

          {/* Controls row */}
          <div className="flex items-center gap-3">
            {/* Play / Pause */}
            <button
              onClick={togglePlay}
              className="shrink-0 flex items-center justify-center w-8 h-8 rounded-full bg-white/15 hover:bg-white/25 transition-colors border border-white/20"
              aria-label={playing ? "Pause" : "Play"}
            >
              {playing
                ? <Pause  className="h-4 w-4 text-white" />
                : <Play   className="h-4 w-4 text-white" />
              }
            </button>

            {/* Current time */}
            <span className="text-sm font-semibold tabular-nums text-white/90" suppressHydrationWarning>
              {formatTime(currentTs)}
            </span>

            <span className="text-white/40 text-xs">–</span>

            <span className="text-sm text-white/50 tabular-nums" suppressHydrationWarning>
              {formatTime(maxTs)}
            </span>

            {/* Spacer */}
            <div className="flex-1" />

            {/* User colour dots legend */}
            <div className="flex items-center gap-1.5">
              {users.map((u, i) => (
                <div
                  key={u.id}
                  className="w-2.5 h-2.5 rounded-full border border-white/40"
                  style={{ backgroundColor: TRACK_COLORS[i % TRACK_COLORS.length] }}
                />
              ))}
            </div>

            {/* PackTrack label */}
            <span className="text-[10px] font-semibold tracking-wider text-white/40 uppercase">PackTrack</span>
          </div>
        </div>
      )}

      {/* Loading shimmer */}
      {loading && (
        <div className="absolute inset-0 z-[1001] flex items-center justify-center bg-black/30 backdrop-blur-sm rounded-xl">
          <span className="text-sm text-white/60">Loading track…</span>
        </div>
      )}
    </div>
  );
}
