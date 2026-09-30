/**
 * What a chat message's content means for each kind (E9.F1.S11/S12).
 * Shared by the browser (drawing) and the server routes (checking), so no
 * server imports here.
 *
 * The rule itself lives in HC6.ChatMessageKindError, which every send SP
 * calls; the checks below mirror it so a bad message is refused before the
 * round trip, never instead of it. See docs/chat_photos_location_delete_plan.md.
 */

/** HC.EventMessage.MessageKind. Anything else is drawn as text. */
export const CHAT_KIND_TEXT = 0;
export const CHAT_KIND_PHOTO = 1;
export const CHAT_KIND_LOCATION = 2;
export type ChatMessageKind = typeof CHAT_KIND_TEXT | typeof CHAT_KIND_PHOTO | typeof CHAT_KIND_LOCATION;

/** Only photos in OUR chat-photos container count as photos. */
export const CHAT_PHOTO_PREFIX = "https://harriercentral.blob.core.windows.net/chat-photos/";
const MAPS_PREFIX = "https://www.google.com/maps/search/?api=1&query=";

export function isChatPhotoUrl(url: string): boolean {
  return url.length <= 500 && url.startsWith(CHAT_PHOTO_PREFIX) && url.endsWith(".jpg")
    && !/[\s?#]/.test(url) && !url.includes("..");
}

/** The coordinates in a location message, or null when it is not one. */
export function parseChatLocation(url: string): { lat: number; lng: number } | null {
  if (url.length > 100 || !url.startsWith(MAPS_PREFIX)) return null;
  const m = /^(-?\d{1,3}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)$/.exec(url.slice(MAPS_PREFIX.length));
  if (!m) return null;
  const lat = Number(m[1]), lng = Number(m[2]);
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 ? { lat, lng } : null;
}

/** At most 6 decimals, "." separator — what ChatMessageKindError's DECIMAL(9, 6) reads. */
function coord(n: number): string {
  return String(Number(n.toFixed(6)));
}

export function chatLocationUrl(lat: number, lng: number): string {
  return `${MAPS_PREFIX}${coord(lat)},${coord(lng)}`;
}

/** "51.50735, -0.12776" — five decimals is about a metre, which is plenty to read. */
export function formatChatLocation(p: { lat: number; lng: number }): string {
  return `${p.lat.toFixed(5)}, ${p.lng.toFixed(5)}`;
}

/** The kind to draw: an unknown kind, or content that does not fit its kind, is text. */
export function chatKindOf(kind: number | null | undefined, text: string): ChatMessageKind {
  if (kind === CHAT_KIND_PHOTO && isChatPhotoUrl(text)) return CHAT_KIND_PHOTO;
  if (kind === CHAT_KIND_LOCATION && parseChatLocation(text)) return CHAT_KIND_LOCATION;
  return CHAT_KIND_TEXT;
}

// ── Replies and reactions (E9.F1.S21/S22, 2026-09-30) ───────────────────────

/**
 * The fixed six reactions, in the order every client draws them. Stored by
 * CODE, never by glyph: in the database's collation an emoji compares equal
 * to '', so a code is the only key that can be looked up. Codes are the
 * JSON keys of HC.EventMessage.ReactionsJson.
 */
export const CHAT_REACTIONS: readonly { code: string; emoji: string; label: string }[] = [
  { code: "thumbs", emoji: "\u{1F44D}", label: "Thumbs up" },
  { code: "heart", emoji: "\u2764\uFE0F", label: "Heart" },
  { code: "laugh", emoji: "\u{1F602}", label: "Laugh" },
  { code: "beer", emoji: "\u{1F37A}", label: "Beer" },
  { code: "run", emoji: "\u{1F3C3}", label: "Runner" },
  { code: "fire", emoji: "\u{1F525}", label: "Fire" },
];

export const CHAT_REACTION_CODES: readonly string[] = CHAT_REACTIONS.map((r) => r.code);

export function reactionEmoji(code: string): string {
  return CHAT_REACTIONS.find((r) => r.code === code)?.emoji ?? code;
}

/**
 * `{"beer":["<PUBLICHASHERID>", …]}` → the same map with every id UPPER and
 * only the six known codes, in palette order. Anything unreadable is no
 * reactions at all, never a crash: the column is server-written JSON, but a
 * defensive parse costs nothing.
 */
export function parseReactions(json: string | null | undefined): Record<string, string[]> {
  const out: Record<string, string[]> = {};
  if (!json) return out;
  let raw: unknown;
  try { raw = JSON.parse(json); } catch { return out; }
  if (!raw || typeof raw !== "object") return out;
  for (const { code } of CHAT_REACTIONS) {
    const ids = (raw as Record<string, unknown>)[code];
    if (!Array.isArray(ids)) continue;
    const clean = ids.filter((x): x is string => typeof x === "string").map((x) => x.toUpperCase());
    if (clean.length) out[code] = clean;
  }
  return out;
}

/** What a quoted message reads as: its text, or a word for a photo or a location. */
export function quoteSnippet(kind: number | null | undefined, text: string | null | undefined): string {
  const t = text ?? "";
  if (kind === CHAT_KIND_PHOTO) return "\u{1F4F7} Photo";
  if (kind === CHAT_KIND_LOCATION) return "\u{1F4CD} Location";
  return t;
}
