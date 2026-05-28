import { NextRequest, NextResponse } from "next/server";
import { createSession } from "@/lib/admin-session";

const API_BASE = process.env.HC_API_URL ?? "http://localhost:7071";

// ── Rate limiting ────────────────────────────────────────────────────────────
// Simple in-memory rate limiter for OTP redemption. Admin users navigate here
// from the Flutter portal — 10 attempts per minute per IP is generous.
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 10;
const RATE_WINDOW_MS = 60_000;

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || entry.resetAt < now) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return true;
  }
  if (entry.count >= RATE_LIMIT) return false;
  entry.count++;
  return true;
}

export async function GET(req: NextRequest) {
  const ip = req.headers.get("x-forwarded-for") ?? "0.0.0.0";
  if (!checkRateLimit(ip)) {
    return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  }

  const token = req.nextUrl.searchParams.get("token");
  const slug  = req.nextUrl.searchParams.get("slug");

  const denied = NextResponse.redirect(new URL(`/${slug ?? ""}/admin/layout`, req.url));

  if (!token || !slug) return denied;

  let kennelSlug: string | undefined;
  try {
    const res = await fetch(`${API_BASE}/api/PublicWebAdminApi`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ queryType: "redeemAdminToken", Token: token }),
      cache: "no-store",
    });

    if (!res.ok) return denied;

    const data = (await res.json()) as Array<Array<{ KennelSlug?: string }>>;
    kennelSlug = data?.[0]?.[0]?.KennelSlug;
  } catch {
    return denied;
  }

  // Token resolved to a different kennel — refuse
  if (!kennelSlug || kennelSlug !== slug) return denied;

  const session = createSession(kennelSlug);
  const response = NextResponse.redirect(new URL(`/${slug}/admin/layout`, req.url));
  response.cookies.set("hc_admin_session", session, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 24 * 60 * 60,
    path: "/",
  });
  return response;
}
