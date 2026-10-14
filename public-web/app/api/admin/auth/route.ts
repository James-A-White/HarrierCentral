import { NextRequest, NextResponse } from "next/server";
import { createSession } from "@/lib/admin-session";
import { ipOf } from "@/lib/member-routes";

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

/** HTML-escape for an attribute value. */
/** The kennel's admin page. The slug is encoded, so a crafted one cannot turn the path into "//other-host". */
// No slug means no kennel to return to: the home page, never `//admin/layout`
// (a protocol-relative path, which the browser reads as a host called "admin").
const adminPage = (slug: string, base: string) =>
  new URL(slug ? `/${encodeURIComponent(slug)}/admin/layout` : "/", base);
const cleanSlug = (v: string) => v.slice(0, 100);

const esc = (v: string) =>
  v.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

/**
 * GET ?token=&slug= — does NOT redeem (idempotency audit W6, 2026-10-14).
 *
 * The one-time token is consumed by publicWeb_redeemAdminToken (DELETE …
 * OUTPUT), so a GET that redeemed it let a link preview, a mail or chat
 * scanner, a lost redirect or a reload burn the token before the admin got
 * there. A GET is now only a page that POSTs the token back here: a browser
 * submits it on load (the button is there if scripts are off); a fetcher that
 * only GETs reads a form and redeems nothing.
 */
export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get("token") ?? "";
  const slug  = cleanSlug(req.nextUrl.searchParams.get("slug") ?? "");
  if (!token || !slug) return NextResponse.redirect(adminPage(slug, req.url));

  const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer">
<title>Signing in…</title>
<style>body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:system-ui,sans-serif;background:#18181b;color:#f4f4f5}
form{text-align:center}button{margin-top:12px;padding:10px 20px;border:0;border-radius:8px;background:#dc2626;color:#fff;font-size:15px;cursor:pointer}</style>
</head><body>
<form id="f" method="post" action="/api/admin/auth">
<input type="hidden" name="token" value="${esc(token)}">
<input type="hidden" name="slug" value="${esc(slug)}">
<p>Signing you in to the page editor…</p>
<noscript><button type="submit">Continue</button></noscript>
</form>
<script>document.getElementById("f").submit();</script>
</body></html>`;
  return new NextResponse(html, {
    status: 200,
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store", "Referrer-Policy": "no-referrer" },
  });
}

/** POST form { token, slug } — redeems the token and sets the admin session. */
export async function POST(req: NextRequest) {
  // ipOf strips the port Azure appends, which changed per connection and
  // so reset this limit on every request.
  const ip = ipOf(req);
  if (!checkRateLimit(ip)) {
    return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  }

  const form = await req.formData().catch(() => null);
  const token = String(form?.get("token") ?? "");
  const slug  = cleanSlug(String(form?.get("slug") ?? ""));

  // 303: the browser follows a POST's redirect with a GET.
  const denied = NextResponse.redirect(adminPage(slug, req.url), 303);

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
  const response = NextResponse.redirect(adminPage(slug, req.url), 303);
  response.cookies.set("hc_admin_session", session, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 24 * 60 * 60,
    path: "/",
  });
  return response;
}
