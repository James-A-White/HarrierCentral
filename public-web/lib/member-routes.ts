/** Shared bits for /api/member/* routes. Server only. */
import { NextRequest, NextResponse } from "next/server";

// In-memory limiter, per process — the same shape the admin OTP route uses.
// A leaked code request costs one email; a hundred cost a hundred, so the
// limit is per email AND per IP. The SP-side 60-minute code reuse means a
// flood only ever re-sends the same code anyway.
const buckets = new Map<string, { count: number; resetAt: number }>();
export function limited(key: string, max: number, windowMs: number): boolean {
  const now = Date.now();
  const b = buckets.get(key);
  if (!b || b.resetAt < now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return false;
  }
  if (b.count >= max) return true;
  b.count++;
  return false;
}

export function ipOf(req: NextRequest): string {
  return (req.headers.get("x-forwarded-for") ?? "0.0.0.0").split(",")[0].trim();
}

export function deviceDataOf(req: NextRequest): object {
  const ua = req.headers.get("user-agent") ?? "";
  // HC.Device.OperatingSystem is a computed column that reads $.browserName
  // when there is no $.systemName — this is what puts "Safari"/"Chrome" in
  // Device Health instead of NULL (which means Android).
  const browserName =
    /Edg\//.test(ua) ? "Edge" :
    /OPR\//.test(ua) ? "Opera" :
    /Chrome\//.test(ua) ? "Chrome" :
    /Safari\//.test(ua) ? "Safari" :
    /Firefox\//.test(ua) ? "Firefox" : "Browser";
  return { browserName, userAgent: ua.slice(0, 500), source: "hashruns.org member" };
}

export async function jsonBody<T>(req: NextRequest): Promise<T | null> {
  try {
    return (await req.json()) as T;
  } catch {
    return null;
  }
}

export const bad = (message: string, status = 400) => NextResponse.json({ error: message }, { status });

export const isEmail = (s: string) => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(s);
