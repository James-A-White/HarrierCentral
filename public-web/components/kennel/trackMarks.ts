/**
 * Trail-mark rendering shared by the PackTrack map and Trail-TV: the
 * glyph/text/legacy-icon DivIcon builder and the "which marks are visible at
 * this cutoff" collector. Lives outside the components so both maps draw the
 * same yellow tiles from the same cache.
 */

import L from "leaflet";
import { parseMark, isTerminalOnInn, haversineMeters, MARK_DEDUPE_METERS } from "@/lib/packtrack";
import type { UserTrack, TrackPoint } from "@/lib/packtrack";

/** Checkpoint icon size (app uses 72; scaled down for the web embed). */
export const DEFAULT_ICON_PX = 40;

// Escape user-entered label text before interpolating into DivIcon HTML —
// labels are arbitrary hasher input on an unauthenticated public page.
export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// Checkpoint icon — PNG from the dynamic icon collection, with an optional
// label badge floated above (yellow, or red for Caution), matching the app.
const checkpointIconCache = new Map<string, L.DivIcon>();
// Yellow rounded tile (no border) for the new glyph/text marks, per
// docs/trail_markers/SPEC.md §4. Mono glyphs are tinted to the ink colour via a
// CSS mask; fixed-colour glyphs (e.g. Caution) render as-is; text stacks on spaces.
const TILE_YELLOW = "#fcff04";
const TILE_INK = "#2d0000";

function tileInnerHtml(m: MarkEntry, ICON_PX: number): string {
  if (m.text) {
    const lines = m.text.trim().split(" ").filter(l => l.length > 0);
    const longest = Math.max(1, ...lines.map(l => l.length));
    const inner = ICON_PX * 0.72;
    const fs = Math.max(
      6,
      Math.min(inner / (longest * 0.62), inner / (lines.length * 1.05), inner),
    );
    return lines
      .map(
        l =>
          `<div style="font:800 ${fs.toFixed(1)}px system-ui,sans-serif;` +
          `color:${TILE_INK};line-height:1.0">${escapeHtml(l)}</div>`,
      )
      .join("");
  }
  if (m.glyphFixed) {
    return `<img src="${m.glyphUrl}" style="width:100%;height:100%;object-fit:contain"/>`;
  }
  // Mono glyph — tint the silhouette to the ink colour via a mask.
  return (
    `<div style="width:100%;height:100%;background:${TILE_INK};` +
    `-webkit-mask:url('${m.glyphUrl}') center/contain no-repeat;` +
    `mask:url('${m.glyphUrl}') center/contain no-repeat"></div>`
  );
}

/**
 * Per-map tweaks to how a mark tile is drawn. Defaults reproduce the original
 * appearance exactly, so the PackTrack map is unaffected.
 */
export interface MarkIconOptions {
  /** Drop the floating label chip. Overview maps show the whole trail at once,
   *  where the chips are unreadable clutter that hides the track. */
  hideLabel?: boolean;
  /** Tile opacity (<1 lets the coloured track read through underneath). */
  opacity?: number;
}

export function checkpointIcon(
  m: MarkEntry,
  ICON_PX: number = DEFAULT_ICON_PX,
  opts: MarkIconOptions = {},
): L.DivIcon {
  const hideLabel = opts.hideLabel ?? false;
  const opacity = opts.opacity ?? 1;
  const isTile = !!(m.glyphUrl || m.text);
  const key = `${ICON_PX}|${hideLabel}|${opacity}|${m.iconUrl ?? ""}|${m.glyphUrl ?? ""}|${m.glyphFixed}|${m.text ?? ""}|${m.label ?? ""}|${m.isCaution}`;
  const cached = checkpointIconCache.get(key);
  if (cached) return cached;

  const badge = m.label && !hideLabel
    ? `<div style="position:absolute;bottom:${ICON_PX + 4}px;left:50%;transform:translateX(-50%);` +
      `background:${m.isCaution ? "#dc2626" : "#fef9c3"};color:${m.isCaution ? "#fff" : "#000"};` +
      `border:1.6px solid ${m.isCaution ? "#991b1b" : "#dc2626"};border-radius:6px;` +
      `padding:3px 6px;font:700 11px system-ui,sans-serif;line-height:1.25;white-space:normal;` +
      `max-width:140px;text-align:center;box-shadow:0 1px 4px rgba(0,0,0,0.4)">${escapeHtml(m.label)}</div>`
    : "";

  const inner = isTile
    ? `<div style="width:${ICON_PX}px;height:${ICON_PX}px;background:${TILE_YELLOW};` +
      `border-radius:${(ICON_PX * 0.22).toFixed(1)}px;padding:${(ICON_PX * 0.14).toFixed(1)}px;` +
      `box-sizing:border-box;display:flex;flex-direction:column;align-items:center;justify-content:center;` +
      `box-shadow:0 1px 4px rgba(0,0,0,0.4)">${tileInnerHtml(m, ICON_PX)}</div>`
    : `<img src="${m.iconUrl}" style="width:100%;height:100%;object-fit:contain;` +
      `filter:drop-shadow(0 1px 3px rgba(0,0,0,0.5))"/>`;

  const icon = L.divIcon({
    html:
      `<div style="position:relative;width:${ICON_PX}px;height:${ICON_PX}px` +
      `${opacity < 1 ? `;opacity:${opacity}` : ""}">${inner}${badge}</div>`,
    className: "",
    iconSize: [ICON_PX, ICON_PX],
    iconAnchor: [ICON_PX / 2, ICON_PX / 2],
  });
  checkpointIconCache.set(key, icon);
  return icon;
}

export interface MarkEntry {
  point: TrackPoint;
  rawType: string;
  iconUrl: string | null;
  glyphUrl: string | null;
  glyphFixed: boolean;
  text: string | null;
  label: string | null;
  isCaution: boolean;
}

// Gather visible (≤ cutoff) checkpoint marks across all runners, collapsing
// same-type marks within MARK_DEDUPE_METERS so multiple runners marking the same
// physical point render once. Photos are skipped (member-only on public web).
export function visibleMarks(users: UserTrack[], cutoff: number): MarkEntry[] {
  const kept: MarkEntry[] = [];
  for (const user of users) {
    for (const p of user.positions) {
      if (p.timestampMs > cutoff) break;
      const parsed = parseMark(p.type);
      // Drawable when it has a glyph, text, or a legacy flat icon (not a photo).
      if (!parsed || parsed.isPhoto) continue;
      if (!parsed.iconUrl && !parsed.glyphUrl && !parsed.text) continue;
      // Mid-track On-Inn (runner resumed after it) — ignored entirely.
      if (parsed.isOnInn && !isTerminalOnInn(user.positions, p)) continue;
      const rawType = (p.type ?? "").trim();
      const dup = kept.some(
        k => k.rawType === rawType &&
          haversineMeters(k.point.lat, k.point.lng, p.lat, p.lng) <= MARK_DEDUPE_METERS,
      );
      if (dup) continue;
      kept.push({
        point: p,
        rawType,
        iconUrl: parsed.iconUrl,
        glyphUrl: parsed.glyphUrl,
        glyphFixed: parsed.glyphFixed,
        text: parsed.text,
        label: parsed.label,
        isCaution: parsed.isCaution,
      });
    }
  }
  return kept;
}

