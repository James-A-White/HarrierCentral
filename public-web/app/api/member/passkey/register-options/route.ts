import { NextRequest, NextResponse } from "next/server";
import { generateRegistrationOptions } from "@simplewebauthn/server";
import { readMember, signValue } from "@/lib/member-session";
import { CHALLENGE_COOKIE, CHALLENGE_TTL_SECONDS, RP_ID, RP_NAME } from "@/lib/passkeys";
import { bad } from "@/lib/member-routes";

/** POST → registration options for the signed-in member; challenge in a signed cookie. */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const options = await generateRegistrationOptions({
    rpName: RP_NAME,
    rpID: RP_ID,
    userName: s.hashName || s.displayName || "hasher",
    userDisplayName: s.hashName || s.displayName || "hasher",
    // The user handle is the hasher id: stable, opaque, and what a synced
    // passkey will present on another device.
    userID: new TextEncoder().encode(s.userId),
    attestationType: "none",
    authenticatorSelection: { residentKey: "preferred", userVerification: "preferred" },
  });
  const res = NextResponse.json(options);
  res.cookies.set(CHALLENGE_COOKIE, signValue({ c: options.challenge, k: "reg" }, CHALLENGE_TTL_SECONDS), {
    httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: CHALLENGE_TTL_SECONDS,
  });
  return res;
}
