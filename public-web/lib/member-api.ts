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
