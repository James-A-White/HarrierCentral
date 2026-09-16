/**
 * Member session — the browser as a device (E9.F7).
 *
 * The app has no username/password: a device holds a secret and proves it
 * with a 30-second SHA-256 token (see /hc-access-tokens). A signed-in browser
 * is exactly that — an HC.Device row — and this module keeps its credentials
 * in an ENCRYPTED httpOnly cookie so the secret never reaches page JavaScript,
 * and mints the same tokens the app mints, byte for byte, so every hcapp_ SP
 * accepts the browser as it accepts a phone.
 *
 * Server only. Never import from a "use client" component.
 */
import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from "crypto";
import type { NextRequest, NextResponse } from "next/server";

export const MEMBER_COOKIE = "hc_member";
const COOKIE_MAX_AGE_REMEMBERED = 365 * 24 * 60 * 60;

export interface MemberSession {
  userId: string;
  deviceId: string;
  deviceSecret: string;
  timeWindow: number;
  hashName: string;
  displayName: string;
  photo: string;
  /** When the person ticked "this isn't my device": session cookie only. */
  remembered: boolean;
}

function key(): Buffer {
  const raw = process.env.HC_MEMBER_SESSION_SECRET;
  if (!raw) throw new Error("HC_MEMBER_SESSION_SECRET environment variable is not set.");
  // Any string works as the secret; hash it so the AES key is always 32 bytes.
  return createHash("sha256").update(raw).digest();
}

/** AES-256-GCM: iv.tag.ciphertext, all base64url. */
export function sealSession(session: MemberSession): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", key(), iv);
  const body = Buffer.concat([cipher.update(JSON.stringify(session), "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString("base64url")}.${tag.toString("base64url")}.${body.toString("base64url")}`;
}

export function openSession(cookie: string | undefined): MemberSession | null {
  if (!cookie) return null;
  const parts = cookie.split(".");
  if (parts.length !== 3) return null;
  try {
    const [iv, tag, body] = parts.map((p) => Buffer.from(p, "base64url"));
    const decipher = createDecipheriv("aes-256-gcm", key(), iv);
    decipher.setAuthTag(tag);
    const plain = Buffer.concat([decipher.update(body), decipher.final()]).toString("utf8");
    const s = JSON.parse(plain) as MemberSession;
    if (!s.userId || !s.deviceId || !s.deviceSecret || !s.timeWindow) return null;
    return s;
  } catch {
    return null;
  }
}

export function readMember(req: NextRequest): MemberSession | null {
  return openSession(req.cookies.get(MEMBER_COOKIE)?.value);
}

export function setMemberCookie(res: NextResponse, session: MemberSession): void {
  res.cookies.set(MEMBER_COOKIE, sealSession(session), {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax", // the WhatsApp link is a cross-site navigation; strict would drop the cookie on arrival
    path: "/",
    ...(session.remembered ? { maxAge: COOKIE_MAX_AGE_REMEMBERED } : {}),
  });
}

export function clearMemberCookie(res: NextResponse): void {
  res.cookies.set(MEMBER_COOKIE, "", { httpOnly: true, path: "/", maxAge: 0 });
}

// ── Access tokens — the app's algorithm, exactly ──────────────────────────────

export const GUID_EMPTY = "00000000-0000-0000-0000-000000000000";
const TOKEN_EPOCH_MS = Date.UTC(1993, 6, 25, 15, 0, 0); // 1993-07-25 15:00 UTC — never changes

/**
 * Mirrors Utilities.generateToken in the app:
 *   UPPER(userId # procName # timeBlocks [# paramString]) → SHA-256 hex, upper.
 * paramString is the RAW compound value (deviceSecret, or deviceSecret +
 * something); the '#' is added here, as the app does. The server accepts
 * ±2 windows, so clock drift of a minute is fine.
 */
export function hcToken(
  userId: string,
  procName: string,
  opts: { paramString?: string; timeWindow?: number; now?: number } = {},
): string {
  const timeWindow = opts.timeWindow ?? 30;
  const seconds = Math.floor(((opts.now ?? Date.now()) - TOKEN_EPOCH_MS) / 1000);
  const timeBlocks = Math.floor(seconds / timeWindow);
  const param = opts.paramString ? `#${opts.paramString.toUpperCase()}` : "";
  const accessString = `${userId}#${procName}#${timeBlocks}${param}`.toUpperCase();
  return createHash("sha256").update(accessString, "utf8").digest("hex").toUpperCase();
}

/** A device-bound token for a member session. */
export function memberToken(s: MemberSession, procName: string, extra = ""): string {
  return hcToken(s.userId, procName, { paramString: s.deviceSecret + extra, timeWindow: s.timeWindow });
}

// ── Short-lived signed values (WebAuthn challenges, QR auth codes) ────────────

export function signValue(payload: object, ttlSeconds: number): string {
  const body = Buffer.from(JSON.stringify({ ...payload, exp: Math.floor(Date.now() / 1000) + ttlSeconds })).toString("base64url");
  const sig = createHmac("sha256", key()).update(body).digest("base64url");
  return `${body}.${sig}`;
}

export function verifyValue<T extends object>(token: string | undefined): (T & { exp: number }) | null {
  if (!token) return null;
  const dot = token.lastIndexOf(".");
  if (dot < 0) return null;
  const body = token.slice(0, dot);
  const sig = Buffer.from(token.slice(dot + 1), "base64url");
  const expected = createHmac("sha256", key()).update(body).digest();
  if (sig.length !== expected.length || !timingSafeEqual(sig, expected)) return null;
  try {
    const v = JSON.parse(Buffer.from(body, "base64url").toString("utf8")) as T & { exp: number };
    if (v.exp < Math.floor(Date.now() / 1000)) return null;
    return v;
  } catch {
    return null;
  }
}
