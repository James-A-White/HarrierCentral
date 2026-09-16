import { NextRequest, NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { authorizeBrowserByCode } from "@/lib/member-api";
import { setMemberCookie } from "@/lib/member-session";
import { bad, deviceDataOf, ipOf, jsonBody, limited } from "@/lib/member-routes";

/**
 * POST { code, remember } → { ok, hashName }
 * Turns the emailed code into a device row for this browser and sets the
 * member cookie. Five wrong codes a minute per IP and the door closes for a
 * while: a six-letter code is 309 million possibilities, so guessing is not
 * the risk — hammering the SP is.
 */
export async function POST(req: NextRequest) {
  const body = await jsonBody<{ code?: string; remember?: boolean }>(req);
  const code = (body?.code ?? "").replace(/[^a-z]/gi, "").toUpperCase();
  if (code.length !== 6) return bad("The code is six letters.");
  if (limited(`verify:ip:${ipOf(req)}`, 10, 60_000)) return bad("Too many attempts. Please wait a minute.", 429);

  try {
    const { session, error } = await authorizeBrowserByCode(code, randomUUID(), deviceDataOf(req), body?.remember !== false);
    if (!session) return bad(error ?? "That code wasn't recognised.", 401);
    const res = NextResponse.json({ ok: true, hashName: session.hashName || session.displayName });
    setMemberCookie(res, session);
    return res;
  } catch (e) {
    console.error("verify-code:", e);
    return bad("We couldn't check the code just now. Please try again.", 502);
  }
}
