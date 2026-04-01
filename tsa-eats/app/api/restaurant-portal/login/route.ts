import { NextRequest, NextResponse } from 'next/server';
import { restaurantLogin } from '@/lib/api';
import { makeRestaurantCookieValue, restaurantCookieOptions } from '@/lib/session';

export async function POST(req: NextRequest) {
  const { password } = await req.json();

  if (!password) {
    return NextResponse.json({ error: 'Password required.' }, { status: 400 });
  }

  const rows = await restaurantLogin(password);
  const restaurant = rows?.[0];

  if (!restaurant) {
    return NextResponse.json({ error: 'Incorrect password.' }, { status: 401 });
  }

  const token = makeRestaurantCookieValue(restaurant.restaurantId);
  const res = NextResponse.json({ ok: true });
  res.cookies.set(restaurantCookieOptions(token));
  return res;
}
