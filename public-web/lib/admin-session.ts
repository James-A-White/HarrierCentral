import { createHmac } from "crypto";

const SECRET = process.env.HC_ADMIN_SESSION_SECRET ?? "dev-only-secret-change-in-production";

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
  if (sig !== expected) return null;
  try {
    const session = JSON.parse(Buffer.from(payload, "base64url").toString()) as AdminSession;
    if (session.exp < Math.floor(Date.now() / 1000)) return null;
    return session;
  } catch {
    return null;
  }
}
