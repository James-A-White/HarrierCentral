/**
 * A kennel's social and chat links (E12.F4.S4): HC.Kennel.SocialLinksJson,
 * a JSON array in display order.
 *
 * THE SAME platform → hosts list lives in FIVE places — change all together:
 *   - portal/lib/util/social_links.dart              (the editor; labels)
 *   - mobile-app/lib/util/social_links.dart          (the app's kennel page)
 *   - db/schema/functions/HC6.SocialLinksProblem.Function.sql  (the SP check)
 *   - api/Endpoints/KennelFromWebsite.cs             (SocialLinks)
 *   - public-web/lib/social-links.ts                 (this file)
 *
 * Pure: safe to import from server and client components alike.
 */

/** Chat-group invite links are what spammers harvest: members-only by default. */
const MEMBERS_BY_DEFAULT: ReadonlySet<string> = new Set([
  "whatsapp", "signal", "telegram", "wechat", "line", "kakaotalk", "zalo", "viber", "discord",
]);

export type SocialPlatform =
  | "facebook" | "instagram" | "whatsapp" | "signal" | "telegram" | "wechat" | "line"
  | "kakaotalk" | "zalo" | "viber" | "discord" | "strava" | "meetup" | "x" | "tiktok"
  | "youtube" | "threads" | "bluesky" | "reddit" | "mailinglist" | "googlecalendar" | "other";

export interface SocialLink {
  platform: SocialPlatform;
  /** https only. Null for a WeChat entry that has only an ID and/or a QR image. */
  url: string | null;
  /** WeChat ID. */
  handle: string | null;
  /** WeChat QR image, https only. */
  qrImageUrl: string | null;
  /** The kennel's own name for the link; required for "other". */
  label: string | null;
  audience: "public" | "members";
}

/** Every platform with its label and the hosts its links may point to (a host matches itself or any subdomain). */
export const SOCIAL_PLATFORMS: ReadonlyArray<readonly [SocialPlatform, string, readonly string[]]> = [
  ["facebook", "Facebook", ["facebook.com", "fb.com", "fb.me"]],
  ["instagram", "Instagram", ["instagram.com"]],
  ["whatsapp", "WhatsApp", ["whatsapp.com", "wa.me"]],
  ["signal", "Signal", ["signal.group", "signal.me"]],
  ["telegram", "Telegram", ["t.me", "telegram.me"]],
  ["wechat", "WeChat", ["weixin.qq.com", "wechat.com"]],
  ["line", "LINE", ["line.me", "lin.ee"]],
  ["kakaotalk", "KakaoTalk", ["kakao.com"]],
  ["zalo", "Zalo", ["zalo.me"]],
  ["viber", "Viber", ["viber.com"]],
  ["discord", "Discord", ["discord.gg", "discord.com"]],
  ["strava", "Strava", ["strava.com", "strava.app.link"]],
  ["meetup", "Meetup", ["meetup.com"]],
  ["x", "X (Twitter)", ["x.com", "twitter.com"]],
  ["tiktok", "TikTok", ["tiktok.com"]],
  ["youtube", "YouTube", ["youtube.com", "youtu.be"]],
  ["threads", "Threads", ["threads.net", "threads.com"]],
  ["bluesky", "Bluesky", ["bsky.app"]],
  ["reddit", "Reddit", ["reddit.com"]],
  ["mailinglist", "Mailing list", ["groups.google.com", "groups.io"]],
  ["googlecalendar", "Google Calendar", ["calendar.google.com"]],
  ["other", "Other", []],
];

const BY_ID = new Map(SOCIAL_PLATFORMS.map(([id, label, hosts]) => [id, { label, hosts }]));

export function socialPlatformLabel(platform: string): string {
  return BY_ID.get(platform as SocialPlatform)?.label ?? platform;
}

/** What a link is called on screen: the kennel's own label, else the platform's. */
export function socialLinkTitle(link: SocialLink): string {
  return link.label || socialPlatformLabel(link.platform);
}

function hostBelongs(host: string, hosts: readonly string[]): boolean {
  const h = host.toLowerCase();
  return hosts.some((x) => h === x || h.endsWith(`.${x}`));
}

function httpsUrl(v: unknown): URL | null {
  if (typeof v !== "string" || !v.trim()) return null;
  try {
    const u = new URL(v.trim());
    return u.protocol === "https:" && u.hostname ? u : null;
  } catch {
    return null;
  }
}

function text(v: unknown): string | null {
  return typeof v === "string" && v.trim() ? v.trim() : null;
}

/** One raw entry → a link we are willing to render, or null. Mirrors the portal's SocialLink.problem. */
function toLink(raw: unknown): SocialLink | null {
  if (!raw || typeof raw !== "object") return null;
  const r = raw as Record<string, unknown>;
  const platform = (typeof r.platform === "string" ? r.platform : "other") as SocialPlatform;
  const def = BY_ID.get(platform);
  if (!def) return null;

  const label = text(r.label);
  // A missing or odd audience takes the platform's default — chat groups are
  // members-only — the same rule as the portal and HC6.KennelSocialLinksVisible.
  const audience: "public" | "members" =
    r.audience === "members" || r.audience === "public"
      ? r.audience
      : MEMBERS_BY_DEFAULT.has(platform) ? "members" : "public";
  const url = httpsUrl(r.url);

  if (platform === "wechat") {
    const handle = text(r.handle);
    const qr = httpsUrl(r.qrImageUrl);
    const okUrl = url && hostBelongs(url.hostname, def.hosts) ? url.href : null;
    if (!okUrl && !handle && !qr) return null;
    return { platform, url: okUrl, handle, qrImageUrl: qr?.href ?? null, label, audience };
  }

  if (!url) return null;
  if (platform === "other") {
    if (!label) return null;
  } else if (!hostBelongs(url.hostname, def.hosts)) {
    return null;
  }
  return { platform, url: url.href, handle: null, qrImageUrl: null, label, audience };
}

/** Parses SocialLinksJson defensively: bad JSON ⇒ [], and every entry that fails the rules is dropped. */
export function parseSocialLinks(json: string | null | undefined): SocialLink[] {
  if (!json || !json.trim()) return [];
  try {
    const v: unknown = JSON.parse(json);
    if (!Array.isArray(v)) return [];
    return v.map(toLink).filter((l): l is SocialLink => l !== null);
  } catch {
    return [];
  }
}
