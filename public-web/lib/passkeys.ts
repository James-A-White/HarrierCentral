/**
 * WebAuthn (passkeys) — E9.F7.S6. Server only.
 *
 * A passkey is a device credential, so it lives on the browser's HC.Device
 * row (credential id, public key, counter). The ceremonies are verified here
 * with @simplewebauthn/server — SQL cannot check an ECDSA signature — and the
 * SPs only store and fetch. The challenge between the two halves of each
 * ceremony rides in a short-lived signed cookie, so nothing is stored for a
 * ceremony that never completes.
 *
 * Bound to RP_ID (hashruns.org, which covers www.). A Tier-3 custom domain is
 * a different relying party and would need its own registration.
 */
export const RP_ID = process.env.WEBAUTHN_RP_ID ?? "hashruns.org";
export const RP_NAME = "Harrier Central";
export const EXPECTED_ORIGINS: string[] = (
  process.env.WEBAUTHN_ORIGINS ?? "https://www.hashruns.org,https://hashruns.org"
).split(",").map((s) => s.trim()).filter(Boolean);
if (process.env.NODE_ENV !== "production") EXPECTED_ORIGINS.push("http://localhost:3000");

export const CHALLENGE_COOKIE = "hc_webauthn";
export const CHALLENGE_TTL_SECONDS = 5 * 60;
