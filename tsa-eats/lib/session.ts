// Worker session cookie helpers — server-side only.

import { cookies } from 'next/headers';
import { validateSession, type WorkerSession } from './api';

export const SESSION_COOKIE = 'tsa_session';
const NINETY_DAYS = 90 * 24 * 60 * 60;

export async function getWorkerSession(): Promise<WorkerSession | null> {
  const jar = await cookies();
  const sessionId = jar.get(SESSION_COOKIE)?.value;
  if (!sessionId) return null;
  return validateSession(sessionId);
}

export function sessionCookieOptions(sessionId: string) {
  return {
    name: SESSION_COOKIE,
    value: sessionId,
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict' as const,
    maxAge: NINETY_DAYS,
    path: '/',
  };
}

// ── Admin session ────────────────────────────────────────────────────

import { createHmac, timingSafeEqual } from 'crypto';

export const ADMIN_COOKIE = 'tsa_admin';
const ADMIN_SECRET = process.env.ADMIN_SESSION_SECRET ?? 'dev-secret-change-me';
const ONE_HOUR = 60 * 60;

function signAdminToken(payload: string): string {
  return createHmac('sha256', ADMIN_SECRET).update(payload).digest('hex');
}

export function makeAdminCookieValue(): string {
  const exp = Math.floor(Date.now() / 1000) + ONE_HOUR;
  const payload = `admin:${exp}`;
  const sig = signAdminToken(payload);
  return `${payload}.${sig}`;
}

export function verifyAdminCookie(value: string): boolean {
  const lastDot = value.lastIndexOf('.');
  if (lastDot === -1) return false;
  const payload = value.slice(0, lastDot);
  const sig = value.slice(lastDot + 1);
  const expected = signAdminToken(payload);
  try {
    if (!timingSafeEqual(Buffer.from(sig, 'hex'), Buffer.from(expected, 'hex'))) return false;
  } catch {
    return false;
  }
  const parts = payload.split(':');
  const exp = parseInt(parts[1] ?? '0', 10);
  return Math.floor(Date.now() / 1000) < exp;
}

export async function getAdminSession(): Promise<boolean> {
  const jar = await cookies();
  const value = jar.get(ADMIN_COOKIE)?.value;
  if (!value) return false;
  return verifyAdminCookie(value);
}

export function adminCookieOptions(value: string) {
  return {
    name: ADMIN_COOKIE,
    value,
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict' as const,
    maxAge: ONE_HOUR,
    path: '/admin',
  };
}
