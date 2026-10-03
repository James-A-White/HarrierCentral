// A run's official (hare's) trail — E5.F6.S6, James 2026-10-03. One lane per
// trail type, held on the run itself (HC.Event.OfficialTrailGzip), not on any
// runner's attendance. The server hides it until the run has ended.
import { haversineMeters } from "@/lib/packtrack";

export interface OfficialTrailLane {
  /** Trail type: 1 Walkers, 2 Short, 3 Normal, 4 Long, 5 Ballbreaker, >= 100 kennel-defined. */
  type: number;
  /** [lat, lon] or [lat, lon, t] — t is ms after the lane's first point. */
  points: ([number, number] | [number, number, number])[];
}
export interface OfficialTrailLaneInfo {
  type: number;
  distanceM?: number;
  points?: number;
  source?: string;
  sourceRef?: string;
}
export interface OfficialTrail {
  lanes: OfficialTrailLane[];
  info: OfficialTrailLaneInfo[];
}

/** The app's built-in trail types (lib/data/models/trail_type/trail_type.dart). */
const TYPE_LABEL: Record<number, string> = { 1: "Walkers", 2: "Short", 3: "Normal", 4: "Long", 5: "Ballbreaker" };
const TYPE_COLOR: Record<number, string> = { 1: "#16a34a", 2: "#f59e0b", 3: "#dc2626", 4: "#7c3aed", 5: "#0f172a" };

export function laneLabel(type: number): string {
  return TYPE_LABEL[type] ?? "Trail";
}
export function laneColor(type: number): string {
  return TYPE_COLOR[type] ?? "#dc2626";
}

/** Length along the lane, metres. */
export function laneLengthM(lane: OfficialTrailLane): number {
  let m = 0;
  for (let i = 1; i < lane.points.length; i++) {
    const [aLat, aLng] = lane.points[i - 1];
    const [bLat, bLng] = lane.points[i];
    m += haversineMeters(aLat, aLng, bLat, bLng);
  }
  return m;
}

/** True when every point carries its time, so replay can animate the lane. */
export function laneIsTimed(lane: OfficialTrailLane): boolean {
  return lane.points.length >= 2 && lane.points.every(p => p.length >= 3 && typeof p[2] === "number");
}

/** The lane as plain [lat, lon] pairs. */
export function lanePath(lane: OfficialTrailLane): [number, number][] {
  return lane.points.map(p => [p[0], p[1]] as [number, number]);
}

/**
 * A timed lane up to `elapsedMs` after its first point — replay places that
 * first point at the first pack track's start (auto-align, James
 * 2026-10-03). Returns the path so far and the hare's position then, or null
 * for an untimed lane.
 */
export function laneUpTo(lane: OfficialTrailLane, elapsedMs: number): { path: [number, number][]; at: [number, number] } | null {
  if (!laneIsTimed(lane) || elapsedMs < 0) return null;
  const pts = lane.points as [number, number, number][];
  const path: [number, number][] = [];
  for (let i = 0; i < pts.length; i++) {
    const [lat, lon, t] = pts[i];
    if (t <= elapsedMs) { path.push([lat, lon]); continue; }
    if (i === 0) return null;
    const [pLat, pLon, pT] = pts[i - 1];
    const f = t > pT ? (elapsedMs - pT) / (t - pT) : 0;
    const at: [number, number] = [pLat + (lat - pLat) * f, pLon + (lon - pLon) * f];
    path.push(at);
    return { path, at };
  }
  return { path, at: path[path.length - 1] };
}

/** Normal first, then the rest by type, so the main trail leads every list. */
export function orderedLanes(lanes: OfficialTrailLane[]): OfficialTrailLane[] {
  return [...lanes].sort((a, b) => (a.type === 3 ? -1 : b.type === 3 ? 1 : a.type - b.type));
}

export async function fetchOfficialTrail(publicEventId: string): Promise<OfficialTrail> {
  try {
    const res = await fetch(`/api/official-trail?publicEventId=${encodeURIComponent(publicEventId)}`);
    if (!res.ok) return { lanes: [], info: [] };
    const data = (await res.json()) as OfficialTrail;
    return {
      lanes: (data.lanes ?? []).filter(l => Array.isArray(l.points) && l.points.length >= 2),
      info: data.info ?? [],
    };
  } catch {
    return { lanes: [], info: [] };
  }
}

const xmlEscape = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

/** The official trail as a GPX 1.1 file — one track per lane. */
export function officialTrailGpx(lanes: OfficialTrailLane[], name: string): string {
  const tracks = orderedLanes(lanes).map(l => {
    const pts = l.points.map(([lat, lon]) => `<trkpt lat="${lat}" lon="${lon}"/>`).join("");
    return `<trk><name>${xmlEscape(`${name} — ${laneLabel(l.type)}`)}</name><trkseg>${pts}</trkseg></trk>`;
  }).join("");
  return `<?xml version="1.0" encoding="UTF-8"?>\n<gpx version="1.1" creator="Harrier Central" xmlns="http://www.topografix.com/GPX/1/1"><metadata><name>${xmlEscape(name)}</name></metadata>${tracks}</gpx>\n`;
}

/** Saves the GPX in the browser — built here, so no server route is needed. */
export function downloadOfficialTrail(lanes: OfficialTrailLane[], name: string, fileName: string): void {
  const blob = new Blob([officialTrailGpx(lanes, name)], { type: "application/gpx+xml" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
