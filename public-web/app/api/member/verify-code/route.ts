import { NextRequest, NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { authorizeBrowserByCode } from "@/lib/member-api";
import { setMemberCookie, signValue, verifyValue } from "@/lib/member-session";
import { bad, deviceDataOf, ipOf, jsonBody, limited } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * POST { code, remember } → { ok, hashName }
 * Turns the emailed code into a device row for this browser and sets the
 * member cookie. Five wrong codes a minute per IP and the door closes for a
 * while: a six-letter code is 309 million possibilities, so guessing is not
 * the risk — hammering the SP is.
 */
/**
 * The browser's deviceId for one sign-in flow (idempotency audit W4), in a
 * signed httpOnly cookie set by request-code — or here, when the flow came
 * through signup instead. Every attempt sends the SAME id, so a double submit
 * or a retry after a lost reply is a repeat that hcapp_authorizeDevice answers
 * with the existing secret, not a second device row with a secret no browser
 * holds. Cleared once the sign-in succeeds; the next flow gets a new one.
 */
const SIGNIN_COOKIE = "hc_signin";
const SIGNIN_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/api/member",
};

export async function POST(req: NextRequest) {
  const body = await jsonBody<{ code?: string; remember?: boolean }>(req);
  const code = (body?.code ?? "").replace(/[^a-z]/gi, "").toUpperCase();
  if (code.length !== 6) return bad("The code is six letters.");
  if (limited(`verify:ip:${ipOf(req)}`, 10, 60_000)) return bad("Too many attempts. Please wait a minute.", 429);

  const held = verifyValue<{ deviceId: string }>(req.cookies.get(SIGNIN_COOKIE)?.value)?.deviceId;
  const deviceId = held ?? randomUUID();
  /** Keep the id for the next attempt when this one does not finish the sign-in. */
  const keep = (res: NextResponse) => {
    if (!held) res.cookies.set(SIGNIN_COOKIE, signValue({ deviceId }, 30 * 60), { ...SIGNIN_COOKIE_OPTIONS, maxAge: 30 * 60 });
    return res;
  };

  try {
    const { session, error } = await authorizeBrowserByCode(code, deviceId, deviceDataOf(req), body?.remember !== false);
    if (!session) return keep(bad(error ?? "That code wasn't recognised.", 401));
    const res = NextResponse.json({ ok: true, hashName: session.hashName || session.displayName });
    setMemberCookie(res, session);
    res.cookies.set(SIGNIN_COOKIE, "", { ...SIGNIN_COOKIE_OPTIONS, maxAge: 0 });
    return res;
  } catch (e) {
    await logWebError({ source: "/api/member/verify-code", error: e });
    return keep(bad("We couldn't check the code just now. Please try again.", 502));
  }
}
