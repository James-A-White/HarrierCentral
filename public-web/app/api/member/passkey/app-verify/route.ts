import { NextRequest, NextResponse } from "next/server";
import { verifyAuthenticationResponse, type AuthenticationResponseJSON } from "@simplewebauthn/server";
import { callAdminApi } from "@/lib/member-api";
import { verifyValue } from "@/lib/member-session";
import { APP_ORIGINS, RP_ID } from "@/lib/passkeys";
import { bad, ipOf, jsonBody, limited } from "@/lib/member-routes";

/**
 * The app's first-install sign-in with a web passkey (E9.F7.S13), step 2:
 * POST { ticket, response } → { ok, inviteCode, hashName }. The same
 * verification as the web's login-verify, against the app's origins; then
 * a fresh invite code for that hasher, which the app feeds to its own
 * hcapp_authorizeDevice URC path — no new auth model.
 */
export async function POST(req: NextRequest) {
  if (limited(`passkey-app:ip:${ipOf(req)}`, 30, 60_000)) return bad("Too many attempts.", 429);
  const body = await jsonBody<{ ticket?: string; response?: AuthenticationResponseJSON }>(req);
  const ch = verifyValue<{ c: string; k: string }>(body?.ticket);
  if (!ch || ch.k !== "app") return bad("The sign-in timed out. Try again.", 410);
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
      expectedOrigin: APP_ORIGINS,
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
    console.error("app-verify:", e);
    return bad("That passkey couldn't be verified.", 401);
  }
  if (!verification.verified) return bad("That passkey couldn't be verified.", 401);

  await callAdminApi("recordPasskeyLogin", { credentialId: response.id, counter: String(verification.authenticationInfo.newCounter) });

  const code = await callAdminApi("issuePasskeyInviteCode", { credentialId: response.id });
  const inviteCode = String(code?.[0]?.[0]?.inviteCode ?? "");
  if (!/^[A-Z]{6}$/.test(inviteCode)) return bad("Couldn't prepare the sign-in. Try again.", 502);
  return NextResponse.json({ ok: true, inviteCode, hashName: String(p.hashName ?? p.displayName ?? "") });
}
