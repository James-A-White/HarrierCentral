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
    path: '/',
  };
}

// ── Order cookie ─────────────────────────────────────────────────────

export const ORDER_COOKIE = 'tsa_order';

export interface OrderCookieData {
  restaurantId: string;
  restaurantName: string;
  mealId: string;
  mealName: string;
  workerId: string;
  workerName: string;
  date: string; // YYYY-MM-DD UTC
  token: string; // DB order token — encoded in QR URL
}

function secondsUntilMidnightUtc(): number {
  const now = new Date();
  const midnight = new Date(Date.UTC(
    now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1
  ));
  return Math.floor((midnight.getTime() - now.getTime()) / 1000);
}

export function orderCookieOptions(data: OrderCookieData) {
  return {
    name: ORDER_COOKIE,
    value: JSON.stringify(data),
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict' as const,
    maxAge: secondsUntilMidnightUtc(),
    path: '/',
  };
}

// ── Restaurant session ───────────────────────────────────────────────

export const RESTAURANT_COOKIE = 'tsa_restaurant';
const RESTAURANT_SECRET = process.env.RESTAURANT_SESSION_SECRET ?? 'restaurant-dev-secret-change-me';
const EIGHT_HOURS = 8 * 60 * 60;

function signRestaurantToken(payload: string): string {
  return createHmac('sha256', RESTAURANT_SECRET).update(payload).digest('hex');
}

export interface RestaurantSession {
  restaurantId: string;
}

export function makeRestaurantCookieValue(restaurantId: string): string {
  const exp = Math.floor(Date.now() / 1000) + EIGHT_HOURS;
  const payload = `restaurant:${restaurantId}:${exp}`;
  const sig = signRestaurantToken(payload);
  return `${payload}.${sig}`;
}

export function verifyRestaurantCookie(value: string): RestaurantSession | null {
  const lastDot = value.lastIndexOf('.');
  if (lastDot === -1) return null;
  const payload = value.slice(0, lastDot);
  const sig = value.slice(lastDot + 1);
  const expected = signRestaurantToken(payload);
  try {
    if (!timingSafeEqual(Buffer.from(sig, 'hex'), Buffer.from(expected, 'hex'))) return null;
  } catch {
    return null;
  }
  // payload format: restaurant:{restaurantId}:{exp}
  // UUIDs contain only hex chars and hyphens, so split(':') gives exactly 3 parts
  const parts = payload.split(':');
  if (parts.length !== 3) return null;
  const exp = parseInt(parts[2] ?? '0', 10);
  if (Math.floor(Date.now() / 1000) >= exp) return null;
  return { restaurantId: parts[1]! };
}

export async function getRestaurantSession(): Promise<RestaurantSession | null> {
  const jar = await cookies();
  const value = jar.get(RESTAURANT_COOKIE)?.value;
  if (!value) return null;
  return verifyRestaurantCookie(value);
}

export function restaurantCookieOptions(value: string) {
  return {
    name: RESTAURANT_COOKIE,
    value,
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict' as const,
    maxAge: EIGHT_HOURS,
    path: '/',
  };
}

export async function getTodayOrder(): Promise<OrderCookieData | null> {
  const jar = await cookies();
  const raw = jar.get(ORDER_COOKIE)?.value;
  if (!raw) return null;
  try {
    const order = JSON.parse(raw) as OrderCookieData;
    const today = new Date().toISOString().split('T')[0];
    if (order.date !== today) return null;
    return order;
  } catch {
    return null;
  }
}
