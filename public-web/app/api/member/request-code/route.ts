import { NextRequest, NextResponse } from "next/server";
import { emailInviteCode } from "@/lib/member-api";
import { bad, ipOf, isEmail, jsonBody, limited } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * POST { email } → { sent: true, known: boolean }
 * The six-letter code goes to the address by the app's own EmailInviteCode
 * path. `known` is what lets the page ask for a hash name when the address
 * is new — the price of that is that a typed address reveals whether it is
 * a member's; the app's signup has the same property.
 */
export async function POST(req: NextRequest) {
  const body = await jsonBody<{ email?: string }>(req);
  const email = (body?.email ?? "").trim().toLowerCase();
  if (!isEmail(email)) return bad("Please enter a valid email address.");
  if (limited(`code:ip:${ipOf(req)}`, 20, 60 * 60_000) || limited(`code:email:${email}`, 5, 15 * 60_000)) {
    return bad("Too many codes requested. Please wait a few minutes and try again.", 429);
  }
  try {
    const known = await emailInviteCode(email);
    return NextResponse.json({ sent: known, known });
  } catch (e) {
    await logWebError({ source: "/api/member/request-code", error: e });
    return bad("We couldn't send the code just now. Please try again.", 502);
  }
}
