import { NextRequest, NextResponse } from 'next/server';
import { timingSafeEqual } from 'crypto';
import { makeRestaurantCookieValue, restaurantCookieOptions } from '@/lib/session';

export async function POST(req: NextRequest) {
  const { password } = await req.json();

  const expected = process.env.RESTAURANT_PASSWORD ?? '';
  if (!expected) {
    return NextResponse.json({ error: 'Restaurant portal not configured.' }, { status: 500 });
  }

  let match = false;
  try {
    match = timingSafeEqual(Buffer.from(password ?? ''), Buffer.from(expected));
  } catch {
    match = false;
  }

  if (!match) {
    return NextResponse.json({ error: 'Incorrect password.' }, { status: 401 });
  }

  const token = makeRestaurantCookieValue();
  const res = NextResponse.json({ ok: true });
  res.cookies.set(restaurantCookieOptions(token));
  return res;
}
