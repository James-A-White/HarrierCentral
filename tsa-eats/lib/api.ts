// Server-side only — do not import in 'use client' components.

const TSA_API_URL = process.env.TSA_API_URL ?? '';
const TSA_API_KEY = process.env.TSA_API_KEY ?? '';

async function callGet<T>(queryType: string, params: Record<string, string> = {}): Promise<T[] | null> {
  const qs = new URLSearchParams({ queryType, ...params }).toString();
  const res = await fetch(`${TSA_API_URL}/api/TsaApi?${qs}`, { cache: 'no-store' });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`TsaApi GET ${queryType} failed: ${res.status}`);
  const data = await res.json() as T[][];
  return data[0] ?? [];
}

async function callPost<T>(queryType: string, body: Record<string, unknown>): Promise<T[] | null> {
  const res = await fetch(`${TSA_API_URL}/api/TsaApi`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Api-Key': TSA_API_KEY,
    },
    body: JSON.stringify({ queryType, ...body }),
    cache: 'no-store',
  });
  if (res.status === 404) return null;
  if (!res.ok) {
    const err = await res.json().catch(() => ({})) as { errorMessage?: string };
    throw new Error(err.errorMessage ?? `TsaApi POST ${queryType} failed: ${res.status}`);
  }
  const data = await res.json() as T[][];
  return data[0] ?? [];
}

// ── Types ────────────────────────────────────────────────────────────

export interface Restaurant {
  id: string;
  name: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  cuisineType: string | null;
  serviceTypes: string | null;
  description: string | null;
  imageUrl: string | null;
  dailyQuota: number;
}

export interface MenuItem {
  id: string;
  restaurantId: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  dailyQuota: number;
  isAvailable: boolean;
}

export interface Invite {
  id: string;
  firstName: string;
  lastName: string;
  createdByAdmin: string;
  createdAt: string;
  expiresAt: string;
  usedAt: string | null;
  status: 'Pending' | 'Registered' | 'Expired';
}

export interface WorkerSession {
  workerId: string;
  firstName: string;
  lastName: string;
  status: string;
}

// ── Public API ───────────────────────────────────────────────────────

export async function getRestaurants(): Promise<Restaurant[]> {
  return (await callGet<Restaurant>('getRestaurants')) ?? [];
}

export async function getMenuItems(restaurantId: string): Promise<MenuItem[]> {
  return (await callGet<MenuItem>('getMenuItems', { restaurantId })) ?? [];
}

// ── Auth API (server-side only) ──────────────────────────────────────

export async function validateInviteToken(token: string) {
  return callPost<{ Success?: number; ErrorMessage?: string | null; id: string; firstName: string; lastName: string }>(
    'validateInviteToken', { token }
  );
}

export async function createOtp(phoneNumber: string, otpHash: string) {
  return callPost<{ Success: number; ErrorMessage: string | null }>(
    'createOtp', { phoneNumber, otpHash }
  );
}

export async function validateOtp(phoneNumber: string, otpHash: string) {
  return callPost<{ Success: number; ErrorMessage: string | null; workerId: string | null }>(
    'validateOtp', { phoneNumber, otpHash }
  );
}

export async function createWorkerAndSession(
  inviteId: string, phoneNumber: string, termsAcceptedAt: string
) {
  return callPost<{ Success: number; ErrorMessage: string | null; sessionId: string; workerId: string; firstName: string; lastName: string }>(
    'createWorkerAndSession', { inviteId, phoneNumber, termsAcceptedAt }
  );
}

export async function createReturnSession(workerId: string) {
  return callPost<{ Success: number; ErrorMessage: string | null; sessionId: string; firstName: string; lastName: string }>(
    'createReturnSession', { workerId }
  );
}

export async function validateSession(sessionId: string): Promise<WorkerSession | null> {
  const rows = await callPost<WorkerSession>('validateSession', { sessionId });
  return rows?.[0] ?? null;
}

// ── Admin API ────────────────────────────────────────────────────────

export async function createInvite(firstName: string, lastName: string, createdByAdmin: string) {
  return callPost<{ id: string; token: string; firstName: string; lastName: string; expiresAt: string }>(
    'createInvite', { firstName, lastName, createdByAdmin }
  );
}

export async function listInvites(): Promise<Invite[]> {
  return (await callPost<Invite>('listInvites', {})) ?? [];
}

// ── Order API ────────────────────────────────────────────────────────

export interface OrderDetails {
  token: string;
  firstName: string;
  lastName: string;
  restaurantName: string;
  mealName: string;
  date: string;
  redeemedAt: string | null;
}

export async function createOrder(workerId: string, restaurantId: string, mealId: string) {
  return callPost<{ token: string; Success: number; ErrorMessage: string | null }>(
    'createOrder', { workerId, restaurantId, mealId }
  );
}

export async function getOrderByToken(token: string): Promise<OrderDetails | null> {
  const rows = await callGet<OrderDetails>('getOrderByToken', { token });
  return rows?.[0] ?? null;
}

export async function redeemOrder(token: string) {
  return callPost<{ Success: number; ErrorMessage: string | null }>(
    'redeemOrder', { token }
  );
}
