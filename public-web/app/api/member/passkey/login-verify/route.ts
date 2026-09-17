import { NextRequest, NextResponse } from "next/server";
import { verifyAuthenticationResponse, type AuthenticationResponseJSON } from "@simplewebauthn/server";
import { callAdminApi } from "@/lib/member-api";
import { setMemberCookie, verifyValue, type MemberSession } from "@/lib/member-session";
import { CHALLENGE_COOKIE, EXPECTED_ORIGINS, RP_ID } from "@/lib/passkeys";
import { bad, ipOf, jsonBody, limited } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * POST { response: AuthenticationResponseJSON, remember } → { ok, hashName }
 * Looks the credential up, verifies the signature against the stored public
 * key, refuses a counter that has not advanced (a cloned authenticator), and
 * only then turns the device credentials into a member cookie.
 */
export async function POST(req: NextRequest) {
  if (limited(`passkey:ip:${ipOf(req)}`, 20, 60_000)) return bad("Too many attempts.", 429);
  const ch = verifyValue<{ c: string; k: string }>(req.cookies.get(CHALLENGE_COOKIE)?.value);
  if (!ch || ch.k !== "auth") return bad("The sign-in timed out. Try again.", 410);
  const body = await jsonBody<{ response?: AuthenticationResponseJSON; remember?: boolean }>(req);
  const response = body?.response;
  if (!response?.id) return bad("Bad request.");

  const rows = await callAdminApi("getPasskey", { credentialId: response.id });
  const p = rows?.[0]?.[0];
  if (!p) return bad("That passkey isn't registered here.", 401);

  let verification;
  try {
    verification = await verifyAuthenticationResponse({
      response,
      expectedChallenge: ch.c,
      expectedOrigin: EXPECTED_ORIGINS,
      expectedRPID: RP_ID,
      requireUserVerification: false,
      credential: {
        id: response.id,
        publicKey: new Uint8Array(Buffer.from(String(p.publicKey), "base64url")),
        counter: Number(p.counter) || 0,
        transports: String(p.transports ?? "").split(",").filter(Boolean) as never,
      },
    });
  } catch (e) {
    await logWebError({ source: "/api/member/passkey/login-verify", error: e });
    return bad("That passkey couldn't be verified.", 401);
  }
  if (!verification.verified) return bad("That passkey couldn't be verified.", 401);

  await callAdminApi("recordPasskeyLogin", {
    credentialId: response.id,
    counter: String(verification.authenticationInfo.newCounter),
  });

  const session: MemberSession = {
    userId: String(p.hasherId).toLowerCase(),
    deviceId: String(p.deviceId).toLowerCase(),
    deviceSecret: String(p.deviceSecret),
    timeWindow: Number(p.timeWindow) || 30,
    hashName: String(p.hashName ?? ""),
    displayName: String(p.displayName ?? ""),
    photo: String(p.photo ?? ""),
    remembered: body?.remember !== false,
  };
  const res = NextResponse.json({ ok: true, hashName: session.hashName || session.displayName });
  setMemberCookie(res, session);
  res.cookies.set(CHALLENGE_COOKIE, "", { path: "/", maxAge: 0 });
  return res;
}
