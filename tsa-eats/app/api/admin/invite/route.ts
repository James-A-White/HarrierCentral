import { NextRequest, NextResponse } from 'next/server';
import { createInvite } from '@/lib/api';
import { getAdminSession } from '@/lib/session';

export async function POST(req: NextRequest) {
  if (!(await getAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized.' }, { status: 401 });
  }

  const { firstName, lastName } = await req.json();
  if (!firstName?.trim() || !lastName?.trim()) {
    return NextResponse.json({ error: 'First and last name are required.' }, { status: 400 });
  }

  const rows = await createInvite(firstName.trim(), lastName.trim(), 'admin');
  const invite = rows?.[0];
  if (!invite) {
    return NextResponse.json({ error: 'Failed to create invite.' }, { status: 500 });
  }

  const registrationUrl = `https://login.tsaeats.org?t=${invite.token}`;

  return NextResponse.json({ ...invite, registrationUrl });
}
