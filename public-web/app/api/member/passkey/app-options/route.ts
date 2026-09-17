import { NextRequest, NextResponse } from "next/server";
import { generateAuthenticationOptions } from "@simplewebauthn/server";
import { signValue } from "@/lib/member-session";
import { CHALLENGE_TTL_SECONDS, RP_ID } from "@/lib/passkeys";
import { bad, ipOf, limited } from "@/lib/member-routes";

/**
 * The app's first-install sign-in with a web passkey (E9.F7.S13), step 1:
 * POST → { options, ticket }. The app has no cookie jar, so the challenge
 * travels back as a signed ticket it returns with the assertion.
 */
export async function POST(req: NextRequest) {
  if (limited(`passkey-app:ip:${ipOf(req)}`, 30, 60_000)) return bad("Too many attempts.", 429);
  const options = await generateAuthenticationOptions({ rpID: RP_ID, userVerification: "preferred" });
  return NextResponse.json({ options, ticket: signValue({ c: options.challenge, k: "app" }, CHALLENGE_TTL_SECONDS) });
}
