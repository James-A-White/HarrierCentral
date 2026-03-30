import { NextRequest, NextResponse } from 'next/server';
import { timingSafeEqual } from 'crypto';
import { makeAdminCookieValue, adminCookieOptions } from '@/lib/session';

export async function POST(req: NextRequest) {
  const { password } = await req.json();

  const expected = process.env.ADMIN_PASSWORD ?? '';
  if (!expected) {
    return NextResponse.json({ error: 'Admin not configured.' }, { status: 500 });
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

  const token = makeAdminCookieValue();
  const res = NextResponse.json({ ok: true });
  res.cookies.set(adminCookieOptions(token));
  return res;
}
