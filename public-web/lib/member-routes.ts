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
  const first = (req.headers.get("x-forwarded-for") ?? "0.0.0.0").split(",")[0].trim();
  // Azure App Service appends the client's port ("83.104.64.69:65387",
  // "[2a00::1]:443"). The port changes with every connection, so a limit
  // keyed on it never trips — strip it (seen 2026-09-28).
  const v6 = /^\[([^\]]+)\](?::\d+)?$/.exec(first);
  if (v6) return v6[1];
  const v4 = /^(\d{1,3}(?:\.\d{1,3}){3}):\d+$/.exec(first);
  return v4 ? v4[1] : first;
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
