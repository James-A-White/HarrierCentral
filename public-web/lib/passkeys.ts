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

/**
 * The app's native passkey assertions (E9.F7.S13) do not come from a web
 * origin: iOS reports the RP id as an https origin, Android reports the
 * signing certificate's hash. WEBAUTHN_APP_ORIGINS adds more (a second
 * Android signing key, say) without a deploy of this file.
 */
export const APP_ORIGINS: string[] = [
  `https://${RP_ID}`,
  // Android: "android:apk-key-hash:" + base64url(SHA-256 of the signing cert)
  "android:apk-key-hash:gJ4IjTJtt7S4kfEV2GwpyY5uzTWUK0qs2Zs5ufMRQoE",
  ...(process.env.WEBAUTHN_APP_ORIGINS ?? "").split(",").map((o) => o.trim()).filter(Boolean),
];

export const CHALLENGE_COOKIE = "hc_webauthn";
export const CHALLENGE_TTL_SECONDS = 5 * 60;
