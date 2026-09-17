import { NextRequest, NextResponse } from "next/server";
import { verifyRegistrationResponse, type RegistrationResponseJSON } from "@simplewebauthn/server";
import { callAdminApi } from "@/lib/member-api";
import { hcToken, readMember, verifyValue } from "@/lib/member-session";
import { CHALLENGE_COOKIE, EXPECTED_ORIGINS, RP_ID } from "@/lib/passkeys";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/** POST <RegistrationResponseJSON> → { ok } — verifies and binds the passkey to this browser's device row. */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const ch = verifyValue<{ c: string; k: string }>(req.cookies.get(CHALLENGE_COOKIE)?.value);
  if (!ch || ch.k !== "reg") return bad("The passkey set-up timed out. Try again.", 410);
  const body = await jsonBody<RegistrationResponseJSON>(req);
  if (!body) return bad("Bad request.");

  let verification;
  try {
    verification = await verifyRegistrationResponse({
      response: body,
      expectedChallenge: ch.c,
      expectedOrigin: EXPECTED_ORIGINS,
      expectedRPID: RP_ID,
      requireUserVerification: false,
    });
  } catch (e) {
    await logWebError({ source: "/api/member/passkey/register-verify", error: e, session: s });
    return bad("That passkey couldn't be verified.", 400);
  }
  if (!verification.verified || !verification.registrationInfo) return bad("That passkey couldn't be verified.", 400);

  const { credential } = verification.registrationInfo;
  const rowsets = await callAdminApi("savePasskey", {
    deviceId: s.deviceId,
    accessToken: hcToken(s.userId, "publicWeb_savePasskey", { paramString: s.deviceSecret, timeWindow: s.timeWindow }),
    credentialId: credential.id,
    publicKey: Buffer.from(credential.publicKey).toString("base64url"),
    counter: String(credential.counter),
    transports: (credential.transports ?? []).join(","),
  });
  const ok = (rowsets?.[0]?.[0] as { success?: number } | undefined)?.success === 1;
  const res = NextResponse.json({ ok });
  res.cookies.set(CHALLENGE_COOKIE, "", { path: "/", maxAge: 0 });
  return ok ? res : bad("The passkey couldn't be saved.", 502);
}
