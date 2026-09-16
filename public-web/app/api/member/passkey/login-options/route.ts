import { NextResponse } from "next/server";
import { generateAuthenticationOptions } from "@simplewebauthn/server";
import { signValue } from "@/lib/member-session";
import { CHALLENGE_COOKIE, CHALLENGE_TTL_SECONDS, RP_ID } from "@/lib/passkeys";

/**
 * POST → authentication options with no allowCredentials: the browser offers
 * whatever passkeys it holds for hashruns.org (discoverable credentials), so
 * nobody has to type anything first.
 */
export async function POST() {
  const options = await generateAuthenticationOptions({ rpID: RP_ID, userVerification: "preferred" });
  const res = NextResponse.json(options);
  res.cookies.set(CHALLENGE_COOKIE, signValue({ c: options.challenge, k: "auth" }, CHALLENGE_TTL_SECONDS), {
    httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: CHALLENGE_TTL_SECONDS,
  });
  return res;
}
