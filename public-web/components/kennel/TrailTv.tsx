"use client";

/**
 * Trail-TV — the big-screen "event wall" (/[slug]/[runNumber]/trail-tv).
 *
 * Layout: live map (top-left), 10-second loop replay (bottom-left), a
 * continuously scrolling carousel of approved photos (right), stats ticker
 * (bottom) and a follow-along QR badge. New approved photos take over the
 * full screen for ~12s before joining the carousel (Hash Flash / GM / VGM
 * photos auto-approve server-side, so trail-to-screen is one poll cycle).
 *
 * Modes:
 *  - live   — polls tracks every 12s and photos every 20s; mark callouts.
 *  - replay — one fetch; the main panel replays the whole run paced at
 *             1 minute per km of the first finisher's trail, with photos
 *             taking over as the replay clock passes their capture time.
 * Auto-selects live within 24h of the run start, replay after — and flips
 * live → replay once tracks exist but nobody has reported for 30 min,
 * unless the mode was pinned by ?mode= or the on-screen toggle.
 */

import { Fragment, useState, useEffect, useRef, useMemo, useCallback } from "react";
import {
  MapContainer, TileLayer, Polyline, CircleMarker, Marker, Pane, Tooltip, useMap,
} from "react-leaflet";
import QRCode from "react-qr-code";
import {
  MARK_PANE, MARK_PANE_Z, checkpointIcon, photoPinIcon, visibleMarks,
} from "./trackMarks";
import {
  fetchPackTrack, fetchRunnerNames, fetchRunPhotos, parseMark, isTerminalOnInn,
  trackUpTo, filterAndInterpolate, formatDistanceLabel, haversineMeters, photoSrc,
} from "@/lib/packtrack";
import type { UserTrack, TrackPoint, RunPhoto } from "@/lib/packtrack";

const TRACK_COLORS = [
  "#ef4444", "#3b82f6", "#22c55e", "#f59e0b",
  "#a855f7", "#ec4899", "#06b6d4", "#f97316",
];

const LIVE_POLL_MS = 12_000;
const PHOTO_POLL_MS = 20_000;
const LOOP_DURATION_MS = 10_000;
const LOOP_HOLD_MS = 1_500;
// Replay pace, in SECONDS of wall time per km of trail. The default is James's
// call (2026-08-30); the wall itself is adjustable with the speed slider, whose
// setting is remembered per screen in localStorage — an unattended wall keeps
// whatever the venue set it to. The panel sublabel is generated from the live
// value, so it can never advertise a pace the wall is not running at.
const DEFAULT_PACE_S_PER_KM = 10;
const PACE_MIN_S = 5;
const PACE_MAX_S = 180; // slowest setting: 3 min of wall time per km of trail
const PACE_STEP_S = 5;
const PACE_STORAGE_KEY = "hc-trailtv-pace-s-per-km";
const REPLAY_HOLD_MS = 6_000;
// The replay NEVER stops for a photo (James, 2026-08-30 — a pause was tried and
// rejected). Instead each photo holds the panel for at least MIN_PHOTO_MS, and
// photos reached while one is showing wait their turn in a queue. A cluster shot
// at one spot therefore plays out over the following seconds while the pack
// keeps moving.
const MIN_PHOTO_MS = 5_000;
/** Most out-of-run photos the end-of-cycle hold will wait for. */
const TRAILING_PHOTOS_MAX = 6;
const TAKEOVER_LIVE_MS = 10_000;  // fresh-from-trail photo, live mode
const PRELOAD_AHEAD = 4;          // photos warmed into cache ahead of the takeover
const TAKEOVER_OUT_MS = 450;       // zoom-back-out exit animation (matches .closing CSS)
const CALLOUT_MS = 6_000;
const ACTIVE_WINDOW_MS = 10 * 60_000; // "on trail" = a point in the last 10 min
const REPLAY_IDLE_MS = 30 * 60_000; // live → replay once no runner has reported for 30 min
// Front-runner cam zoom is DERIVED PER RUN: it fits the ground this run's leader
// typically covered in FOLLOW_WINDOW_MS, so a sprawling trail gets a wider view
// than a tight one — but the value is CONSTANT for the whole replay.
//
// It was recomputed continuously in 0.21.36 (zoom in at a check, out on a fast
// leg) and that is what made the cam "flash black every few seconds": a drifting
// fractional zoom keeps crossing a rounding boundary, Leaflet swaps tile levels,
// and it prunes the outgoing level before the incoming one covers the panel.
// Measured: levels 16-15-16-17-16 in 100 seconds, one sample with 8 tiles over a
// panel needing ~18. Widening the hysteresis was not enough at 10 s/km, where
// the ground covered changes nine times faster in wall time.
// FOLLOW_ZOOM is the first-fix fallback before any track data has arrived.
const FOLLOW_ZOOM = 16;
const FOLLOW_ZOOM_MIN = 14;
const FOLLOW_ZOOM_MAX = 17;
const FOLLOW_WINDOW_MS = 3 * 60_000; // of RUN time behind the leader to keep in frame
const FOLLOW_SPREAD_PERCENTILE = 0.75; // typical, not worst-case, ground covered
const FOLLOW_SPAN_PADDING = 1.25;    // breathing room around that ground
const FOLLOW_MIN_SPAN_M = 60;        // don't zoom to the rooftops when they stop
const FOLLOW_ZOOM_TAU = 10;          // seconds — zoom smoothing time constant
// Only WHOLE zoom levels are ever applied, and only once the smoothed target is
// this far past the current one. A fractional zoom that drifts across a rounding
// boundary makes Leaflet swap tile levels, and it prunes the outgoing level
// before the incoming one covers the panel — the cam "flashing black every few
// seconds" (James, 2026-08-30). Measured before the fix: level 16-15-16-17-16 in
// 100 seconds, with one sample showing 8 tiles over a panel that needs ~18.
const FOLLOW_ZOOM_HYSTERESIS = 0.7;
// Camera spring stiffness. A critically damped spring lags its target by 2/omega
// SECONDS of travel, so at a fixed omega the runner sits further off-centre the
// faster the replay runs — the original "running off the screen because of the
// smoothing". Omega therefore scales with the pace, keeping the lag roughly
// constant in METRES from 60 s/km down to 5 s/km.
const FOLLOW_SPRING_OMEGA = 3;   // rad/s at the reference pace
const FOLLOW_SPRING_REF_PACE_S = 90;
const FOLLOW_SPRING_OMEGA_MAX = 25;
const LEAD_HYSTERESIS_METERS = 15; // new leader must be this far ahead to steal the cam
// Cam marks scale with the wall like the overview ones, but bigger and still
// labelled — the cam is where a mark is actually meant to be read.
const CAM_MARK_FRACTION = 0.035;
const CAM_MARK_MIN = 22;
const CAM_MARK_MAX = 56;
// The replay panel shows the newest photo large with the previous few beneath;
// the old single scrolling column clipped whatever ran past the panel bottom.
const REVEAL_STRIP_MAX = 4;
// Numbered pin dropped where each photo was taken. Scaled like the trail marks
// so it reads the same on a laptop preview and a 4K wall.
const PIN_FRACTION = 0.017;
const PIN_MIN = 15;
const PIN_MAX = 30;
// Trail-mark tiles on the whole-run panels are sized from the viewport rather
// than fixed: a 36px tile that looked fine on a 4K wall buried the track on a
// laptop preview (James, 2026-08-30 — "the trail symbols hide the track on the
// bottom view"). Small, unlabelled and slightly translucent there; the
// front-runner cam is zoomed in, so it keeps full-size labelled marks.
const OVERVIEW_MARK_FRACTION = 0.02; // of the map column's width
const OVERVIEW_MARK_MIN = 12;
const OVERVIEW_MARK_MAX = 34;
const OVERVIEW_MARK_OPACITY = 0.8;
const MAP_COLUMN_FRACTION = 0.55;    // matches grid-template-columns below

interface TrailTvProps {
  slug: string;
  runNumber: string;
  lat: number;
  lon: number;
  eventId: string;
  publicEventId: string;
  eventName: string;
  kennelName: string;
  /** Run start instant (EventStartDatetimeGmt), epoch ms; null if unknown. */
  eventStartMs: number | null;
  initialMode: "live" | "replay" | null;
}

interface PreparedTrack {
  id: string;
  color: string;
  positions: TrackPoint[]; // filtered + interpolated
  /** Cumulative meters at each position index (for front-runner lookup). */
  cumDist: number[];
  distanceMeters: number;
  finishTs: number | null; // terminal On-Inn timestamp
  lastTs: number;
}

interface PhotoEntry extends RunPhoto {
  photoId: string;
  /** Capture time from the PHO:: track mark, when one exists. */
  markTs: number | null;
  /** Where it was taken, from the same mark. Null when the photo has no mark. */
  lat: number | null;
  lng: number | null;
  /** 1-based position along the trail, in capture order. Null when unplaced. */
  num: number | null;
  /**
   * True when the photo has no place inside the run: taken before the pack set
   * off, after they were in, or with no known time at all. Held back to the end
   * of the replay rather than shown before the trail has started.
   */
  outsideRun: boolean;
}

/** Where a photo was taken, harvested from the PHO:: marks in the track payload. */
interface PhotoMark {
  ts: number;
  lat: number;
  lng: number;
}

interface Callout {
  key: number;
  text: string;
  big: boolean;
}

// ── Track prep ─────────────────────────────────────────────────────────────────

function prepareTracks(users: UserTrack[]): PreparedTrack[] {
  const out: PreparedTrack[] = [];
  users.forEach((u, i) => {
    const gps = u.positions.filter((p) => !p.type);
    const filtered = filterAndInterpolate(gps);
    if (filtered.length < 2) return;
    const oin = u.positions.find(
      (p) => p.type && parseMark(p.type)?.isOnInn && isTerminalOnInn(u.positions, p),
    );
    const upTo = oin ? trackUpTo(filtered, oin.timestampMs) : filtered;
    if (upTo.length < 2) return;
    const cumDist: number[] = [0];
    for (let k = 1; k < upTo.length; k++) {
      cumDist.push(
        cumDist[k - 1] +
          haversineMeters(upTo[k - 1].lat, upTo[k - 1].lng, upTo[k].lat, upTo[k].lng),
      );
    }
    out.push({
      id: u.id.toLowerCase(),
      color: TRACK_COLORS[i % TRACK_COLORS.length],
      positions: upTo,
      cumDist,
      distanceMeters: cumDist[cumDist.length - 1],
      finishTs: oin ? oin.timestampMs : null,
      lastTs: upTo[upTo.length - 1].timestampMs,
    });
  });
  return out;
}

function boundsOf(tracks: PreparedTrack[], fallback: [number, number]): [number, number][] {
  const pts: [number, number][] = [];
  for (const t of tracks) for (const p of t.positions) pts.push([p.lat, p.lng]);
  return pts.length > 0 ? pts : [fallback];
}

/** Fit the map to the supplied points whenever their bounding box changes. */
function AutoFit({ points }: { points: [number, number][] }) {
  const map = useMap();
  const key = useMemo(() => {
    let minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (const [la, ln] of points) {
      if (la < minLat) minLat = la;
      if (la > maxLat) maxLat = la;
      if (ln < minLng) minLng = ln;
      if (ln > maxLng) maxLng = ln;
    }
    return `${minLat.toFixed(4)}|${maxLat.toFixed(4)}|${minLng.toFixed(4)}|${maxLng.toFixed(4)}`;
  }, [points]);
  useEffect(() => {
    if (points.length === 0) return;
    // The panel's grid size settles after mount — without invalidateSize the
    // map keeps its first-measured (wrong) viewport and renders undersized.
    map.invalidateSize();
    map.fitBounds(points, { padding: [30, 30] });
    const t = setTimeout(() => {
      map.invalidateSize();
      map.fitBounds(points, { padding: [30, 30] });
    }, 400);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, map]);
  return null;
}

/**
 * Keeps the map centered on a moving target at a fixed zoom (follow-cam).
 * The replay clock steps at 5Hz; a setView({animate:true}) per tick restarts
 * Leaflet's pan animation each time, so the camera visibly stutters. Instead
 * a critically-damped spring (position + velocity per axis) chases the latest
 * target inside an rAF loop: the camera accelerates smoothly into motion and
 * decelerates into a stop — 5Hz stepping, lead swaps, and takeover pauses all
 * become eased glides. The map is moved with panBy({animate:false}), a raw
 * CSS pan — per-frame setView goes through _resetView, which churns the tile
 * queue and leaves blank tiles behind a moving camera.
 */
function FollowCenter({
  center, spreadMeters, omega,
}: {
  center: [number, number] | null;
  /** How far the leader has ranged from their current position over the recent
   *  window — the ground the camera has to keep in frame. null = hold zoom. */
  spreadMeters: number | null;
  /** Spring stiffness, scaled to the replay pace by the caller. */
  omega: number;
}) {
  const map = useMap();
  const target = useRef<[number, number] | null>(null);
  const omegaRef = useRef(omega);
  useEffect(() => { omegaRef.current = omega; }, [omega]);
  const spread = useRef<number | null>(null);
  const camZoom = useRef<number | null>(null);
  const cam = useRef<{ lat: number; lng: number; vLat: number; vLng: number } | null>(null);
  useEffect(() => {
    target.current = center;
  }, [center]);
  useEffect(() => {
    spread.current = spreadMeters;
  }, [spreadMeters]);

  // Ground the frame must cover -> Leaflet zoom, at this latitude and panel size.
  const zoomFor = useCallback((metres: number, lat: number): number => {
    const size = map.getSize();
    const halfPx = Math.max(80, Math.min(size.x, size.y) / 2);
    const mpp = Math.max(FOLLOW_MIN_SPAN_M, metres * FOLLOW_SPAN_PADDING) / halfPx;
    const raw = Math.log2((156543.03392 * Math.cos((lat * Math.PI) / 180)) / mpp);
    return Math.max(FOLLOW_ZOOM_MIN, Math.min(FOLLOW_ZOOM_MAX, raw));
  }, [map]);
  useEffect(() => {
    map.invalidateSize();
    let raf = 0;
    let last = performance.now();
    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);
      const dt = Math.min(100, now - last) / 1000;
      last = now;
      const tgt = target.current;
      if (!tgt) return;
      if (!cam.current) {
        // First fix: jump straight there rather than glide in from afar.
        cam.current = { lat: tgt[0], lng: tgt[1], vLat: 0, vLng: 0 };
        camZoom.current =
          spread.current != null ? zoomFor(spread.current, tgt[0]) : FOLLOW_ZOOM;
        map.setView(tgt, Math.round(camZoom.current), { animate: false });
        return;
      }
      const c = cam.current;
      const w = omegaRef.current;
      // accel = ω²·(target − pos) − 2ω·vel (critical damping — no overshoot)
      c.vLat += ((tgt[0] - c.lat) * w * w - 2 * w * c.vLat) * dt;
      c.vLng += ((tgt[1] - c.lng) * w * w - 2 * w * c.vLng) * dt;
      c.lat += c.vLat * dt;
      c.lng += c.vLng * dt;
      // Zoom BEFORE the pan correction — zooming changes the projection, so a
      // pan computed against the old zoom would leave the head off-centre.
      const s = spread.current;
      if (s != null) {
        const want = zoomFor(s, c.lat);
        camZoom.current =
          camZoom.current == null
            ? want
            : camZoom.current + (want - camZoom.current) * Math.min(1, dt / FOLLOW_ZOOM_TAU);
        if (Math.abs(camZoom.current - map.getZoom()) >= FOLLOW_ZOOM_HYSTERESIS) {
          map.setZoom(Math.round(camZoom.current), { animate: false });
        }
      }
      const offset = map
        .latLngToContainerPoint([c.lat, c.lng])
        .subtract(map.getSize().divideBy(2))
        .round();
      if (offset.x !== 0 || offset.y !== 0) {
        map.panBy(offset, { animate: false, noMoveStart: true });
      }
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [map, zoomFor]);
  return null;
}

/** Head position + covered distance of each runner at the given cutoff. */
function headsAt(tracks: PreparedTrack[], cutoff: number) {
  return tracks
    .map((t) => {
      const pts = trackUpTo(t.positions, cutoff);
      if (pts.length === 0) return null;
      const idx = pts.length - 1;
      return { track: t, head: pts[idx], distance: t.cumDist[Math.min(idx, t.cumDist.length - 1)] };
    })
    .filter((x): x is NonNullable<typeof x> => x != null);
}

/** Trail marks (checks, drink stops, on-inn, text tiles) visible at the cutoff. */
/**
 * Numbered pin at the spot each photo was taken, so the number beside the photo
 * in the side panel can be found on the map. The one currently on screen is
 * picked out in gold; the rest sit back in the panel's dark green.
 */
function TvPhotoPins({
  photos, cutoff, size, currentId,
}: {
  photos: PhotoEntry[];
  cutoff: number | null;
  size: number;
  currentId: string | null;
}) {
  return (
    <>
      {photos.map((p) =>
        p.num == null || p.lat == null || p.lng == null ? null
          : cutoff != null && p.markTs != null && p.markTs > cutoff ? null
          : (
            <Marker
              key={`photo-${p.photoId}`}
              position={[p.lat, p.lng]}
              icon={photoPinIcon(p.num, size, p.photoId === currentId)}
              zIndexOffset={600}
            />
          ),
      )}
    </>
  );
}

function TvMarks({
  users, cutoff, size, subdued = false,
}: {
  users: UserTrack[];
  cutoff: number | null;
  size: number;
  /** Overview maps: no label chips, slightly see-through, so the track reads. */
  subdued?: boolean;
}) {
  const marks = useMemo(() => visibleMarks(users, cutoff ?? Infinity), [users, cutoff]);
  const iconOpts = subdued
    ? { hideLabel: true, opacity: OVERVIEW_MARK_OPACITY }
    : undefined;
  return (
    <Pane name={MARK_PANE} style={{ zIndex: MARK_PANE_Z }}>
      {marks.map((m, i) => (
        <Marker
          key={`mark-${i}-${m.rawType}`}
          position={[m.point.lat, m.point.lng]}
          icon={checkpointIcon(m, size, iconOpts)}
        />
      ))}
    </Pane>
  );
}

// ── Map panels ─────────────────────────────────────────────────────────────────

function trackPolyline(t: PreparedTrack, cutoff: number | null, name?: string | null) {
  const pts = cutoff == null ? t.positions : trackUpTo(t.positions, cutoff);
  if (pts.length < 2) return null;
  const head = pts[pts.length - 1];
  return (
    <Fragment key={t.id}>
      <Polyline
        positions={pts.map((p) => [p.lat, p.lng]) as [number, number][]}
        pathOptions={{ color: t.color, weight: 4, opacity: 0.9 }}
      />
      <CircleMarker
        center={[head.lat, head.lng]}
        radius={7}
        pathOptions={{ color: "#ffffff", weight: 2, fillColor: t.color, fillOpacity: 1 }}
      >
        {name && (
          <Tooltip permanent direction="right" offset={[10, 0]} className="tv-name-chip">
            {name}
          </Tooltip>
        )}
      </CircleMarker>
    </Fragment>
  );
}

/** Colored-dot → runner-name legend, overlaid on a map panel. */
function RunnerLegend({ tracks, names }: { tracks: PreparedTrack[]; names: Record<string, string> }) {
  const rows = tracks
    .map((t) => ({ color: t.color, name: names[t.id] }))
    .filter((r): r is { color: string; name: string } => !!r.name);
  if (rows.length === 0) return null;
  return (
    <div className="tv-legend">
      {rows.map((r) => (
        <div key={r.name + r.color} className="tv-legend-row">
          <span className="tv-legend-dot" style={{ background: r.color }} />
          {r.name}
        </div>
      ))}
    </div>
  );
}

function TvMapPanel({
  tracks, users, cutoff, center, label, sublabel, style, names, markPx,
  photos, pinPx, currentPhotoId, showLegend = false,
}: {
  tracks: PreparedTrack[];
  /** Raw payload users — the source of trail marks (PreparedTrack holds GPS only). */
  users: UserTrack[];
  cutoff: number | null;
  center: [number, number];
  label: string;
  sublabel?: string | null;
  style?: React.CSSProperties;
  /** When provided, head dots get permanent name-chip labels. */
  names?: Record<string, string>;
  /** Trail-mark tile size, scaled to the wall by the caller. */
  markPx: number;
  /** Photos to pin, by capture position. */
  photos: PhotoEntry[];
  pinPx: number;
  currentPhotoId: string | null;
  showLegend?: boolean;
}) {
  return (
    <div className="tv-panel" style={style}>
      <div className="tv-panel-label">
        {label}
        {sublabel ? <span className="tv-panel-sublabel">{sublabel}</span> : null}
      </div>
      {showLegend && names && <RunnerLegend tracks={tracks} names={names} />}
      <MapContainer
        center={center}
        zoom={15}
        zoomControl={false}
        attributionControl={false}
        dragging={false}
        scrollWheelZoom={false}
        doubleClickZoom={false}
        style={{ width: "100%", height: "100%", background: "#0c2a0e" }}
      >
        <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
        <AutoFit points={boundsOf(tracks, center)} />
        <TvMarks users={users} cutoff={cutoff} size={markPx} subdued />
        <TvPhotoPins photos={photos} cutoff={cutoff} size={pinPx} currentId={currentPhotoId} />
        {tracks.map((t) => trackPolyline(t, cutoff, names?.[t.id]))}
      </MapContainer>
    </div>
  );
}

// ── Main component ─────────────────────────────────────────────────────────────

export default function TrailTv({
  slug, runNumber, lat, lon, eventId, publicEventId,
  eventName, kennelName, eventStartMs, initialMode,
}: TrailTvProps) {
  const autoMode: "live" | "replay" =
    eventStartMs != null && Date.now() - eventStartMs > 24 * 3600_000 ? "replay" : "live";
  const [mode, setMode] = useState<"live" | "replay">(initialMode ?? autoMode);
  // A ?mode= override or a manual toggle pins the mode; auto-switching only
  // applies while the page is still on its own automatic choice.
  const modePinned = useRef(initialMode != null);
  const modeRef = useRef(mode);
  useEffect(() => { modeRef.current = mode; }, [mode]);

  const [tracks, setTracks] = useState<PreparedTrack[]>([]);
  const [rawUsers, setRawUsers] = useState<UserTrack[]>([]);
  const [markCount, setMarkCount] = useState(0);
  const [names, setNames] = useState<Record<string, string>>({});
  const [photos, setPhotos] = useState<PhotoEntry[]>([]);
  const [takeover, setTakeover] = useState<PhotoEntry | null>(null);
  const [takeoverClosing, setTakeoverClosing] = useState(false);
  const [callouts, setCallouts] = useState<Callout[]>([]);
  const [nowTick, setNowTick] = useState(Date.now());
  const [loopClock, setLoopClock] = useState<number | null>(null);
  const [replayClock, setReplayClock] = useState<number | null>(null);

  const knownPhotoIds = useRef<Set<string> | null>(null);
  const lastMarkTs = useRef<number>(0);
  const firstTrackLoad = useRef(true);
  const photoMarks = useRef<Map<string, PhotoMark>>(new Map());
  const calloutKey = useRef(0);
  const takeoverActiveRef = useRef(false);
  const takeoverIdRef = useRef<string | null>(null);

  // A takeover zooms IN on entry (CSS animation) and must zoom back OUT on
  // exit rather than vanish: dismiss flips a "closing" class for the exit
  // animation, then unmounts. A newer takeover arriving mid-exit replaces it
  // (the stale timeout sees a different id and does nothing).
  const dismissTakeover = useCallback((photoId: string) => {
    if (takeoverIdRef.current !== photoId) return;
    setTakeoverClosing(true);
    setTimeout(() => {
      if (takeoverIdRef.current !== photoId) return;
      setTakeover(null);
      setTakeoverClosing(false);
    }, TAKEOVER_OUT_MS);
  }, []);
  const showTakeover = useCallback((e: PhotoEntry, holdMs: number) => {
    takeoverIdRef.current = e.photoId;
    setTakeoverClosing(false);
    setTakeover(e);
    setTimeout(() => dismissTakeover(e.photoId), holdMs);
  }, [dismissTakeover]);

  // ── Track polling ────────────────────────────────────────────────────────────
  const loadTracks = useCallback(async () => {
    const payload = await fetchPackTrack(eventId);
    if (!payload?.users) return;

    // Photo capture times + mark stats + callouts come from the raw marks.
    let marks = 0;
    const newCallouts: Callout[] = [];
    let newestMark = lastMarkTs.current;
    for (const u of payload.users) {
      for (const p of u.positions) {
        if (!p.type) continue;
        if (p.type.toUpperCase().startsWith("PHO::")) {
          photoMarks.current.set(p.type.slice(5).toLowerCase(), {
            ts: p.timestampMs, lat: p.lat, lng: p.lng,
          });
          continue;
        }
        const parsed = parseMark(p.type);
        if (!parsed) continue;
        marks += 1;
        if (!firstTrackLoad.current && p.timestampMs > lastMarkTs.current) {
          const upper = p.type.toUpperCase();
          const text = parsed.isOnInn
            ? "ON-INN!"
            : upper.startsWith("CHK") || upper.includes("CHECK")
              ? "CHECK DROPPED"
              : upper.startsWith("DRK") || upper.includes("DRINK")
                ? "🍺 DRINK STOP"
                : parsed.label
                  ? parsed.label.toUpperCase()
                  : "NEW TRAIL MARK";
          newCallouts.push({ key: ++calloutKey.current, text, big: parsed.isOnInn });
        }
        if (p.timestampMs > newestMark) newestMark = p.timestampMs;
      }
    }
    lastMarkTs.current = newestMark;
    firstTrackLoad.current = false;
    setMarkCount(marks);
    if (newCallouts.length > 0) {
      setCallouts((cur) => [...cur, ...newCallouts.slice(0, 3)]);
      newCallouts.slice(0, 3).forEach((c) =>
        setTimeout(() => setCallouts((cur) => cur.filter((x) => x.key !== c.key)), CALLOUT_MS),
      );
    }

    const prepared = prepareTracks(payload.users);
    // Decide live → replay HERE, in the same state batch as the track load,
    // so the live maps never receive tracks they'd animate a fitBounds for
    // right before being unmounted (Leaflet's zoom-end timer then fires on
    // the removed map: "Cannot read properties of undefined (_leaflet_pos)").
    if (!modePinned.current && modeRef.current === "live" && prepared.length > 0) {
      const newest = prepared.reduce((m, t) => Math.max(m, t.lastTs), 0);
      if (Date.now() - newest > REPLAY_IDLE_MS) setMode("replay");
    }
    setTracks(prepared);
    setRawUsers(payload.users);

    const missing = prepared.map((t) => t.id).filter((id) => !(id in names));
    if (missing.length > 0) {
      const identity = await fetchRunnerNames(publicEventId, missing);
      setNames((cur) => ({ ...cur, ...identity.names }));
    }
  }, [eventId, publicEventId, names]);

  useEffect(() => {
    loadTracks();
    if (mode !== "live") return;
    const t = setInterval(loadTracks, LIVE_POLL_MS);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mode]);

  // ── Photo polling + takeover queue ───────────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    const load = async () => {
      const map = await fetchRunPhotos(publicEventId);
      if (cancelled) return;
      // markTs is NOT resolved here — see `timedPhotos`. This fetch and the
      // track fetch both start on mount, and this one (a small JSON) nearly
      // always wins, so photoMarks is still empty at this point.
      const entries: PhotoEntry[] = Object.entries(map).map(([photoId, p]) => ({
        ...p, photoId, markTs: null, lat: null, lng: null, num: null,
        outsideRun: false,
      }));
      setPhotos(entries);

      if (knownPhotoIds.current == null) {
        knownPhotoIds.current = new Set(entries.map((e) => e.photoId));
      } else if (mode === "live") {
        for (const e of entries) {
          if (!knownPhotoIds.current.has(e.photoId)) {
            knownPhotoIds.current.add(e.photoId);
            showTakeover(e, TAKEOVER_LIVE_MS);
          }
        }
      } else {
        for (const e of entries) knownPhotoIds.current.add(e.photoId);
      }
    };
    load();
    const t = setInterval(load, mode === "live" ? PHOTO_POLL_MS : 3 * PHOTO_POLL_MS);
    return () => { cancelled = true; clearInterval(t); };
  }, [publicEventId, mode, showTakeover]);

  // Span of the whole run — needed before the photos, which are placed
  // relative to it.
  const timeline = useMemo(() => {
    if (tracks.length === 0) return null;
    const min = Math.min(...tracks.map((t) => t.positions[0].timestampMs));
    const max = Math.max(...tracks.map((t) => t.lastTs));
    return max > min ? { min, max } : null;
  }, [tracks]);

  // When each photo was taken, resolved from the PHO:: marks in the track
  // payload. This is a RENDER-TIME join, not a fetch-time one: the photo list
  // and the track payload are fetched in parallel and the photo list normally
  // lands first, so baking markTs in at fetch time stamped every photo `null`
  // until the next photo poll a minute later — which silently disabled the whole
  // reveal-as-reached feature (every photo dumped into the panel at once, and no
  // photo pauses, because nothing ever "crossed" the clock). Keyed on `tracks`
  // because loadTracks fills photoMarks immediately before setting them.
  // Numbering is assigned here too, in capture order, so the number beside a
  // photo and the number pinned on the map are the same value by construction.
  const timedPhotos = useMemo(() => {
    const timed: PhotoEntry[] = photos.map((p) => {
      const mark = photoMarks.current.get(p.photoId);
      // A PHO:: mark is the best answer — it is the runner's own position at the
      // moment of the shot. Failing that, the upload's CreatedAt still puts the
      // photo somewhere sensible on the timeline, which is far better than
      // treating it as having no time and dumping it at the front of the queue.
      const ts = mark?.ts ?? p.createdAtMs ?? null;
      const outside =
        ts == null ||
        timeline == null ||
        ts < timeline.min ||
        ts > timeline.max;
      return {
        ...p,
        markTs: ts,
        lat: mark?.lat ?? null,
        lng: mark?.lng ?? null,
        num: null,
        outsideRun: outside,
      };
    });
    timed.sort((a, b) => (a.markTs ?? 0) - (b.markTs ?? 0));
    // Only pinnable photos are numbered: the number's whole job is to let you
    // find the shot on the map, and one without a mark has no position.
    let n = 0;
    for (const p of timed) if (p.lat != null) p.num = ++n;
    return timed;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [photos, tracks, timeline]);

  // ── Clocks ───────────────────────────────────────────────────────────────────
  useEffect(() => {
    const t = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  // Replay speed, remembered per screen. Read in an effect rather than during
  // render so the server and the first client paint agree.
  const [paceSecPerKm, setPaceSecPerKm] = useState(DEFAULT_PACE_S_PER_KM);
  useEffect(() => {
    try {
      const raw = window.localStorage.getItem(PACE_STORAGE_KEY);
      const n = raw == null ? NaN : parseInt(raw, 10);
      if (Number.isFinite(n) && n >= PACE_MIN_S && n <= PACE_MAX_S) setPaceSecPerKm(n);
    } catch {
      // Storage blocked (private window, locked-down kiosk) — keep the default.
    }
  }, []);
  const changePace = useCallback((n: number) => {
    setPaceSecPerKm(n);
    try {
      window.localStorage.setItem(PACE_STORAGE_KEY, String(n));
    } catch {
      // Not being able to remember it is not a reason to refuse to change it.
    }
  }, []);

  // The LONGEST track sets the replay length — the same distance the panel
  // advertises as the trail, so the stated pace is the pace you actually see.
  //
  // This used to key off the FIRST finisher's distance (earliest terminal
  // On-Inn), which collapsed onto the 60s floor whenever that finisher's track
  // was short. BMPH3 #2060 is the case that exposed it: two runners marked
  // On-Inn about 70 m in, so a 7.74 km trail replayed in one minute no matter
  // what REPLAY_MS_PER_KM said — the real reason the wall "runs quite quickly".
  const replayDurationMs = useMemo(() => {
    if (tracks.length === 0) return 60_000;
    const longest = tracks.reduce((m, t) => Math.max(m, t.distanceMeters), 0);
    return Math.max(20_000, (longest / 1000) * paceSecPerKm * 1000);
  }, [tracks, paceSecPerKm]);

  // 10-second loop (bottom-left panel, both modes).
  useEffect(() => {
    if (!timeline) return;
    let raf = 0;
    const start = performance.now();
    const tick = (now: number) => {
      const cycle = LOOP_DURATION_MS + LOOP_HOLD_MS;
      const t = (now - start) % cycle;
      const frac = Math.min(1, t / LOOP_DURATION_MS);
      setLoopClock(timeline.min + frac * (timeline.max - timeline.min));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [timeline]);

  // Mirror the takeover state into a ref so the replay interval can consult
  // it without restarting (and resetting) the clock.
  useEffect(() => {
    takeoverActiveRef.current = takeover != null;
    takeoverIdRef.current = takeover?.photoId ?? null;
  }, [takeover]);

  // Paced replay clock + photo sync. 200ms steps: per-tick track math is too
  // heavy for requestAnimationFrame and 5Hz is smooth enough on a wall.
  //
  // The clock ACCUMULATES elapsed time rather than reading the wall clock, so a
  // live takeover left on screen by a mid-run mode flip can still hold it. It
  // does NOT stop for photos: those are queued into the side panel instead.
  // Photos held back to the end need time on screen before the cycle wraps —
  // the bare 6s hold only fits one. A count, not an array, so polling for new
  // photos doesn't restart the replay clock.
  const trailingHoldMs = useMemo(() => {
    const n = timedPhotos.filter((p) => p.outsideRun).length;
    return REPLAY_HOLD_MS + Math.min(n, TRAILING_PHOTOS_MAX) * MIN_PHOTO_MS;
  }, [timedPhotos]);

  const replayElapsedRef = useRef(0);

  // Start over when the run or the mode changes — but NOT when the pace slider
  // moves. That is handled by rescaling, so dragging the slider speeds the wall
  // up from where it is instead of throwing away the replay in progress.
  useEffect(() => { replayElapsedRef.current = 0; }, [mode, timeline]);
  const prevDurationRef = useRef(replayDurationMs);
  useEffect(() => {
    const prev = prevDurationRef.current;
    prevDurationRef.current = replayDurationMs;
    if (prev > 0 && prev !== replayDurationMs) {
      replayElapsedRef.current = Math.min(
        replayDurationMs,
        replayElapsedRef.current * (replayDurationMs / prev),
      );
    }
  }, [replayDurationMs]);

  useEffect(() => {
    if (mode !== "replay" || !timeline) return;
    const span = timeline.max - timeline.min;
    const cycle = replayDurationMs + trailingHoldMs;

    const t = setInterval(() => {
      if (takeoverActiveRef.current) return;
      let el = replayElapsedRef.current + 200;
      if (el >= cycle) el -= cycle;
      replayElapsedRef.current = el;
      setReplayClock(timeline.min + Math.min(1, el / replayDurationMs) * span);
    }, 200);
    return () => clearInterval(t);
  }, [mode, timeline, replayDurationMs, trailingHoldMs]);

  // ── Replay photo queue ───────────────────────────────────────────────────────
  // Reaching a photo's capture moment ENQUEUES it; the panel then shows each
  // queued photo for at least MIN_PHOTO_MS. Without the queue a burst shot at one
  // spot replaced itself within a couple of hundred milliseconds and none of them
  // were seen. `displayed[0]` is on screen now, the rest are the ones already
  // shown, newest first — the same shape the panel used to derive from the clock.
  // The queue holds photo IDs, never photo objects. Capture times arrive with
  // the track payload, AFTER the photo list, so an object captured at enqueue
  // time can be a stale copy with no capture time, no position and no number —
  // exactly the bug that shipped in 0.21.34 in a different place. IDs are
  // resolved against `timedPhotos` at render time, so a queued photo always
  // renders with whatever is currently known about it.
  const queueRef = useRef<string[]>([]);
  const enqueuedRef = useRef<Set<string>>(new Set());
  const shownSinceRef = useRef(0);
  const lastClockRef = useRef<number | null>(null);
  const [displayedIds, setDisplayedIds] = useState<string[]>([]);

  useEffect(() => {
    if (mode !== "replay" || replayClock == null) return;
    // Nothing is reachable before the track payload lands: until then every
    // photo looks unplaced, and enqueueing on that basis would show the whole
    // set at once in arbitrary order.
    if (tracks.length === 0) return;
    // Cycle wrap: start the show over.
    if (lastClockRef.current != null && replayClock < lastClockRef.current) {
      queueRef.current = [];
      enqueuedRef.current = new Set();
      setDisplayedIds([]);
    }
    lastClockRef.current = replayClock;
    const atEnd = timeline != null && replayClock >= timeline.max;
    for (const p of timedPhotos) {
      // Photos taken before the pack set off or after they were in have no
      // moment on the trail. They used to lead the queue, which cost 20 seconds
      // of a BMPH3 wall before the first on-trail photo appeared (James,
      // 2026-08-30); they now wait until the replay has finished.
      const reached = p.outsideRun
        ? atEnd
        : p.markTs != null && p.markTs <= replayClock;
      if (!reached || enqueuedRef.current.has(p.photoId)) continue;
      enqueuedRef.current.add(p.photoId);
      queueRef.current.push(p.photoId);
    }
  }, [mode, replayClock, timedPhotos, tracks.length, timeline]);

  useEffect(() => {
    if (mode !== "replay") return;
    const t = setInterval(() => {
      if (queueRef.current.length === 0) return;
      if (displayedIds.length > 0 && performance.now() - shownSinceRef.current < MIN_PHOTO_MS) {
        return;
      }
      const next = queueRef.current.shift();
      if (next == null) return;
      shownSinceRef.current = performance.now();
      setDisplayedIds((cur) => [next, ...cur]);
    }, 250);
    return () => clearInterval(t);
  }, [mode, displayedIds.length]);

  // ── Photo preloading ─────────────────────────────────────────────────────────
  // A photo's <img> only began fetching when it mounted, so on a slow link the
  // slot sat empty right when the photo was meant to be seen. Warm the next few
  // upcoming photos into the browser cache instead, so they paint instantly.
  // Warm the width they will ACTUALLY be shown at — replay photos now land in
  // the right panel at 1080px, live arrivals still take over the screen at
  // 1920px, and caching the wrong one warms a file nothing requests.
  //
  // In replay the queue is ordered by markTs, so "upcoming" is simply the next
  // few past the clock; in live the newest arrivals are the ones about to fire.
  // The ref makes this idempotent, so re-running on every clock tick is cheap.
  const preloadedRef = useRef<Set<string>>(new Set());
  useEffect(() => {
    if (timedPhotos.length === 0) return;
    const byId = new Map(timedPhotos.map((p) => [p.photoId, p]));
    // In replay, warm what the QUEUE is about to show — not what the clock is
    // about to reach. Those diverge badly at a fast pace: the clock passes every
    // photo long before the queue has shown them (each holds the panel for
    // MIN_PHOTO_MS), so a clock-based window goes empty mid-replay and every
    // remaining photo painted blank for a moment as it appeared.
    const upcoming: PhotoEntry[] =
      mode === "replay"
        ? queueRef.current
            .slice(0, PRELOAD_AHEAD)
            .map((id) => byId.get(id))
            .filter((p): p is PhotoEntry => p != null)
        // Live: the newest arrivals are the ones about to take over the screen.
        : timedPhotos.slice(-PRELOAD_AHEAD);
    const warmWidth = mode === "replay" ? 1080 : 1920;
    for (const p of upcoming) {
      if (preloadedRef.current.has(p.photoId)) continue;
      preloadedRef.current.add(p.photoId);
      const img = new window.Image();
      img.src = photoSrc(p.url, warmWidth);
    }
  }, [timedPhotos, replayClock, displayedIds, mode]);

  // ── Ticker stats ─────────────────────────────────────────────────────────────
  const stats = useMemo(() => {
    const total = tracks.reduce((s, t) => s + t.distanceMeters, 0);
    const active = tracks.filter((t) => nowTick - t.lastTs < ACTIVE_WINDOW_MS).length;
    const finished = tracks.filter((t) => t.finishTs != null).length;
    const elapsed = eventStartMs != null && nowTick > eventStartMs
      ? Math.floor((nowTick - eventStartMs) / 60000) : null;
    return { total, active, finished, elapsed };
  }, [tracks, nowTick, eventStartMs]);

  // Live → replay once the run is over: tracks exist but nobody has reported
  // a position in the last REPLAY_IDLE_MS. The 24h-after-start rule alone
  // left the morning-after screen in live mode (no front-runner cam, no
  // photo takeovers) until the following evening. Deliberately longer than
  // the 10-min "on trail" window so a pack-wide drink-stop lull mid-run
  // doesn't flip a live wall into replay. (The first-load case is decided
  // inside loadTracks; this covers a live wall whose pack goes home later.)
  const newestPositionTs = tracks.reduce((m, t) => Math.max(m, t.lastTs), 0);
  useEffect(() => {
    if (modePinned.current || mode !== "live" || tracks.length === 0) return;
    if (nowTick - newestPositionTs > REPLAY_IDLE_MS) setMode("replay");
  }, [mode, tracks.length, newestPositionTs, nowTick]);

  // Overview trail-mark size follows the window so the wall looks the same on a
  // laptop preview and a 4K screen. Seeded at the design width rather than read
  // during render, so the server and first client paint agree.
  const [viewportW, setViewportW] = useState(1920);
  useEffect(() => {
    const onResize = () => setViewportW(window.innerWidth);
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);
  const scaledMarkPx = (fraction: number, lo: number, hi: number) =>
    Math.round(Math.min(hi, Math.max(lo, viewportW * MAP_COLUMN_FRACTION * fraction)));
  const overviewMarkPx = scaledMarkPx(OVERVIEW_MARK_FRACTION, OVERVIEW_MARK_MIN, OVERVIEW_MARK_MAX);
  const camMarkPx = scaledMarkPx(CAM_MARK_FRACTION, CAM_MARK_MIN, CAM_MARK_MAX);
  const pinPx = scaledMarkPx(PIN_FRACTION, PIN_MIN, PIN_MAX);
  const camPinPx = scaledMarkPx(PIN_FRACTION * 1.6, PIN_MIN, PIN_MAX * 1.6);

  const carouselRef = useRef<HTMLDivElement | null>(null);
  const marqueeRef = useRef<HTMLDivElement | null>(null);
  const [marqueeAnimated, setMarqueeAnimated] = useState(false);
  const [imgLoadTick, setImgLoadTick] = useState(0);

  // Animate the carousel only when the single photo list truly overflows the
  // panel. scrollHeight counts the duplicated list when animating, so halve it
  // in that case before comparing.
  useEffect(() => {
    // Replay never scrolls: the panel is a reveal feed anchored to the top, so
    // the photo the replay has just reached is always the one on screen.
    if (mode === "replay") {
      if (marqueeAnimated) setMarqueeAnimated(false);
      return;
    }
    const measure = () => {
      const c = carouselRef.current, m = marqueeRef.current;
      if (!c || !m) return;
      const single = marqueeAnimated ? m.scrollHeight / 2 : m.scrollHeight;
      const should = single > c.clientHeight + 20;
      if (should !== marqueeAnimated) setMarqueeAnimated(should);
    };
    measure();
    window.addEventListener("resize", measure);
    return () => window.removeEventListener("resize", measure);
  }, [timedPhotos, imgLoadTick, marqueeAnimated, mode]);


  // Right-panel photo feed.
  //   live   — every approved photo, marquee-scrolled; a brand-new arrival ALSO
  //            takes over the screen, which is the point of a live wall.
  //   replay — the queue above, held at least MIN_PHOTO_MS each. James,
  //            2026-08-30: full-screen takeovers on a replay are "too
  //            distracting" — the photo is hours old, so it belongs beside the
  //            map, not over it — and the replay must keep running behind it.
  const photoById = useMemo(
    () => new Map(timedPhotos.map((p) => [p.photoId, p])),
    [timedPhotos],
  );
  const carouselPhotos = useMemo(
    () => (mode !== "replay"
      ? timedPhotos
      : displayedIds
          .map((id) => photoById.get(id))
          .filter((p): p is PhotoEntry => p != null)),
    [mode, timedPhotos, displayedIds, photoById],
  );
  // The -50% translate marquee only works when content genuinely overflows;
  // otherwise it scrolls the short column out of view and the panel goes
  // blank. MEASURE the rendered single-list height against the container
  // (re-checked as images load and on resize) instead of guessing by count.
  const marqueeList = marqueeAnimated
    ? [...carouselPhotos, ...carouselPhotos]
    : carouselPhotos;
  const marqueeSeconds = Math.max(30, carouselPhotos.length * 8);

  // Carousel scroll is JS-driven so the speed can EASE to a stop while a
  // photo takeover is showing and ease back up afterwards (a CSS keyframe
  // can only hard-pause). Exponential approach, ~0.6s time constant.
  useEffect(() => {
    const el = marqueeRef.current;
    if (!marqueeAnimated) {
      if (el) el.style.transform = "";
      return;
    }
    let raf = 0;
    let last = performance.now();
    let offset = 0;
    let speed = 1;
    const tick = (now: number) => {
      const dt = Math.min(100, now - last);
      last = now;
      const target = takeoverActiveRef.current ? 0 : 1;
      speed += (target - speed) * Math.min(1, dt / 600);
      const m = marqueeRef.current;
      if (m) {
        const half = m.scrollHeight / 2;
        if (half > 0) {
          const pxPerMs = half / (marqueeSeconds * 1000);
          offset = (offset + pxPerMs * dt * speed) % half;
          m.style.transform = `translateY(-${offset.toFixed(2)}px)`;
        }
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [marqueeAnimated, marqueeSeconds]);

  // Front runner at the replay clock — most distance covered so far. The cam
  // sticks with the current leader until someone is genuinely ahead
  // (LEAD_HYSTERESIS_METERS), so neck-and-neck runners don't yank the camera
  // back and forth every tick.
  const leaderIdRef = useRef<string | null>(null);
  const frontRunner = useMemo(() => {
    if (mode !== "replay" || replayClock == null || tracks.length === 0) {
      leaderIdRef.current = null;
      return null;
    }
    const heads = headsAt(tracks, replayClock);
    if (heads.length === 0) {
      leaderIdRef.current = null;
      return null;
    }
    const best = heads.reduce((a, b) => (a.distance >= b.distance ? a : b));
    const cur = heads.find((h) => h.track.id === leaderIdRef.current);
    const chosen = cur && best.distance - cur.distance < LEAD_HYSTERESIS_METERS ? cur : best;
    leaderIdRef.current = chosen.track.id;
    return chosen;
  }, [mode, replayClock, tracks]);

  // How much ground this run's leader typically covered in FOLLOW_WINDOW_MS —
  // one number for the whole replay, so the cam zoom never moves during
  // playback. Sliding window over the longest track, straight-line start-to-end
  // (cheap and good enough to size a camera), 75th percentile so one sprint or
  // one long stop does not set the framing for the entire run.
  const camSpreadMeters = useMemo(() => {
    if (tracks.length === 0) return null;
    const pts = tracks.reduce((a, b) => (a.distanceMeters >= b.distanceMeters ? a : b)).positions;
    if (pts.length < 2) return null;
    const spans: number[] = [];
    let j = 0;
    for (let i = 1; i < pts.length; i++) {
      while (j < i && pts[i].timestampMs - pts[j].timestampMs > FOLLOW_WINDOW_MS) j++;
      spans.push(haversineMeters(pts[j].lat, pts[j].lng, pts[i].lat, pts[i].lng));
    }
    if (spans.length === 0) return null;
    spans.sort((a, b) => a - b);
    return spans[Math.min(spans.length - 1, Math.floor(spans.length * FOLLOW_SPREAD_PERCENTILE))];
  }, [tracks]);

  // See FOLLOW_SPRING_OMEGA: keep the camera's lag constant in metres as the
  // pace changes, rather than letting a fast replay outrun its own smoothing.
  const camOmega = Math.min(
    FOLLOW_SPRING_OMEGA_MAX,
    FOLLOW_SPRING_OMEGA * (FOLLOW_SPRING_REF_PACE_S / paceSecPerKm),
  );

  const replayPaceLabel = paceSecPerKm < 60
    ? `${paceSecPerKm} s`
    : `${(paceSecPerKm / 60).toFixed(1).replace(/\.0$/, "")} min`;

  const currentPhotoId = carouselPhotos.length > 0 ? carouselPhotos[0].photoId : null;

  const center: [number, number] = [lat, lon];
  const followUrl = `https://www.hashruns.org/${slug}/${runNumber}`;


  return (
    <div className="tv-root">
      <style>{`
        .tv-root { position: fixed; inset: 0; background: #0c2a0e url('/images/jungle_background.jpg'); background-size: 512px; color: #fff; font-family: system-ui, sans-serif; display: grid; grid-template-columns: 55% 45%; grid-template-rows: 1fr 1fr 56px; gap: 10px; padding: 10px; }
        .tv-panel { grid-column: 1; position: relative; border-radius: 14px; overflow: hidden; border: 1px solid rgba(255,255,255,.18); box-shadow: 0 8px 30px rgba(0,0,0,.5); }
        .tv-panel-label { position: absolute; z-index: 1000; top: 10px; left: 10px; background: rgba(12,42,14,.85); border: 1px solid rgba(255,255,255,.25); padding: 6px 14px; border-radius: 999px; font-weight: 700; font-size: 15px; letter-spacing: .06em; }
        .tv-panel-sublabel { margin-left: 10px; font-weight: 400; opacity: .8; font-size: 13px; }
        .tv-live-dot { display:inline-block; width:9px; height:9px; border-radius:50%; background:#ef4444; margin-right:8px; animation: tvpulse 1.4s infinite; }
        @keyframes tvpulse { 0%,100% { opacity: 1 } 50% { opacity: .3 } }
        .tv-carousel { grid-column: 2; grid-row: 1 / span 2; position: relative; border-radius: 14px; overflow: hidden; border: 1px solid rgba(255,255,255,.18); background: rgba(0,0,0,.45); }
        .tv-marquee { display: flex; flex-direction: column; gap: 10px; padding: 10px; will-change: transform; }
        .tv-photo { width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 18px rgba(0,0,0,.6); }
        .tv-photo-cap { font-size: 13px; opacity: .85; margin: -4px 2px 6px; }
        .tv-reveal { position: absolute; inset: 0; display: flex; flex-direction: column; gap: 10px; padding: 10px; }
        .tv-reveal-hero { flex: 1; min-height: 0; display: flex; flex-direction: column; gap: 8px; }
        .tv-reveal-frame { flex: 1; min-height: 0; display: flex; align-items: center; justify-content: center; }
        .tv-reveal-imgbox { position: relative; display: flex; max-width: 100%; max-height: 100%; min-height: 0; }
        .tv-reveal-frame img { display: block; max-width: 100%; max-height: 100%; object-fit: contain; border-radius: 10px; box-shadow: 0 4px 18px rgba(0,0,0,.6); }
        .tv-reveal-cap { flex: 0 0 auto; font-size: 15px; opacity: .85; text-align: center; }
        .tv-reveal-frame { position: relative; }
        .tv-reveal-strip { flex: 0 0 14%; display: flex; gap: 8px; min-height: 0; }
        .tv-reveal-thumb { position: relative; flex: 1 1 0; min-width: 0; height: 100%; }
        .tv-reveal-thumb img { width: 100%; height: 100%; object-fit: cover; border-radius: 8px; opacity: .6; }
        .tv-marquee-item { position: relative; }
        /* Photo number — the same value pinned on the map where it was taken. */
        .tv-photo-num { position: absolute; top: 8px; left: 8px; z-index: 2; min-width: 40px; height: 40px; padding: 0 10px; border-radius: 999px; background: #e0a51e; color: #1a1a00; font: 800 22px/40px system-ui, sans-serif; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,.55); }
        .tv-photo-num.small { top: 5px; left: 5px; min-width: 24px; height: 24px; padding: 0 6px; font-size: 14px; line-height: 24px; }
        .tv-photo-reveal { animation: tvreveal .6s ease-out; }
        @keyframes tvreveal { from { transform: scale(.88); opacity: 0 } to { transform: scale(1); opacity: 1 } }
        .tv-empty { position:absolute; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:12px; opacity:.75; font-size:20px; text-align:center; padding:30px; }
        .tv-ticker { grid-column: 1 / -1; display: flex; align-items: center; gap: 28px; background: rgba(12,42,14,.9); border: 1px solid rgba(255,255,255,.18); border-radius: 14px; padding: 0 22px; font-size: 17px; overflow: hidden; white-space: nowrap; }
        .tv-stat b { color: #e0a51e; font-size: 21px; margin-right: 6px; }
        .tv-brand { font-weight: 800; letter-spacing: .04em; margin-right: auto; }
        .tv-qr { display:flex; align-items:center; gap:10px; background:#fff; border-radius:8px; padding:4px; }
        .tv-qr-caption { font-size: 13px; opacity:.9; }
        .tv-takeover { position: fixed; inset: 0; z-index: 5000; background: rgba(0,0,0,.88); display: flex; align-items: center; justify-content: center; flex-direction: column; gap: 14px; animation: tvzoom .5s ease-out; }
        @keyframes tvzoom { from { transform: scale(.6); opacity: 0 } to { transform: scale(1); opacity: 1 } }
        .tv-takeover.closing { animation: tvzoomout .45s ease-in forwards; }
        @keyframes tvzoomout { from { transform: scale(1); opacity: 1 } to { transform: scale(.6); opacity: 0 } }
        .tv-takeover img { max-width: 92vw; max-height: 84vh; border-radius: 16px; box-shadow: 0 0 80px rgba(224,165,30,.4); }
        .tv-takeover-badge { background: #B71C1C; color: #fff; font-weight: 800; padding: 8px 26px; border-radius: 999px; font-size: 22px; letter-spacing: .04em; }
        .tv-callouts { position: fixed; top: 18px; left: 50%; transform: translateX(-50%); z-index: 4000; display: flex; flex-direction: column; gap: 10px; align-items: center; }
        .tv-callout { background: #B71C1C; color: #fff; font-weight: 900; padding: 10px 34px; border-radius: 999px; font-size: 26px; letter-spacing: .08em; box-shadow: 0 8px 30px rgba(0,0,0,.6); animation: tvslide .4s ease-out; }
        .tv-callout.big { font-size: 40px; background: #e0a51e; color: #1a1a00; padding: 16px 48px; }
        @keyframes tvslide { from { transform: translateY(-60px); opacity: 0 } to { transform: translateY(0); opacity: 1 } }
        .tv-name-chip { background: rgba(12,42,14,.88) !important; color: #fff !important; border: 1px solid rgba(255,255,255,.4) !important; border-radius: 999px !important; padding: 2px 9px !important; font-weight: 700; font-size: 12px; box-shadow: none !important; }
        .tv-name-chip::before { display: none !important; }
        .tv-legend { position: absolute; z-index: 1000; top: 10px; right: 10px; background: rgba(12,42,14,.85); border: 1px solid rgba(255,255,255,.25); border-radius: 12px; padding: 8px 14px; display: flex; flex-direction: column; gap: 5px; font-size: 13px; font-weight: 600; }
        .tv-legend-row { display: flex; align-items: center; gap: 8px; }
        .tv-legend-dot { width: 11px; height: 11px; border-radius: 50%; border: 2px solid #fff; }
        .tv-mode { position: fixed; bottom: 66px; left: 16px; z-index: 3000; background: rgba(0,0,0,.55); border: 1px solid rgba(255,255,255,.3); color: #fff; border-radius: 999px; padding: 5px 16px; font-size: 13px; cursor: pointer; opacity: .35; }
        .tv-mode:hover { opacity: 1; }
        /* Sits beside the mode toggle, equally recessive — a wall runs
           unattended, but whoever set it up can dial the pace. */
        .tv-pace { position: fixed; bottom: 66px; left: 152px; z-index: 3000; display: flex; align-items: center; gap: 9px; background: rgba(0,0,0,.55); border: 1px solid rgba(255,255,255,.3); color: #fff; border-radius: 999px; padding: 5px 16px; font-size: 13px; opacity: .35; transition: opacity .2s; }
        .tv-pace:hover { opacity: 1; }
        .tv-pace input { width: 120px; accent-color: #e0a51e; cursor: pointer; }
        .tv-pace-value { min-width: 66px; font-variant-numeric: tabular-nums; }
      `}</style>

      {/* ── Left column: live = live map + 10s loop; replay = one big paced
             replay map spanning both rows, with the photo show alongside ── */}
      {mode === "live" ? (
        <>
          <TvMapPanel
            tracks={tracks}
            users={rawUsers}
            cutoff={null}
            center={center}
            label="LIVE"
            sublabel={`${stats.active} on trail`}
            names={names}
            markPx={overviewMarkPx}
            photos={timedPhotos}
            pinPx={pinPx}
            currentPhotoId={currentPhotoId}
            showLegend
          />
          <TvMapPanel
            tracks={tracks}
            users={rawUsers}
            cutoff={loopClock}
            center={center}
            label="THE RUN IN 10 SECONDS"
            markPx={overviewMarkPx}
            photos={timedPhotos}
            pinPx={pinPx}
            currentPhotoId={currentPhotoId}
          />
        </>
      ) : (
        <>
          <div className="tv-panel">
            <div className="tv-panel-label">
              FRONT RUNNER CAM
              {frontRunner && (
                <span className="tv-panel-sublabel">
                  {names[frontRunner.track.id] ?? "leading"} · {formatDistanceLabel(frontRunner.distance)}
                </span>
              )}
            </div>
            <RunnerLegend tracks={tracks} names={names} />
            <MapContainer
              center={center}
              zoom={FOLLOW_ZOOM}
              zoomSnap={1}
              zoomControl={false}
              attributionControl={false}
              dragging={false}
              scrollWheelZoom={false}
              doubleClickZoom={false}
              style={{ width: "100%", height: "100%", background: "#0c2a0e" }}
            >
              <TileLayer
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                keepBuffer={4}
              />
              <FollowCenter
                center={frontRunner ? [frontRunner.head.lat, frontRunner.head.lng] : null}
                spreadMeters={camSpreadMeters}
                omega={camOmega}
              />
              <TvMarks users={rawUsers} cutoff={replayClock} size={camMarkPx} />
              <TvPhotoPins
                photos={timedPhotos}
                cutoff={replayClock}
                size={camPinPx}
                currentId={currentPhotoId}
              />
              {tracks.map((t) => trackPolyline(t, replayClock, names[t.id]))}
            </MapContainer>
          </div>
          <TvMapPanel
            tracks={tracks}
            users={rawUsers}
            cutoff={replayClock}
            center={center}
            label="RUN REPLAY"
            sublabel={`${replayPaceLabel} / km · ${formatDistanceLabel(tracks.reduce((m, t) => Math.max(m, t.distanceMeters), 0))} trail`}
            markPx={overviewMarkPx}
            photos={timedPhotos}
            pinPx={pinPx}
            currentPhotoId={currentPhotoId}
          />
        </>
      )}

      {/* ── Right column: photo carousel (live) / reveal feed (replay) ── */}
      <div className="tv-carousel" ref={carouselRef}>
        {mode === "replay" && carouselPhotos.length > 0 ? (
          // Sized to the panel rather than stacked at natural height: with the
          // marquee stopped, a column of full-width photos simply ran off the
          // bottom and the older ones were never seen. Newest fills the frame,
          // the previous few sit under it as thumbnails.
          <div className="tv-reveal">
            <div className="tv-reveal-hero tv-photo-reveal" key={carouselPhotos[0].photoId}>
              <div className="tv-reveal-frame">
                <div className="tv-reveal-imgbox">
                  {carouselPhotos[0].num != null && (
                    <div className="tv-photo-num">{carouselPhotos[0].num}</div>
                  )}
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={photoSrc(carouselPhotos[0].url, 1080)}
                    alt={carouselPhotos[0].title ?? "run photo"}
                    onError={(e) => {
                      const p0 = carouselPhotos[0];
                      if (e.currentTarget.src !== p0.url) e.currentTarget.src = p0.url;
                    }}
                  />
                </div>
              </div>
              {(carouselPhotos[0].title || carouselPhotos[0].uploader) && (
                <div className="tv-reveal-cap">
                  {carouselPhotos[0].title ?? ""}
                  {carouselPhotos[0].title && carouselPhotos[0].uploader ? " — " : ""}
                  {carouselPhotos[0].uploader ? `📷 ${carouselPhotos[0].uploader}` : ""}
                </div>
              )}
            </div>
            {carouselPhotos.length > 1 && (
              <div className="tv-reveal-strip">
                {carouselPhotos.slice(1, 1 + REVEAL_STRIP_MAX).map((p) => (
                  <div className="tv-reveal-thumb" key={p.photoId}>
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={photoSrc(p.url, 256)}
                      alt={p.title ?? "earlier run photo"}
                      onError={(e) => {
                        if (e.currentTarget.src !== p.url) e.currentTarget.src = p.url;
                      }}
                    />
                    {p.num != null && <div className="tv-photo-num small">{p.num}</div>}
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : marqueeList.length === 0 ? (
          <div className="tv-empty">
            <div style={{ fontSize: 44 }}>📸</div>
            <div>
              {mode === "replay"
                ? "Photos appear as the replay reaches them…"
                : "Waiting for the first photo from trail…"}
            </div>
            <div style={{ fontSize: 14, opacity: 0.7 }}>
              {mode === "replay"
                ? "Each shot pops in at the point on trail where it was taken"
                : "Hash Flash photos appear here moments after they\u2019re taken"}
            </div>
          </div>
        ) : (
          <div ref={marqueeRef} className="tv-marquee">
            {/* Key by photo, not by index: in replay a newly-reached photo is
                PREPENDED, and index keys would remount (and re-animate, and
                re-fetch) the whole column every time one arrived. The suffix
                only distinguishes the duplicated marquee copy in live mode. */}
            {marqueeList.map((p, i) => (
              <div
                key={`${p.photoId}-${i < carouselPhotos.length ? 0 : 1}`}
                className={`tv-marquee-item${mode === "replay" ? " tv-photo-reveal" : ""}`}
              >
                {p.num != null && <div className="tv-photo-num small">{p.num}</div>}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  className="tv-photo"
                  src={photoSrc(p.url, 1080)}
                  alt={p.title ?? "run photo"}
                  onLoad={() => setImgLoadTick((n) => n + 1)}
                  onError={(e) => {
                    // Optimizer unavailable → fall back to the original blob.
                    if (e.currentTarget.src !== p.url) e.currentTarget.src = p.url;
                  }}
                />
                {(p.title || p.uploader) && (
                  <div className="tv-photo-cap">
                    {p.title ?? ""}{p.title && p.uploader ? " — " : ""}{p.uploader ? `📷 ${p.uploader}` : ""}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── Ticker ── */}
      <div className="tv-ticker">
        <span className="tv-brand">
          {mode === "live" && <span className="tv-live-dot" />}
          {kennelName} · {eventName}
        </span>
        <span className="tv-stat"><b>{tracks.length}</b>hashers tracked</span>
        {mode === "live" && <span className="tv-stat"><b>{stats.active}</b>on trail now</span>}
        <span className="tv-stat"><b>{formatDistanceLabel(stats.total)}</b>pack distance</span>
        <span className="tv-stat"><b>{markCount}</b>trail marks</span>
        {stats.finished > 0 && <span className="tv-stat"><b>{stats.finished}</b>on-inn</span>}
        {mode === "live" && stats.elapsed != null && stats.elapsed < 24 * 60 && (
          <span className="tv-stat"><b>{Math.floor(stats.elapsed / 60)}h {stats.elapsed % 60}m</b>elapsed</span>
        )}
        <span className="tv-qr"><QRCode value={followUrl} size={40} /></span>
        <span className="tv-qr-caption">Follow along<br />{`hashruns.org/${slug}`}</span>
      </div>

      {/* ── Overlays ── */}
      <button
        className="tv-mode"
        onClick={() => {
          modePinned.current = true;
          setMode(mode === "live" ? "replay" : "live");
        }}
      >
        {mode === "live" ? "switch to replay" : "switch to live"}
      </button>

      {mode === "replay" && (
        <div className="tv-pace">
          <label htmlFor="tv-pace">speed</label>
          <input
            id="tv-pace"
            type="range"
            min={PACE_MIN_S}
            max={PACE_MAX_S}
            step={PACE_STEP_S}
            value={paceSecPerKm}
            onChange={(e) => changePace(Number(e.target.value))}
          />
          <span className="tv-pace-value">{replayPaceLabel} / km</span>
        </div>
      )}

      <div className="tv-callouts">
        {callouts.map((c) => (
          <div key={c.key} className={`tv-callout${c.big ? " big" : ""}`}>{c.text}</div>
        ))}
      </div>

      {takeover && (
        <div
          className={`tv-takeover${takeoverClosing ? " closing" : ""}`}
          onClick={() => dismissTakeover(takeover.photoId)}
        >
          {/* "Fresh from trail" only means something live — in replay the
              photo is minutes or hours old, so the badge is just noise. */}
          {mode === "live" && (
            <div className="tv-takeover-badge">📸 FRESH FROM TRAIL</div>
          )}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={photoSrc(takeover.url, 1920)}
            alt={takeover.title ?? "new run photo"}
            onError={(e) => {
              if (e.currentTarget.src !== takeover.url) e.currentTarget.src = takeover.url;
            }}
          />
          {(takeover.title || takeover.uploader) && (
            <div style={{ fontSize: 20 }}>
              {takeover.title ?? ""}{takeover.title && takeover.uploader ? " — " : ""}
              {takeover.uploader ? `📷 ${takeover.uploader}` : ""}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
