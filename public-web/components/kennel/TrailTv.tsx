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
 * live → replay once tracks exist but nobody is on trail (the pack is home),
 * unless the mode was pinned by ?mode= or the on-screen toggle.
 */

import { Fragment, useState, useEffect, useRef, useMemo, useCallback } from "react";
import { MapContainer, TileLayer, Polyline, CircleMarker, Tooltip, useMap } from "react-leaflet";
import QRCode from "react-qr-code";
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
const REPLAY_MS_PER_KM = 60_000; // 1 minute of wall time per km of trail
const REPLAY_HOLD_MS = 6_000;
const TAKEOVER_LIVE_MS = 10_000;  // fresh-from-trail photo, live mode
const TAKEOVER_REPLAY_MS = 4_000;  // synced photo on the replay timeline
const CALLOUT_MS = 6_000;
const ACTIVE_WINDOW_MS = 10 * 60_000; // "on trail" = a point in the last 10 min
const FOLLOW_ZOOM = 17.5;
const FOLLOW_SPRING_OMEGA = 3; // rad/s — camera spring stiffness; lower = floatier follow-cam
const LEAD_HYSTERESIS_METERS = 15; // new leader must be this far ahead to steal the cam

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
function FollowCenter({ center }: { center: [number, number] | null }) {
  const map = useMap();
  const target = useRef<[number, number] | null>(null);
  const cam = useRef<{ lat: number; lng: number; vLat: number; vLng: number } | null>(null);
  useEffect(() => {
    target.current = center;
  }, [center]);
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
        map.setView(tgt, FOLLOW_ZOOM, { animate: false });
        return;
      }
      const c = cam.current;
      const w = FOLLOW_SPRING_OMEGA;
      // accel = ω²·(target − pos) − 2ω·vel (critical damping — no overshoot)
      c.vLat += ((tgt[0] - c.lat) * w * w - 2 * w * c.vLat) * dt;
      c.vLng += ((tgt[1] - c.lng) * w * w - 2 * w * c.vLng) * dt;
      c.lat += c.vLat * dt;
      c.lng += c.vLng * dt;
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
  }, [map]);
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
  tracks, cutoff, center, label, sublabel, style, names, showLegend = false,
}: {
  tracks: PreparedTrack[];
  cutoff: number | null;
  center: [number, number];
  label: string;
  sublabel?: string | null;
  style?: React.CSSProperties;
  /** When provided, head dots get permanent name-chip labels. */
  names?: Record<string, string>;
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

  const [tracks, setTracks] = useState<PreparedTrack[]>([]);
  const [markCount, setMarkCount] = useState(0);
  const [names, setNames] = useState<Record<string, string>>({});
  const [photos, setPhotos] = useState<PhotoEntry[]>([]);
  const [takeover, setTakeover] = useState<PhotoEntry | null>(null);
  const [callouts, setCallouts] = useState<Callout[]>([]);
  const [nowTick, setNowTick] = useState(Date.now());
  const [loopClock, setLoopClock] = useState<number | null>(null);
  const [replayClock, setReplayClock] = useState<number | null>(null);

  const knownPhotoIds = useRef<Set<string> | null>(null);
  const lastMarkTs = useRef<number>(0);
  const firstTrackLoad = useRef(true);
  const photoMarkTs = useRef<Map<string, number>>(new Map());
  const calloutKey = useRef(0);
  const replayFiredPhotos = useRef<Set<string>>(new Set());
  const takeoverActiveRef = useRef(false);

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
    setTracks(prepared);

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
      const entries: PhotoEntry[] = Object.entries(map).map(([photoId, p]) => ({
        ...p, photoId, markTs: photoMarkTs.current.get(photoId) ?? null,
      }));
      entries.sort((a, b) => (a.markTs ?? 0) - (b.markTs ?? 0));
      setPhotos(entries);

      if (knownPhotoIds.current == null) {
        knownPhotoIds.current = new Set(entries.map((e) => e.photoId));
      } else if (mode === "live") {
        for (const e of entries) {
          if (!knownPhotoIds.current.has(e.photoId)) {
            knownPhotoIds.current.add(e.photoId);
            setTakeover(e);
            setTimeout(() => setTakeover((cur) => (cur?.photoId === e.photoId ? null : cur)), TAKEOVER_LIVE_MS);
          }
        }
      } else {
        for (const e of entries) knownPhotoIds.current.add(e.photoId);
      }
    };
    load();
    const t = setInterval(load, mode === "live" ? PHOTO_POLL_MS : 3 * PHOTO_POLL_MS);
    return () => { cancelled = true; clearInterval(t); };
  }, [publicEventId, mode]);

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

  // First finisher (earliest terminal On-Inn; else the longest track) sets
  // the replay pace: one minute of wall time per km of their trail.
  const replayDurationMs = useMemo(() => {
    if (tracks.length === 0) return 60_000;
    const finished = tracks.filter((t) => t.finishTs != null);
    const pacer = finished.length > 0
      ? finished.reduce((a, b) => ((a.finishTs ?? 0) <= (b.finishTs ?? 0) ? a : b))
      : tracks.reduce((a, b) => (a.distanceMeters >= b.distanceMeters ? a : b));
    return Math.max(60_000, (pacer.distanceMeters / 1000) * REPLAY_MS_PER_KM);
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
  }, [takeover]);

  // Paced replay clock + photo sync. 200ms steps: per-tick track math is
  // too heavy for requestAnimationFrame and 5Hz is smooth enough on a wall.
  // While a photo takeover is on screen the clock FREEZES (start shifts
  // forward by each skipped step) so the replay pauses behind the photo.
  useEffect(() => {
    if (mode !== "replay" || !timeline) return;
    let start = performance.now();
    replayFiredPhotos.current = new Set();
    const t = setInterval(() => {
      if (takeoverActiveRef.current) {
        start += 200; // hold the replay while the photo shows
        return;
      }
      const cycle = replayDurationMs + REPLAY_HOLD_MS;
      const el = (performance.now() - start) % cycle;
      if (el < 250) replayFiredPhotos.current = new Set(); // new cycle — re-arm takeovers
      const frac = Math.min(1, el / replayDurationMs);
      setReplayClock(timeline.min + frac * (timeline.max - timeline.min));
    }, 200);
    return () => clearInterval(t);
  }, [mode, timeline, replayDurationMs]);

  // Replay photo takeovers: fire as the replay clock passes each capture time.
  useEffect(() => {
    if (mode !== "replay" || replayClock == null) return;
    if (takeover != null) return; // let the current takeover finish first
    for (const p of photos) {
      if (p.markTs != null && p.markTs <= replayClock && !replayFiredPhotos.current.has(p.photoId)) {
        replayFiredPhotos.current.add(p.photoId);
        setTakeover(p);
        setTimeout(() => setTakeover((cur) => (cur?.photoId === p.photoId ? null : cur)), TAKEOVER_REPLAY_MS);
        break; // one at a time
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [replayClock, mode]);

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
  // a position in the last ACTIVE_WINDOW_MS. The 24h-after-start rule alone
  // left the morning-after screen in live mode (no front-runner cam, no
  // photo takeovers) until the following evening.
  useEffect(() => {
    if (modePinned.current || mode !== "live" || tracks.length === 0) return;
    if (stats.active === 0) setMode("replay");
  }, [mode, tracks.length, stats.active]);

  const carouselRef = useRef<HTMLDivElement | null>(null);
  const marqueeRef = useRef<HTMLDivElement | null>(null);
  const [marqueeAnimated, setMarqueeAnimated] = useState(false);
  const [imgLoadTick, setImgLoadTick] = useState(0);

  // Animate the carousel only when the single photo list truly overflows the
  // panel. scrollHeight counts the duplicated list when animating, so halve it
  // in that case before comparing.
  useEffect(() => {
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
  }, [photos, imgLoadTick, marqueeAnimated]);

  const carouselPhotos = photos.length > 0 ? photos : [];
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
        .tv-empty { position:absolute; inset:0; display:flex; align-items:center; justify-content:center; flex-direction:column; gap:12px; opacity:.75; font-size:20px; text-align:center; padding:30px; }
        .tv-ticker { grid-column: 1 / -1; display: flex; align-items: center; gap: 28px; background: rgba(12,42,14,.9); border: 1px solid rgba(255,255,255,.18); border-radius: 14px; padding: 0 22px; font-size: 17px; overflow: hidden; white-space: nowrap; }
        .tv-stat b { color: #e0a51e; font-size: 21px; margin-right: 6px; }
        .tv-brand { font-weight: 800; letter-spacing: .04em; margin-right: auto; }
        .tv-qr { display:flex; align-items:center; gap:10px; background:#fff; border-radius:8px; padding:4px; }
        .tv-qr-caption { font-size: 13px; opacity:.9; }
        .tv-takeover { position: fixed; inset: 0; z-index: 5000; background: rgba(0,0,0,.88); display: flex; align-items: center; justify-content: center; flex-direction: column; gap: 14px; animation: tvzoom .5s ease-out; }
        @keyframes tvzoom { from { transform: scale(.6); opacity: 0 } to { transform: scale(1); opacity: 1 } }
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
            cutoff={null}
            center={center}
            label="LIVE"
            sublabel={`${stats.active} on trail`}
            names={names}
            showLegend
          />
          <TvMapPanel
            tracks={tracks}
            cutoff={loopClock}
            center={center}
            label="THE RUN IN 10 SECONDS"
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
              zoomSnap={0.5}
              zoomControl={false}
              attributionControl={false}
              dragging={false}
              scrollWheelZoom={false}
              doubleClickZoom={false}
              style={{ width: "100%", height: "100%", background: "#0c2a0e" }}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
              <FollowCenter center={frontRunner ? [frontRunner.head.lat, frontRunner.head.lng] : null} />
              {tracks.map((t) => trackPolyline(t, replayClock, names[t.id]))}
            </MapContainer>
          </div>
          <TvMapPanel
            tracks={tracks}
            cutoff={replayClock}
            center={center}
            label="RUN REPLAY"
            sublabel={`1 min / km · ${formatDistanceLabel(tracks.reduce((m, t) => Math.max(m, t.distanceMeters), 0))} trail`}
          />
        </>
      )}

      {/* ── Right column: photo carousel ── */}
      <div className="tv-carousel" ref={carouselRef}>
        {marqueeList.length === 0 ? (
          <div className="tv-empty">
            <div style={{ fontSize: 44 }}>📸</div>
            <div>Waiting for the first photo from trail…</div>
            <div style={{ fontSize: 14, opacity: 0.7 }}>
              Hash Flash photos appear here moments after they&apos;re taken
            </div>
          </div>
        ) : (
          <div ref={marqueeRef} className="tv-marquee">
            {marqueeList.map((p, i) => (
              <div key={`${p.photoId}-${i}`}>
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
        <div className="tv-takeover" onClick={() => setTakeover(null)}>
          <div className="tv-takeover-badge">📸 FRESH FROM TRAIL</div>
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
