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
import { MapContainer, TileLayer, Polyline, CircleMarker, Marker, Tooltip, useMap } from "react-leaflet";
import QRCode from "react-qr-code";
import { checkpointIcon, visibleMarks } from "./trackMarks";
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
// Replay pace. Wound back from 60s/km on 2026-08-30: at the old speed the pack
// crossed the front-runner cam faster than the camera spring could follow, so
// runners visibly trailed off the edge of frame (a critically damped spring lags
// its target by 2/omega SECONDS of travel — cut the on-screen speed and the lag
// shrinks with it). The panel sublabel is generated from this, so it can be
// re-tuned here alone.
const REPLAY_MS_PER_KM = 90_000; // 1.5 minutes of wall time per km of trail
const REPLAY_HOLD_MS = 6_000;
// A newly revealed photo eases the replay to a standstill, holds, then eases
// back up — otherwise a cluster of photos taken at one spot flashes past
// unread. Easing (not a hard freeze) so the map never jerks.
const PHOTO_PAUSE_MS = 3_500;
const PHOTO_EASE_MS = 900;
const TAKEOVER_LIVE_MS = 10_000;  // fresh-from-trail photo, live mode
const PRELOAD_AHEAD = 4;          // photos warmed into cache ahead of the takeover
const TAKEOVER_OUT_MS = 450;       // zoom-back-out exit animation (matches .closing CSS)
const CALLOUT_MS = 6_000;
const ACTIVE_WINDOW_MS = 10 * 60_000; // "on trail" = a point in the last 10 min
const REPLAY_IDLE_MS = 30 * 60_000; // live → replay once no runner has reported for 30 min
// Front-runner cam zoom is DERIVED, not fixed: the camera keeps the ground the
// leader covered over the last FOLLOW_WINDOW_MS of run time inside the frame, so
// a fast leg pulls the view out and a stop at a check lets it back in. Smoothed
// over FOLLOW_ZOOM_TAU seconds and only applied past a dead-band, so the wall
// drifts rather than churning tiles. FOLLOW_ZOOM is just the first-fix fallback.
const FOLLOW_ZOOM = 16;
const FOLLOW_ZOOM_MIN = 14;
const FOLLOW_ZOOM_MAX = 17;
const FOLLOW_WINDOW_MS = 3 * 60_000; // of RUN time behind the leader to keep in frame
const FOLLOW_SPAN_PADDING = 1.25;    // breathing room around that ground
const FOLLOW_MIN_SPAN_M = 60;        // don't zoom to the rooftops when they stop
const FOLLOW_ZOOM_TAU = 4;           // seconds — zoom smoothing time constant
const FOLLOW_ZOOM_DEADBAND = 0.3;    // ignore smaller corrections (tile-grid rebuilds)
const FOLLOW_SPRING_OMEGA = 3; // rad/s — camera spring stiffness; lower = floatier follow-cam
const LEAD_HYSTERESIS_METERS = 15; // new leader must be this far ahead to steal the cam
// Cam marks scale with the wall like the overview ones, but bigger and still
// labelled — the cam is where a mark is actually meant to be read.
const CAM_MARK_FRACTION = 0.035;
const CAM_MARK_MIN = 22;
const CAM_MARK_MAX = 56;
// The replay panel shows the newest photo large with the previous few beneath;
// the old single scrolling column clipped whatever ran past the panel bottom.
const REVEAL_STRIP_MAX = 4;
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
  center, spreadMeters,
}: {
  center: [number, number] | null;
  /** How far the leader has ranged from their current position over the recent
   *  window — the ground the camera has to keep in frame. null = hold zoom. */
  spreadMeters: number | null;
}) {
  const map = useMap();
  const target = useRef<[number, number] | null>(null);
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
        map.setView(tgt, camZoom.current, { animate: false });
        return;
      }
      const c = cam.current;
      const w = FOLLOW_SPRING_OMEGA;
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
        if (Math.abs(map.getZoom() - camZoom.current) >= FOLLOW_ZOOM_DEADBAND) {
          map.setZoom(camZoom.current, { animate: false });
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
/** Smoothstep 0..1 — used to ease the replay to a stop behind a photo. */
function smoothstep(x: number): number {
  const t = Math.max(0, Math.min(1, x));
  return t * t * (3 - 2 * t);
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
    <>
      {marks.map((m, i) => (
        <Marker
          key={`mark-${i}-${m.rawType}`}
          position={[m.point.lat, m.point.lng]}
          icon={checkpointIcon(m, size, iconOpts)}
          zIndexOffset={500}
        />
      ))}
    </>
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
  tracks, users, cutoff, center, label, sublabel, style, names, markPx, showLegend = false,
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
  const photoMarkTs = useRef<Map<string, number>>(new Map());
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
          photoMarkTs.current.set(p.type.slice(5).toLowerCase(), p.timestampMs);
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
      // always wins, so photoMarkTs is still empty at this point.
      const entries: PhotoEntry[] = Object.entries(map).map(([photoId, p]) => ({
        ...p, photoId, markTs: null,
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

  // When each photo was taken, resolved from the PHO:: marks in the track
  // payload. This is a RENDER-TIME join, not a fetch-time one: the photo list
  // and the track payload are fetched in parallel and the photo list normally
  // lands first, so baking markTs in at fetch time stamped every photo `null`
  // until the next photo poll a minute later — which silently disabled the whole
  // reveal-as-reached feature (every photo dumped into the panel at once, and no
  // photo pauses, because nothing ever "crossed" the clock). Keyed on `tracks`
  // because loadTracks fills photoMarkTs immediately before setting them.
  const timedPhotos = useMemo(() => {
    const timed = photos.map((p) => ({
      ...p,
      markTs: photoMarkTs.current.get(p.photoId) ?? null,
    }));
    timed.sort((a, b) => (a.markTs ?? 0) - (b.markTs ?? 0));
    return timed;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [photos, tracks]);

  // ── Clocks ───────────────────────────────────────────────────────────────────
  useEffect(() => {
    const t = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  const timeline = useMemo(() => {
    if (tracks.length === 0) return null;
    const min = Math.min(...tracks.map((t) => t.positions[0].timestampMs));
    const max = Math.max(...tracks.map((t) => t.lastTs));
    return max > min ? { min, max } : null;
  }, [tracks]);

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
    return Math.max(60_000, (longest / 1000) * REPLAY_MS_PER_KM);
  }, [tracks]);

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
  // The clock ACCUMULATES elapsed time rather than reading the wall clock, so it
  // can run at a variable rate: crossing a photo's capture moment eases the
  // replay to a standstill, holds it while the photo is read, then eases back up
  // to full speed. A hard freeze (the old behaviour behind a takeover) visibly
  // jerked the map, and without any hold a burst of photos taken at one spot
  // replaced each other before anyone could look.
  const replayElapsedRef = useRef(0);
  const photoPauseAtRef = useRef<number | null>(null);
  const photosRef = useRef<PhotoEntry[]>([]);
  useEffect(() => { photosRef.current = timedPhotos; }, [timedPhotos]);

  useEffect(() => {
    if (mode !== "replay" || !timeline) return;
    replayElapsedRef.current = 0;
    photoPauseAtRef.current = null;
    const span = timeline.max - timeline.min;
    const cycle = replayDurationMs + REPLAY_HOLD_MS;
    const clockOf = (e: number) =>
      timeline.min + Math.min(1, e / replayDurationMs) * span;

    const t = setInterval(() => {
      let speed = 1;
      const pausedAt = photoPauseAtRef.current;
      if (pausedAt != null) {
        const u = performance.now() - pausedAt;
        if (u >= PHOTO_EASE_MS * 2 + PHOTO_PAUSE_MS) photoPauseAtRef.current = null;
        else if (u < PHOTO_EASE_MS) speed = 1 - smoothstep(u / PHOTO_EASE_MS);
        else if (u < PHOTO_EASE_MS + PHOTO_PAUSE_MS) speed = 0;
        else speed = smoothstep((u - PHOTO_EASE_MS - PHOTO_PAUSE_MS) / PHOTO_EASE_MS);
      }
      // A live takeover can still be on screen if the wall flipped mode midway.
      if (takeoverActiveRef.current) speed = 0;

      const prevEl = replayElapsedRef.current;
      let el = prevEl + 200 * speed;
      if (el >= cycle) el -= cycle;
      replayElapsedRef.current = el;

      const nextClock = clockOf(el);
      // Arm a pause when the clock has just crossed a photo's capture moment.
      // `el > prevEl` skips the cycle wrap, where the window is meaningless.
      if (el > prevEl && photoPauseAtRef.current == null) {
        const prevClock = clockOf(prevEl);
        for (const p of photosRef.current) {
          if (p.markTs != null && p.markTs > prevClock && p.markTs <= nextClock) {
            photoPauseAtRef.current = performance.now();
            break;
          }
        }
      }
      setReplayClock(nextClock);
    }, 200);
    return () => clearInterval(t);
  }, [mode, timeline, replayDurationMs]);

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
    const clock = replayClock;
    const upcoming =
      mode === "replay" && clock != null
        // Only timeline-placed photos are "upcoming". Unplaced ones (no PHO::
        // point) sort to the front of `photos` and are on screen from the start
        // of the cycle anyway, so letting them fill this window would starve
        // the photos the replay is actually about to reach.
        ? timedPhotos
            .filter((p) => p.markTs != null && p.markTs > clock)
            .slice(0, PRELOAD_AHEAD)
        // Replay not started (or live): warm the front of the queue / the
        // newest arrivals, which are the ones about to take over.
        : mode === "replay"
          ? timedPhotos.slice(0, PRELOAD_AHEAD)
          : timedPhotos.slice(-PRELOAD_AHEAD);
    const warmWidth = mode === "replay" ? 1080 : 1920;
    for (const p of upcoming) {
      if (preloadedRef.current.has(p.photoId)) continue;
      preloadedRef.current.add(p.photoId);
      const img = new window.Image();
      img.src = photoSrc(p.url, warmWidth);
    }
  }, [timedPhotos, replayClock, mode]);

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
  //   replay — photos are REVEALED as the replay clock reaches the moment they
  //            were taken and stack newest-first at the top. James, 2026-08-30:
  //            full-screen takeovers on a replay are "too distracting" — the
  //            photo is hours old, so it belongs beside the map, not over it.
  const carouselPhotos = useMemo(() => {
    if (mode !== "replay") return timedPhotos;
    const reached: PhotoEntry[] = [];
    const unplaced: PhotoEntry[] = [];
    for (const p of timedPhotos) {
      // No PHO:: point means the photo has no place on the timeline. Show it
      // below the revealed ones rather than never showing it at all.
      if (p.markTs == null) unplaced.push(p);
      else if (replayClock != null && p.markTs <= replayClock) reached.push(p);
    }
    return [...reached.reverse(), ...unplaced];
  }, [timedPhotos, mode, replayClock]);
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

  // Ground the front runner has ranged over recently — drives the cam zoom.
  // Measured from their CURRENT position (not the window's bounding box) because
  // the camera is centred on them, so what matters is the furthest thing behind
  // them that still has to fit on screen.
  const camSpreadMeters = useMemo(() => {
    if (mode !== "replay" || replayClock == null || !frontRunner) return null;
    const pts = trackUpTo(frontRunner.track.positions, replayClock);
    if (pts.length === 0) return null;
    const head = pts[pts.length - 1];
    let spread = 0;
    for (let i = pts.length - 1; i >= 0; i--) {
      if (replayClock - pts[i].timestampMs > FOLLOW_WINDOW_MS) break;
      const d = haversineMeters(head.lat, head.lng, pts[i].lat, pts[i].lng);
      if (d > spread) spread = d;
    }
    return spread;
  }, [mode, replayClock, frontRunner]);

  // e.g. "2.5 min" — generated so the panel can never claim a pace the constant
  // no longer sets.
  const replayPaceLabel = `${(REPLAY_MS_PER_KM / 60_000)
    .toFixed(1)
    .replace(/\.0$/, "")} min`;

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
        .tv-reveal-frame img { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: 10px; box-shadow: 0 4px 18px rgba(0,0,0,.6); }
        .tv-reveal-cap { flex: 0 0 auto; font-size: 15px; opacity: .85; text-align: center; }
        .tv-reveal-strip { flex: 0 0 14%; display: flex; gap: 8px; min-height: 0; }
        .tv-reveal-strip img { flex: 1 1 0; min-width: 0; height: 100%; object-fit: cover; border-radius: 8px; opacity: .6; }
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
            showLegend
          />
          <TvMapPanel
            tracks={tracks}
            users={rawUsers}
            cutoff={loopClock}
            center={center}
            label="THE RUN IN 10 SECONDS"
            markPx={overviewMarkPx}
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
              zoomSnap={0}
              zoomControl={false}
              attributionControl={false}
              dragging={false}
              scrollWheelZoom={false}
              doubleClickZoom={false}
              style={{ width: "100%", height: "100%", background: "#0c2a0e" }}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              <FollowCenter
                center={frontRunner ? [frontRunner.head.lat, frontRunner.head.lng] : null}
                spreadMeters={camSpreadMeters}
              />
              <TvMarks users={rawUsers} cutoff={replayClock} size={camMarkPx} />
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
                  /* eslint-disable-next-line @next/next/no-img-element */
                  <img
                    key={p.photoId}
                    src={photoSrc(p.url, 256)}
                    alt={p.title ?? "earlier run photo"}
                    onError={(e) => {
                      if (e.currentTarget.src !== p.url) e.currentTarget.src = p.url;
                    }}
                  />
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
                className={mode === "replay" ? "tv-photo-reveal" : undefined}
              >
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
