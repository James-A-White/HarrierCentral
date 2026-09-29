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
