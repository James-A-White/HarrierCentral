import { createHmac, timingSafeEqual } from "crypto";

const raw = process.env.HC_ADMIN_SESSION_SECRET;
if (!raw) {
  throw new Error("HC_ADMIN_SESSION_SECRET environment variable is not set.");
}
const SECRET = raw;

interface AdminSession {
  kennelSlug: string;
  exp: number;
}

export function createSession(kennelSlug: string): string {
  const session: AdminSession = {
    kennelSlug,
    exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
  };
  const payload = Buffer.from(JSON.stringify(session)).toString("base64url");
  const sig = createHmac("sha256", SECRET).update(payload).digest("hex");
  return `${payload}.${sig}`;
}

export function verifySession(cookie: string | undefined): AdminSession | null {
  if (!cookie) return null;
  const dot = cookie.lastIndexOf(".");
  if (dot === -1) return null;
  const payload = cookie.slice(0, dot);
  const sig = cookie.slice(dot + 1);
  const expected = createHmac("sha256", SECRET).update(payload).digest("hex");
  const sigBuf      = Buffer.from(sig,      "hex");
  const expectedBuf = Buffer.from(expected, "hex");
  if (sigBuf.length !== expectedBuf.length) return null;
  if (!timingSafeEqual(sigBuf, expectedBuf)) return null;
  try {
    const session = JSON.parse(Buffer.from(payload, "base64url").toString()) as AdminSession;
    if (session.exp < Math.floor(Date.now() / 1000)) return null;
    return session;
  } catch {
    return null;
  }
}
