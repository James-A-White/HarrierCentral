/**
 * Server-side calls behind the member sign-in and RSVP (E9.F7).
 *
 * Three doors into the same Azure Function app:
 *  - AppApiHC6         — the app's own shim; the browser is a device, so it
 *                        calls hcapp_ SPs with device tokens like a phone.
 *  - EmailInviteCode   — emails the six-letter invite code (the app's own
 *                        "re-connect" mechanism), no auth, rate-limited here.
 *  - PublicWebAdminApi — publicWeb_ SPs behind X-Internal-Secret.
 *
 * Server only.
 */
import { GUID_EMPTY, hcToken, type MemberSession } from "@/lib/member-session";
import type { Song } from "@/lib/api";
import { CHAT_KIND_TEXT, type ChatMessageKind } from "@/lib/chat-content";

const API_BASE = process.env.HC_API_URL ?? "http://localhost:7071";
const WEB_VERSION = "<web>";

type Row = Record<string, unknown>;
type Rowsets = Row[][];

/** The write-SP envelope every hcapp_ / publicWeb_ write returns in rowset 0. */
export interface Envelope {
  success: number;
  errorCode?: number;
  errorType?: number;
}

function envelopeOf(rowsets: Rowsets): Envelope {
  const r = rowsets?.[0]?.[0] as unknown as Envelope | undefined;
  return r ?? { success: 0 };
}

export function userMessageOf(rowsets: Rowsets): string {
  const r = rowsets?.[1]?.[0] as { errorUserMessage?: string } | undefined;
  return r?.errorUserMessage ?? "Something went wrong. Please try again.";
}

/** publicWeb_<queryType> via the admin shim. Every value is sent as a string — the shim reads strings only. */
export async function callAdminApi(queryType: string, params: Record<string, string | null>): Promise<Rowsets> {
  const res = await fetch(`${API_BASE}/api/PublicWebAdminApi`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Internal-Secret": process.env.HC_INTERNAL_SECRET ?? "",
    },
    body: JSON.stringify({ queryType, ...params }),
    cache: "no-store",
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`PublicWebAdminApi ${queryType}: ${res.status} ${text.slice(0, 200)}`);
  }
  return (await res.json()) as Rowsets;
}

/** hcapp_<queryType> via the app shim. */
export async function callAppApi(body: Record<string, unknown>): Promise<Rowsets> {
  const res = await fetch(`${API_BASE}/api/AppApiHC6`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    cache: "no-store",
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`AppApiHC6 ${String(body.queryType)}: ${res.status} ${text.slice(0, 200)}`);
  // The shim turns an SP error into a flat object in some paths; normalise to rowsets.
  const parsed = JSON.parse(text) as unknown;
  if (Array.isArray(parsed)) return parsed as Rowsets;
  const flat = parsed as Row;
  return [[{ success: 0, errorCode: flat.errorCode, errorType: flat.errorType }], [flat]];
}

// ── Email code ────────────────────────────────────────────────────────────────

/** Emails the invite code. Returns whether the address matched a live hasher. */
export async function emailInviteCode(email: string): Promise<boolean> {
  const res = await fetch(`${API_BASE}/api/EmailInviteCode`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email }),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`EmailInviteCode: ${res.status}`);
  return res.headers.get("x-invite-code-sent") === "true";
}

export interface ProvisionedDevice {
  session: MemberSession;
}

/**
 * Turns an emailed code into a device: hcapp_authorizeDevice with the
 * 'URC:' scan text, under the global pre-auth token, exactly as a fresh
 * install of the app does — except IsMobile = 0.
 */
export async function authorizeBrowserByCode(
  code: string,
  deviceId: string,
  deviceData: object,
  remembered: boolean,
): Promise<{ session?: MemberSession; error?: string }> {
  const rowsets = await callAppApi({
    queryType: "authorizeDevice",
    deviceId,
    accessToken: hcToken(GUID_EMPTY, "hcapp_authorizeDevice"),
    hcVersion: WEB_VERSION,
    scanText: `URC:${code.trim().toUpperCase()}`,
    deviceData: JSON.stringify(deviceData),
    isMobile: 0,
  });
  const env = envelopeOf(rowsets);
  if (env.success !== 1) return { error: userMessageOf(rowsets) };
  const p = rowsets[1]?.[0] as Row;
  return {
    session: {
      userId: String(p.hasherId).toLowerCase(),
      deviceId: deviceId.toLowerCase(),
      deviceSecret: String(p.deviceSecret),
      timeWindow: Number(p.timeWindow) || 30,
      hashName: String(p.hashName ?? ""),
      displayName: String(p.displayName ?? ""),
      photo: String(p.photo ?? ""),
      remembered,
    },
  };
}

// ── QR sign-in ────────────────────────────────────────────────────────────────

/** Polls publicWeb_confirmAuthentication. Null until the phone has scanned. */
export async function confirmQrAuthentication(
  deviceId: string,
  scanData: string,
  deviceData: object,
  remembered: boolean,
): Promise<MemberSession | null> {
  const rowsets = await callAdminApi("confirmAuthentication", {
    newDeviceId: deviceId,
    qrCodeData: scanData,
    deviceInfo: JSON.stringify(deviceData),
  });
  const p = rowsets?.[0]?.[0];
  if (!p || !p.deviceSecret) return null;
  return {
    userId: String(p.hasherId).toLowerCase(),
    deviceId: deviceId.toLowerCase(),
    deviceSecret: String(p.deviceSecret),
    timeWindow: Number(p.timeWindow) || 30,
    hashName: String(p.hashName ?? ""),
    displayName: String(p.displayName ?? ""),
    photo: String(p.photo ?? ""),
    remembered,
  };
}

// ── Signup ────────────────────────────────────────────────────────────────────

export async function createMember(p: {
  email: string; hashName: string; firstName?: string; lastName?: string; kennelSlug: string;
}): Promise<{ ok: true } | { ok: false; duplicate: boolean; message: string }> {
  const rowsets = await callAdminApi("createMember", {
    email: p.email,
    hashName: p.hashName,
    firstName: p.firstName ?? null,
    lastName: p.lastName ?? null,
    kennelSlug: p.kennelSlug,
  });
  const env = envelopeOf(rowsets);
  if (env.success === 1) return { ok: true };
  return { ok: false, duplicate: env.errorCode === 10005, message: userMessageOf(rowsets) };
}

// ── RSVP + pack ───────────────────────────────────────────────────────────────

export async function setRunRsvp(s: MemberSession, publicEventId: string, rsvpState: 1 | 2 | 3): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("setRunRsvp", {
    deviceId: s.deviceId,
    // The inner SP validates the token, so it is generated for ITS name.
    accessToken: hcToken(s.userId, "hcapp_setEventRsvp", { paramString: s.deviceSecret, timeWindow: s.timeWindow }),
    publicEventId,
    rsvpState: String(rsvpState),
  });
  const env = envelopeOf(rowsets);
  if (env.success === 1) {
    const r = rowsets[1]?.[0] as { serverMessage?: string } | undefined;
    return { ok: true, message: r?.serverMessage || undefined };
  }
  return { ok: false, message: userMessageOf(rowsets) };
}

export interface PackMember {
  hasherId: string;
  name: string;
  photo: string;
  rsvpState: number;
  attendenceState: number;
  isHare: number;
}

export interface RunPack {
  me: { hasherId: string; hashName: string; rsvpState: number; attendenceState: number; isHare: number; isPast: number };
  pack: PackMember[];
}

export async function getRunPack(s: MemberSession, publicEventId: string): Promise<RunPack | null> {
  const rowsets = await callAdminApi("getRunPack", {
    deviceId: s.deviceId,
    accessToken: hcToken(s.userId, "publicWeb_getRunPack", { paramString: s.deviceSecret, timeWindow: s.timeWindow }),
    publicEventId,
  });
  if (envelopeOf(rowsets).success !== 1) return null;
  const me = rowsets[1]?.[0] as RunPack["me"] | undefined;
  if (!me) return null;
  return { me, pack: (rowsets[2] ?? []) as unknown as PackMember[] };
}

// ── The five tabs (E9.F7.S5/S8/S9/S10/S11) ────────────────────────────────────

/** publicWeb_getMyRuns row: the GlobalRunRow shape plus My* columns. */
export interface MyRun {
  PublicEventId: string;
  EventNumber: number;
  EventName: string;
  EventStartDatetime: string;
  EventEndDatetime: string | null;
  EventStartDatetimeGmt: string | null;
  KennelIANATimezone: string | null;
  EventTypeName: string | null;
  EventPriceForMembers: number | null;
  EventPriceForNonMembers: number | null;
  EventCurrencyType: string | null;
  Hares: string | null;
  LocationOneLineDesc: string | null;
  LocationStreet: string | null;
  LocationCity: string | null;
  LocationPostCode: string | null;
  LocationRegion: string | null;
  LocationCountry: string | null;
  Latitude: number | null;
  Longitude: number | null;
  EventDescription: string | null;
  EventImage: string | null;
  EventUrl: string | null;
  IsCountedRun: number;
  KennelSlug: string;
  KennelShortName: string;
  KennelName: string;
  KennelLogo: string | null;
  PrimaryColor: string | null;
  AccentColor: string | null;
  PublicKennelId: string;
  KennelWebsiteDomain: string | null;
  MyRsvpState: number;
  MyAttendenceState: number;
  MyIsHare: number;
  MyNotificationPref: number;
  MyEmailAlertPref: number;
  Following: number;
  IsMember: number;
  IsPast: number;
  GoingCount: number;
  TrackRunnerCount: number | null;
  PhotoCount: number | null;
  MessageCount: number | null;
  DownDownCount: number | null;
  DistanceUnitsPref: number;
  /** The hasher's own preference bitfield: 0x03 unit, 0x3C >> 2 radius rung. */
  HasherPreferences: number;
  EventGeographicScope: number | null;
  EventType: string | null;
}

export interface MyKennel {
  PublicKennelId: string;
  KennelSlug: string;
  KennelShortName: string;
  KennelName: string;
  KennelLogo: string | null;
  KennelCoverPhoto: string | null;
  KennelStatus: number | null;
  City: string | null;
  Region: string | null;
  Country: string | null;
  /** The app's location line: city, region when the country shows it, country. */
  Location: string;
  CityLat: number | null;
  CityLon: number | null;
  KennelWebsiteDomain: string | null;
  /** 1 when I have a HasherKennelMap row here (the app shows counts and chat only then). */
  HasHkm: number;
  /** 0 auto (within N km) · 1 always · 2 never — the app's EnumFollowType. */
  Following: number;
  IsHomeKennel: number;
  IsMember: number;
  /** 0 auto · 1 on · 2 ignore · 3 mute · 4 on before the run. */
  KennelNotificationPref: number;
  /** 0 default · 1 on · 2 off. */
  KennelEmailAlertPref: number;
  MembershipExpirationDate: string | null;
  MemberSince: string | null;
  DateOfLastRun: string | null;
  Runs: number;
  Haring: number;
  IsEstimate: number;
  KennelDescription: string | null;
  KennelWebsiteUrl: string | null;
  KennelMismanagementTeam: string | null;
  MessagingGroupInviteUrl: string | null;
  DefaultMessagingPlatform: number;
  AllowSelfPayment: number;
  KennelCredit: number;
  CurrencySymbol: string | null;
  DigitsAfterDecimal: number;
  DistanceUnitsPref: number;
  /** The caller's own HC.Hasher.Preferences (publicWeb_getMyKennels v3). */
  HasherPreferences?: number;
  DefaultPriceMembers: number;
  DefaultPriceNonMembers: number;
  ExcludeFromLeaderboard: number;
  LastRunGmt: string | null;
  LastRunLocal: string | null;
  LastRunNumber: number | null;
  NextRunGmt: string | null;
  NextRunLocal: string | null;
  NextRunNumber: number | null;
  NextRunName: string | null;
  NextRunPublicEventId: string | null;
  /** Lower-cased, space-led words for the app's comma / plus / not search. */
  SearchText: string;
}

/** publicWeb_getLeaderboard row — the app's LeaderboardModel plus the home kennel's name. */
export interface LeaderboardRow {
  displayName: string; totalRunCount: number; totalHaringCount: number; ytdTotalRunCount: number; ytdHaringCount: number;
  rollingYearTotalRunCount: number; rollingYearHaringCount: number; isHomeKennel: number; homeKennelShortName: string | null; isMe: number;
}

/** publicWeb_getKennelArt row — a run with an event image. */
export interface KennelArtRow {
  PublicEventId: string; EventNumber: number | null; EventName: string; EventImage: string; EventStartDatetime: string; EventStartDatetimeGmt: string; KennelSlug: string;
}

export interface HistoryTotals { Runs: number; Haring: number; Kennels: number; IsEstimate: number }
export interface HistoryKennel {
  PublicKennelId: string; KennelSlug: string; KennelShortName: string; KennelName: string; KennelLogo: string | null;
  TotalRuns: number; TotalHaring: number; HcRuns: number; HcHaring: number; HistoricalRuns: number; HistoricalHaring: number;
  IsEstimate: number; Following: number; KennelCredit: number; DigitsAfterDecimal: number; CurrencySymbol: string;
}
export interface HistoryCountry {
  CountryId: string; CountryName: string; CountryCode: string | null; FlagFile: string | null; RunCount: number; HareCount: number;
}
export interface MyHistory { totals: HistoryTotals; kennels: HistoryKennel[]; countries: HistoryCountry[] }

/** publicWeb_getMyRunsFor row — the app's UserRunHistoryModel. */
export interface HistoryRunRow {
  totalRunsThisKennel: number | null; totalHaringThisKennel: number | null;
  publicEventId: string; eventName: string; eventNumber: number;
  countryName: string; flagFile: string | null; countryCode: string | null;
  kennelName: string; kennelShortName: string; kennelSlug: string; kennelLogo: string | null;
  digitsAfterDecimal: number; currencySymbol: string; eventStartDatetime: string;
  extrasDescription: string | null; extrasPrice: number | null; hemId: string | null;
  attendenceState: number; isHare: number;
  creditAmount: number | null; debitAmount: number | null; creditAvailable: number | null; paymentType: number | null; doPayForExtras: number | null;
}
export interface HistoryRunsHeader {
  Kind: "kennel" | "country";
  PublicKennelId: string | null; KennelSlug: string | null; KennelShortName: string | null; KennelName: string | null; KennelLogo: string | null;
  HcRuns: number | null; HcHaring: number | null; HistoricalRuns: number | null; HistoricalHaring: number | null; IsEstimate: number | null;
  KennelCredit: number | null; DigitsAfterDecimal: number | null; CurrencySymbol: string | null;
  CountryId: string | null; CountryName: string | null; FlagFile: string | null;
}
export interface HistoryRuns { header: HistoryRunsHeader | null; runs: HistoryRunRow[] }

export interface KennelSearchRow {
  PublicKennelId: string; KennelSlug: string; KennelShortName: string; KennelName: string; KennelLogo: string | null;
  KennelStatus: number | null; City: string | null; Region: string | null; Country: string | null; LastRunGmt: string | null;
}

function tokenFor(s: MemberSession, proc: string): string {
  return hcToken(s.userId, proc, { paramString: s.deviceSecret, timeWindow: s.timeWindow });
}

export async function getMyRuns(s: MemberSession): Promise<MyRun[]> {
  const rowsets = await callAdminApi("getMyRuns", { deviceId: s.deviceId, accessToken: tokenFor(s, "publicWeb_getMyRuns") });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as MyRun[];
}

export async function getMyKennels(s: MemberSession): Promise<MyKennel[]> {
  const rowsets = await callAdminApi("getMyKennels", { deviceId: s.deviceId, accessToken: tokenFor(s, "publicWeb_getMyKennels") });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as MyKennel[];
}

export async function getMyHistory(s: MemberSession): Promise<MyHistory | null> {
  const rowsets = await callAdminApi("getMyHistory", { deviceId: s.deviceId, accessToken: tokenFor(s, "publicWeb_getMyHistory") });
  if (envelopeOf(rowsets).success !== 1) return null;
  const t = (rowsets[1]?.[0] ?? {}) as Partial<HistoryTotals>;
  return {
    totals: { Runs: Number(t.Runs) || 0, Haring: Number(t.Haring) || 0, Kennels: Number(t.Kennels) || 0, IsEstimate: Number(t.IsEstimate) || 0 },
    kennels: (rowsets[2] ?? []) as unknown as HistoryKennel[],
    countries: (rowsets[3] ?? []) as unknown as HistoryCountry[],
  };
}

export async function getMyRunsFor(s: MemberSession, p: { publicKennelId?: string; countryId?: string; allRuns: boolean }): Promise<HistoryRuns | null> {
  const rowsets = await callAdminApi("getMyRunsFor", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "publicWeb_getMyRunsFor"),
    publicKennelId: p.publicKennelId ?? null,
    countryId: p.countryId ?? null,
    allRuns: p.allRuns ? "1" : "0",
  });
  if (envelopeOf(rowsets).success !== 1) return null;
  return { header: ((rowsets[1]?.[0] as unknown as HistoryRunsHeader) ?? null), runs: (rowsets[2] ?? []) as unknown as HistoryRunRow[] };
}

/**
 * The app's kennel-card popup, through hcapp_joinKennel in self mode:
 * following 0 (within N km) · 1 (always) · 2 (never); isHomeKennel 1 sets,
 * 0 clears. Either may be omitted to keep it.
 */
export async function setKennelFollowing(s: MemberSession, publicKennelId: string, p: { following?: 0 | 1 | 2; isHomeKennel?: 0 | 1 }): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("setKennelFollowing", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_joinKennel"),
    publicKennelId,
    following: p.following == null ? null : String(p.following),
    isHomeKennel: p.isHomeKennel == null ? null : String(p.isHomeKennel),
  });
  return envelopeOf(rowsets).success === 1 ? { ok: true } : { ok: false, message: userMessageOf(rowsets) };
}

/**
 * The bell and the envelope (E9.F7.S14), through the app's own
 * hcapp_setEmailAndNotificationPrefs: one of a kennel or a run;
 * notification 0 auto · 1 on · 2 ignore · 3 mute · 4 before the run;
 * email 1 on · 2 off; -1 (or omitted) leaves it as it is.
 */
export async function setNotificationPrefs(s: MemberSession, p: { publicKennelId?: string; publicEventId?: string; notification?: number; email?: number }): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("setNotificationPrefs", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_setEmailAndNotificationPrefs"),
    publicKennelId: p.publicKennelId ?? null,
    publicEventId: p.publicEventId ?? null,
    notificationPreference: String(p.notification ?? -1),
    emailPreference: String(p.email ?? -1),
  });
  return envelopeOf(rowsets).success === 1 ? { ok: true } : { ok: false, message: userMessageOf(rowsets) };
}

/** One passkey on the signed-in hasher's account (E9.F7.S18). The credential
 * id and public key are deliberately NOT returned by the SP — a settings
 * screen has no use for them. */
export type Passkey = {
  DeviceId: string;
  Label: string;
  Platform: string;
  IsThisDevice: number;
  LastLogin: string | null;
  IsMobile: number;
  /** E9.F7.S19. A row that is BOTH signed out and passkey-free is not
   *  returned at all — it can no longer reach the account by any route. */
  HasPasskey?: number;
  IsSignedOut?: number;
  /** What the device was running when it last signed in. Null for the 564
   *  rows platform-wide that never reported one. */
  AppVersion?: string | null;
  AppBuild?: string | null;
};

/** Every device that can reach this account. Supersedes listPasskeys. */
export async function listDevices(s: MemberSession): Promise<Passkey[]> {
  const rowsets = await callAdminApi("listDevices", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_listDevices"),
  });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as Passkey[];
}

/** Cuts one device off — the server rotates its secret, which is the
 *  revocation, and drops its push tokens. Returns what is left. */
export async function signOutDevice(
  s: MemberSession,
  targetDeviceId: string,
): Promise<{ ok: boolean; message?: string; remaining: Passkey[] }> {
  const rowsets = await callAdminApi("signOutDevice", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_signOutDevice"),
    targetDeviceId,
  });
  if (envelopeOf(rowsets).success !== 1) {
    return { ok: false, message: userMessageOf(rowsets), remaining: [] };
  }
  return { ok: true, remaining: (rowsets[1] ?? []) as unknown as Passkey[] };
}

export async function listPasskeys(s: MemberSession): Promise<Passkey[]> {
  const rowsets = await callAdminApi("listPasskeys", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_listPasskeys"),
  });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as Passkey[];
}

/** Removes one passkey and returns what is left, so the caller repaints from
 * the reply rather than asking again. */
export async function deletePasskey(
  s: MemberSession,
  targetDeviceId: string,
): Promise<{ ok: boolean; message?: string; remaining: Passkey[] }> {
  const rowsets = await callAdminApi("deletePasskey", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "hcapp_deletePasskey"),
    targetDeviceId,
  });
  if (envelopeOf(rowsets).success !== 1) {
    return { ok: false, message: userMessageOf(rowsets), remaining: [] };
  }
  return { ok: true, remaining: (rowsets[1] ?? []) as unknown as Passkey[] };
}

export async function getLeaderboard(s: MemberSession, publicKennelId: string): Promise<LeaderboardRow[]> {
  const rowsets = await callAdminApi("getLeaderboard", { deviceId: s.deviceId, accessToken: tokenFor(s, "publicWeb_getLeaderboard"), publicKennelId });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as LeaderboardRow[];
}

export async function getKennelArt(s: MemberSession, publicKennelId: string): Promise<KennelArtRow[]> {
  const rowsets = await callAdminApi("getKennelArt", { deviceId: s.deviceId, accessToken: tokenFor(s, "publicWeb_getKennelArt"), publicKennelId });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as KennelArtRow[];
}

/** Public directory search through the anonymous GET shim. */
export async function searchKennels(q: string): Promise<KennelSearchRow[]> {
  const url = new URL(`${API_BASE}/api/PublicWebApi`);
  url.searchParams.set("queryType", "searchKennels");
  url.searchParams.set("q", q);
  const res = await fetch(url.toString(), { cache: "no-store" });
  if (!res.ok) return [];
  const rowsets = (await res.json()) as Rowsets;
  return (rowsets?.[0] ?? []) as unknown as KennelSearchRow[];
}

// ── Chat (E9.F7.S15) — the app's own message SPs behind publicWeb_ wrappers ──

/** "dm" is a direct message between two hashers (E9.F1.S7); its id is the ThreadId. */
export type ChatKind = "run" | "kennel" | "room" | "dm";

/** hcapp_getEventBadgeCount list mode — one row per run, kennel, room or DM thread. */
export interface ChatThreadRow {
  BadgeCount: number; PublicEventId: string | null; EventName: string | null; EventNumber: number | null;
  EventStartDatetimeGmt: string | null; EventImage: string | null; PublicKennelId: string | null;
  KennelShortName: string | null; KennelLogo: string | null; MessageCount: number; LastMessageAt: string | null;
  Pinned: number; RoomType?: number | null;
  /** A platform room's coin, from HC6.ChatRoomCatalog(). Null until it has art. */
  RoomIcon?: string | null;
  /** A direct message (E9.F1.S7): the thread, and who is on the other end.
   *  Null on every other kind. EventName / KennelLogo carry the same name and
   *  photo as fallbacks. The SP returns these rows only to devices whose
   *  BuildNumber parses to >= HC6.MinBuildForDmPush(). */
  ThreadId?: string | null;
  OtherPublicHasherId?: string | null;
  OtherDisplayName?: string | null;
  OtherPhoto?: string | null;
}

/** hcapp_get*Messages row (flutter_chat_core shape). */
export interface ChatMessageRow {
  id: string; type: string; text: string; roomId: string | null; createdAt: number;
  authorId: string; authorFirstName: string; authorImageUrl: string | null; sequenceCount: number;
  /** 0 text, 1 photo (text = blob URL), 2 location (text = maps URL) — E9.F1.S11/S12. Anything else draws as text. */
  messageKind?: number | null;
  /** 1 when I may delete it: my own, or I moderate this thread (E9.F1.S13/S14). */
  canDelete?: number | null;
  /** A reply (E9.F1.S21): the quoted message, UPPER. The quote's own fields follow so it draws without the original. */
  replyToMessageId?: string | null;
  /** The quoted message's text (or URL); null when it is not a reply or the original was deleted. */
  replyToText?: string | null;
  replyToKind?: number | null;
  replyToAuthor?: string | null;
  /** 1 when the quoted message has since been deleted: the quote reads "Message deleted". */
  replyToRemoved?: number | null;
  /** Reactions (E9.F1.S22): `{"beer":["<PUBLICHASHERID>", …]}` as the server holds it, or null. parseReactions() reads it. */
  reactions?: string | null;
}

/** One message whose reactions changed since the last poll (E9.F1.S22). */
export interface ChatReactionUpdate { id: string; reactions: string | null }

// The wrapper SPs sign nothing themselves: the token is for the app SP the
// kind selects, so a DM is read and sent through the DM SPs' own gates.
const CHAT_GET_PROC: Record<ChatKind, string> = { run: "hcapp_getEventMessages", kennel: "hcapp_getKennelMessages", room: "hcapp_getRoomMessages", dm: "hcapp_getDirectMessages" };
const CHAT_SEND_PROC: Record<ChatKind, string> = { run: "hcapp_sendEventMessage", kennel: "hcapp_sendKennelMessage", room: "hcapp_sendRoomMessage", dm: "hcapp_sendDirectMessage" };
// Rooms and DMs mark themselves read through their reader's @markRead flag.
const CHAT_READ_PROC: Record<"run" | "kennel", string> = { run: "hcapp_markEventChatRead", kennel: "hcapp_markKennelChatRead" };

function chatIds(kind: ChatKind, id: string) {
  return {
    publicEventId: kind === "run" ? id : null, publicKennelId: kind === "kennel" ? id : null,
    roomType: kind === "room" ? id : null, threadId: kind === "dm" ? id : null,
  };
}

export async function getChatThreads(s: MemberSession): Promise<{ me: string; threads: ChatThreadRow[] }> {
  const rowsets = await callAdminApi("getChatThreads", { deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_getEventBadgeCount") });
  const env = (rowsets[0]?.[0] ?? {}) as { success?: number; Me?: string };
  if (env.success !== 1) return { me: "", threads: [] };
  // The badge SP returns its thread rows as the next rowset that carries BadgeCount.
  const rows = (rowsets.slice(1).find((r) => r.length > 0 && "BadgeCount" in (r[0] as object)) ?? []) as unknown as ChatThreadRow[];
  // A row that names no thread at all is a kind this build does not know: skip it, never crash on it.
  return { me: (env.Me ?? "").toUpperCase(), threads: rows.filter((t) => t.PublicEventId || t.PublicKennelId || t.RoomType != null || t.ThreadId) };
}

/** The other half of a direct message, from hcapp_getDirectMessages' status rowset (E9.F1.S7). */
export interface DmThreadInfo {
  /** UPPER, as the chat rowsets carry authorId. */
  otherPublicHasherId: string;
  otherDisplayName: string;
  otherPhoto: string | null;
  /** 0 when either side has ended the conversation or blocked the other: the composer closes. */
  canSend: number;
  /** 1 when this member has muted the thread's pushes. */
  muted: number;
  unreadCount: number;
}

export interface ChatMessages {
  me: string;
  messages: ChatMessageRow[];
  /** Every removed message in the thread, UPPER. A delta fetch never sees a deletion, so the client drops these. */
  removed: string[];
  /** A DM's status — who, whether I may send, muted. Absent for every other kind, and absent when the DM SP refused (not my thread). */
  dm?: DmThreadInfo;
  /** Older messages whose reactions changed after `reactionsSince` (E9.F1.S22). Empty when none. */
  reactionUpdates: ChatReactionUpdate[];
  /** Server time of this read: pass it back as `reactionsSince` on the next poll. */
  reactionsAsOf: string | null;
}

export async function getChatMessages(s: MemberSession, kind: ChatKind, id: string, since?: number, markRead?: boolean, reactionsSince?: string | null): Promise<ChatMessages | null> {
  const rowsets = await callAdminApi("getChatMessages", {
    deviceId: s.deviceId, accessToken: tokenFor(s, CHAT_GET_PROC[kind]), kind, ...chatIds(kind, id),
    sinceSequenceCount: since == null ? null : String(since), markRead: markRead ? "1" : "0",
    reactionsSince: reactionsSince || null,
  });
  const env = (rowsets[0]?.[0] ?? {}) as { success?: number; Me?: string };
  if (env.success !== 1) return null;
  const rows = (rowsets.slice(1).find((r) => r.length > 0 && "sequenceCount" in (r[0] as object)) ?? []) as unknown as ChatMessageRow[];
  // The LAST rowset, found by its column rather than its index: the room
  // path puts a badge rowset in front of it. Empty when nothing was removed.
  const removedRows = (rowsets.slice(1).find((r) => r.length > 0 && "removedId" in (r[0] as object)) ?? []) as { removedId?: unknown }[];
  const removed = removedRows.map((r) => String(r.removedId ?? "").toUpperCase()).filter(Boolean);
  // Reactions on messages the delta would not otherwise carry, and the server
  // clock to poll from next time — both by column, both AFTER removedId.
  const updateRows = (rowsets.slice(1).find((r) => r.length > 0 && "reactions" in (r[0] as object) && !("sequenceCount" in (r[0] as object))) ?? []) as { id?: unknown; reactions?: unknown }[];
  const reactionUpdates: ChatReactionUpdate[] = updateRows
    .map((r) => ({ id: String(r.id ?? "").toUpperCase(), reactions: r.reactions == null ? null : String(r.reactions) }))
    .filter((r) => r.id);
  const asOfRow = rowsets.slice(1).find((r) => r.length > 0 && "reactionsAsOf" in (r[0] as object))?.[0] as { reactionsAsOf?: unknown } | undefined;
  const reactionsAsOf = asOfRow?.reactionsAsOf == null ? null : String(asOfRow.reactionsAsOf);
  const out: ChatMessages = { me: (env.Me ?? "").toUpperCase(), messages: rows, removed, reactionUpdates, reactionsAsOf };
  if (kind === "dm") {
    // The wrapper emits its own success envelope BEFORE the DM SP runs, so a
    // refusal (not my thread) looks like an empty thread with no status
    // rowset. No status ⇒ no DM: the page treats that as not found.
    const st = rowsets.slice(1).find((r) => r.length > 0 && "canSend" in (r[0] as object))?.[0] as Partial<DmThreadInfo> | undefined;
    if (!st?.otherPublicHasherId) return null;
    out.dm = {
      otherPublicHasherId: String(st.otherPublicHasherId).toUpperCase(),
      otherDisplayName: String(st.otherDisplayName ?? ""),
      otherPhoto: st.otherPhoto ? String(st.otherPhoto) : null,
      canSend: Number(st.canSend) === 1 ? 1 : 0,
      muted: Number(st.muted) === 1 ? 1 : 0,
      unreadCount: Number(st.unreadCount) || 0,
    };
  }
  return out;
}

export async function sendChatMessage(s: MemberSession, kind: ChatKind, id: string, messageId: string, text: string, messageKind: ChatMessageKind = CHAT_KIND_TEXT, replyToMessageId?: string | null): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("sendChatMessage", {
    deviceId: s.deviceId, accessToken: tokenFor(s, CHAT_SEND_PROC[kind]), kind, ...chatIds(kind, id), messageId, messageContent: text,
    messageKind: String(messageKind),
    // A reply quotes one message of the same thread (E9.F1.S21); the SP checks that.
    replyToMessageId: replyToMessageId || null,
  });
  // The app's send SPs emit their push-recipient SELECTs as rowsets before
  // anything else, so the envelope is wherever a `success` column sits.
  const env = rowsets.map((r) => r?.[0] as { success?: number; errorUserMessage?: string } | undefined).filter((r) => r && "success" in r);
  if (env.some((r) => r?.success === 1)) return { ok: true };
  const msg = rowsets.map((r) => r?.[0] as { errorUserMessage?: string } | undefined).find((r) => r?.errorUserMessage)?.errorUserMessage;
  return { ok: false, message: msg ?? "Couldn't send." };
}

/**
 * Adds or removes MY reaction on one message (E9.F1.S22) through
 * publicWeb_reactToChatMessage, which EXECs hcapp_reactToChatMessage — the
 * palette and the "may I see this message" gate live there. Answers the
 * message's whole reactions JSON as the server now holds it.
 */
export async function reactToChatMessage(s: MemberSession, messageId: string, reaction: string, on: 0 | 1): Promise<{ ok: true; reactions: string | null } | { ok: false; message: string }> {
  const rowsets = await callAdminApi("reactToChatMessage", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_reactToChatMessage"), messageId, reaction, on: String(on),
  });
  const row = rowsets.map((r) => r?.[0] as { success?: number; reactions?: unknown } | undefined).find((r) => r?.success === 1);
  if (row) return { ok: true, reactions: row.reactions == null ? null : String(row.reactions) };
  const msg = rowsets.map((r) => r?.[0] as { errorUserMessage?: string } | undefined).find((r) => r?.errorUserMessage)?.errorUserMessage;
  return { ok: false, message: msg ?? "That reaction could not be saved." };
}

/**
 * Deletes one message (E9.F1.S13/S14) through publicWeb_deleteChatMessage,
 * which EXECs hcapp_deleteChatMessage — the rule (my own, or a chat
 * administrator's) lives there, not here.
 */
export async function deleteChatMessage(s: MemberSession, messageId: string): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("deleteChatMessage", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_deleteChatMessage"), messageId,
  });
  // An auth failure returns the error rowset alone (no success column), so
  // look for success = 1 anywhere rather than trusting rowset 0.
  if (rowsets.some((r) => (r?.[0] as { success?: number } | undefined)?.success === 1)) return { ok: true };
  const msg = rowsets.map((r) => r?.[0] as { errorUserMessage?: string } | undefined).find((r) => r?.errorUserMessage)?.errorUserMessage;
  return { ok: false, message: msg ?? "That message could not be deleted." };
}

// ── Block and report (E9.F1.S16/S17) ─────────────────────────────────────────

/** One hasher the signed-in member has blocked, as hcapp_getBlockedHashers lists them. */
export interface BlockedHasher {
  /** UPPER — what the chat rowsets carry as authorId. */
  PublicHasherId: string;
  DisplayName: string;
  Photo: string | null;
  BlockedAt: string;
}

/** `success = 1` anywhere in the reply: an auth failure returns the error rowset alone, so rowset 0 cannot be trusted. */
const succeeded = (rowsets: Rowsets) => rowsets.some((r) => (r?.[0] as { success?: number } | undefined)?.success === 1);
const refusalOf = (rowsets: Rowsets) => rowsets.map((r) => r?.[0] as { errorUserMessage?: string } | undefined).find((r) => r?.errorUserMessage)?.errorUserMessage;

/** The blocked list is the rowset whose rows carry PublicHasherId — index-free, so an SP that grows a rowset in front does not break it. */
function blockedListOf(rowsets: Rowsets): BlockedHasher[] {
  return (rowsets.find((r) => r.length > 0 && "PublicHasherId" in (r[0] as object)) ?? []) as unknown as BlockedHasher[];
}

/** Everyone this member has blocked, newest first. Empty on refusal too — a settings list has nothing better to say. */
export async function getBlockedHashers(s: MemberSession): Promise<BlockedHasher[]> {
  const rowsets = await callAdminApi("getBlockedHashers", { deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_getBlockedHashers") });
  if (refusalOf(rowsets)) return [];
  return blockedListOf(rowsets);
}

/**
 * Blocks (1) or unblocks (0) one hasher through publicWeb_setHasherBlock,
 * which EXECs hcapp_setHasherBlock. From then on every chat reader hides
 * their messages from this member, so the caller re-fetches any open
 * thread in full. Returns the blocked list as it now stands, so a screen
 * repaints from the reply rather than asking again.
 */
export async function setHasherBlock(
  s: MemberSession,
  targetPublicHasherId: string,
  blocked: 0 | 1,
): Promise<{ ok: boolean; message?: string; blocked: BlockedHasher[] }> {
  const rowsets = await callAdminApi("setHasherBlock", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_setHasherBlock"), targetPublicHasherId, blocked: String(blocked),
  });
  if (succeeded(rowsets)) return { ok: true, blocked: blockedListOf(rowsets) };
  return { ok: false, message: refusalOf(rowsets) ?? "That could not be saved. Please try again.", blocked: [] };
}

/** hcapp_reportChatMessage caps the reason here and refuses a longer one. */
export const CHAT_REPORT_REASON_MAX = 1000;

/**
 * Reports one message to Harrier Central's reviewers (E9.F1.S17) through
 * publicWeb_reportChatMessage → hcapp_reportChatMessage. The SP hands the
 * API what to email and the API strips it, so only the envelope reaches
 * here. Reporting the same message twice is a success that sends nothing.
 */
export async function reportChatMessage(s: MemberSession, messageId: string, reason: string | null): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("reportChatMessage", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_reportChatMessage"), messageId, reason,
  });
  if (succeeded(rowsets)) return { ok: true };
  return { ok: false, message: refusalOf(rowsets) ?? "The report could not be sent. Please try again." };
}

// ── Direct messages (E9.F1.S7/S18/S19) ───────────────────────────────────────
//
// Six thin publicWeb_ wrappers, each EXECing the app SP the token is signed
// for — the rules (who may message whom, what a request is, who is told)
// live there and nowhere else. Each reply is the app SP's own: the envelope
// wherever `success` sits, the data row found by a column it alone carries.

/** 0 friends only (the default — every row is 0 today) · 1 anyone · 2 nobody. */
export type DmPreference = 0 | 1 | 2;

/** HC.Hasher.Preferences bits 0x4000|0x8000 — the same read as HC6.DirectMessagePreference. 3 is unused and reads as nobody. */
export function dmPreferenceOf(preferences: number | null | undefined): DmPreference {
  const p = ((preferences ?? 0) >> 14) & 3;
  return p === 0 ? 0 : p === 1 ? 1 : 2;
}

/** What hcapp_startDirectMessage answers: the door, and who is behind it. */
export interface DmStart {
  /** open → go to ThreadId. requested → they will be asked (also the answer when they blocked me, or once declined — nothing may reveal either). refused → they accept nobody. blocked → I blocked them. */
  outcome: "open" | "requested" | "refused" | "blocked";
  /** UPPER; set only when open. */
  threadId: string | null;
  otherPublicHasherId: string;
  otherDisplayName: string;
  otherPhoto: string | null;
}

/** The rowset carrying Outcome, wherever the SP put it; the outcome is checked against what each SP may say by its caller. */
function dmOutcomeOf(rowsets: Rowsets): (Omit<DmStart, "outcome"> & { outcome: string }) | null {
  const r = rowsets.find((x) => x.length > 0 && "Outcome" in (x[0] as object))?.[0] as
    { Outcome?: string; ThreadId?: string | null; OtherPublicHasherId?: string; OtherDisplayName?: string; OtherPhoto?: string | null } | undefined;
  if (!r?.Outcome) return null;
  return {
    outcome: String(r.Outcome),
    threadId: r.ThreadId ? String(r.ThreadId).toUpperCase() : null,
    otherPublicHasherId: String(r.OtherPublicHasherId ?? "").toUpperCase(),
    otherDisplayName: String(r.OtherDisplayName ?? ""),
    otherPhoto: r.OtherPhoto ? String(r.OtherPhoto) : null,
  };
}

const START_OUTCOMES: readonly DmStart["outcome"][] = ["open", "requested", "refused", "blocked"];

/** "Message <name>" from any chat (E9.F1.S19): one of four outcomes, never an error for a refusal. */
export async function startDirectMessage(s: MemberSession, targetPublicHasherId: string): Promise<{ ok: true; start: DmStart } | { ok: false; message: string }> {
  const rowsets = await callAdminApi("startDirectMessage", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_startDirectMessage"), targetPublicHasherId,
  });
  const r = succeeded(rowsets) ? dmOutcomeOf(rowsets) : null;
  const outcome = START_OUTCOMES.find((o) => o === r?.outcome);
  if (r && outcome) return { ok: true, start: { ...r, outcome } };
  return { ok: false, message: refusalOf(rowsets) ?? "That conversation could not be started. Please try again." };
}

/** A request I have received and not yet answered, as hcapp_getDirectMessageRequests lists them. */
export interface DmRequest {
  /** UPPER. */
  FromPublicHasherId: string;
  DisplayName: string;
  Photo: string | null;
  RequestedAt: string;
}

/** Requests waiting on me, oldest first as the SP orders them. Empty on refusal too. */
export async function getDirectMessageRequests(s: MemberSession): Promise<DmRequest[]> {
  const rowsets = await callAdminApi("getDirectMessageRequests", { deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_getDirectMessageRequests") });
  if (refusalOf(rowsets)) return [];
  return (rowsets.find((r) => r.length > 0 && "FromPublicHasherId" in (r[0] as object)) ?? []) as unknown as DmRequest[];
}

/**
 * Accept (1) or decline (0) one request. Accepting makes the pair friends
 * and mints the thread — `threadId` is where to go next. Declining is
 * silent: the requester is never told.
 */
export async function respondDirectMessageRequest(s: MemberSession, fromPublicHasherId: string, accept: 0 | 1): Promise<{ ok: true; outcome: "open" | "declined"; threadId: string | null } | { ok: false; message: string }> {
  const rowsets = await callAdminApi("respondDirectMessageRequest", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_respondDirectMessageRequest"), fromPublicHasherId, accept: String(accept),
  });
  const r = succeeded(rowsets) ? dmOutcomeOf(rowsets) : null;
  if (r?.outcome === "open" || r?.outcome === "declined") return { ok: true, outcome: r.outcome, threadId: r.threadId };
  return { ok: false, message: refusalOf(rowsets) ?? "That request could not be answered. Please try again." };
}

/** Ends the conversation from my side (E9.F1.S7): it stays readable, but neither of us can send until they start it again. Silent to them. */
export async function endDirectMessage(s: MemberSession, threadId: string): Promise<{ ok: boolean; message?: string }> {
  const rowsets = await callAdminApi("endDirectMessage", { deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_endDirectMessage"), threadId });
  if (succeeded(rowsets)) return { ok: true };
  return { ok: false, message: refusalOf(rowsets) ?? "That could not be saved. Please try again." };
}

/** Mutes (1) or unmutes (0) the thread's pushes to my devices. Returns the value as it now stands. */
export async function setDirectMessageMute(s: MemberSession, threadId: string, mute: 0 | 1): Promise<{ ok: true; muted: 0 | 1 } | { ok: false; message: string }> {
  const rowsets = await callAdminApi("setDirectMessageMute", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_setDirectMessageMute"), threadId, mute: String(mute),
  });
  if (succeeded(rowsets)) {
    const r = rowsets.find((x) => x.length > 0 && "Muted" in (x[0] as object))?.[0] as { Muted?: unknown } | undefined;
    return { ok: true, muted: Number(r?.Muted ?? mute) === 1 ? 1 : 0 };
  }
  return { ok: false, message: refusalOf(rowsets) ?? "That could not be saved. Please try again." };
}

/** Who may message me (E9.F1.S18). The SP read-modify-writes its two bits and hands back the value as stored. */
export async function setDirectMessagePreference(s: MemberSession, preference: DmPreference): Promise<{ ok: true; preference: DmPreference } | { ok: false; message: string }> {
  const rowsets = await callAdminApi("setDirectMessagePreference", {
    deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_setDirectMessagePreference"), preference: String(preference),
  });
  if (succeeded(rowsets)) {
    const r = rowsets.find((x) => x.length > 0 && "Preference" in (x[0] as object))?.[0] as { Preference?: unknown } | undefined;
    const p = Number(r?.Preference ?? preference);
    return { ok: true, preference: p === 1 ? 1 : p === 2 ? 2 : 0 };
  }
  return { ok: false, message: refusalOf(rowsets) ?? "That setting could not be saved. Please try again." };
}

/**
 * A 15-minute write-only SAS for one chat photo, from the
 * GetChatPhotoUploadToken function (E9.F1.S11). The blob path is built from
 * the token's user, never from anything the browser sends. A 403 is the
 * SP refusing the device (signed out elsewhere); anything else throws.
 */
export async function getChatPhotoUploadUrl(s: MemberSession, photoGuid: string): Promise<{ sasUrl: string; blobUrl: string } | { error: string }> {
  const res = await fetch(`${API_BASE}/api/GetChatPhotoUploadToken`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ deviceId: s.deviceId, accessToken: tokenFor(s, "hcapp_getChatPhotoUploadToken"), photoGuid }),
    cache: "no-store",
  });
  const text = await res.text();
  let j: { sasUrl?: string; blobUrl?: string; errorUserMessage?: string | null } = {};
  try { j = JSON.parse(text) as typeof j; } catch { /* not JSON */ }
  if (res.ok && j.sasUrl && j.blobUrl) return { sasUrl: j.sasUrl, blobUrl: j.blobUrl };
  if (res.status === 403) return { error: j.errorUserMessage ?? "This browser is no longer signed in. Please sign in again." };
  throw new Error(`GetChatPhotoUploadToken: ${res.status} ${text.slice(0, 200)}`);
}

export async function markChatRead(s: MemberSession, kind: "run" | "kennel", id: string): Promise<void> {
  await callAdminApi("markChatRead", { deviceId: s.deviceId, accessToken: tokenFor(s, CHAT_READ_PROC[kind]), kind, ...chatIds(kind, id) }).catch(() => undefined);
}

/**
 * The app's Songs tab: the whole catalogue, ungrouped (a kennel's own
 * songbook belongs on that kennel's pages). Pass a songId for just one.
 */
export async function getAllSongs(s: MemberSession, songId?: string): Promise<Song[]> {
  const rowsets = await callAdminApi("getAllSongs", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "publicWeb_getAllSongs"),
    songId: songId ?? null,
  });
  if (envelopeOf(rowsets).success !== 1) return [];
  return (rowsets[1] ?? []) as unknown as Song[];
}

/** What SendRunCountsReport needs; resolved server-side so the browser never sees it. */
export interface ReportContext { KennelId: string; KennelName: string; UserName: string; EmailAddress: string | null }

export async function getReportContext(s: MemberSession, publicKennelId?: string): Promise<ReportContext | null> {
  const rowsets = await callAdminApi("getReportContext", {
    deviceId: s.deviceId,
    accessToken: tokenFor(s, "publicWeb_getReportContext"),
    publicKennelId: publicKennelId ?? null,
  });
  if (envelopeOf(rowsets).success !== 1) return null;
  return (rowsets[1]?.[0] as unknown as ReportContext) ?? null;
}
