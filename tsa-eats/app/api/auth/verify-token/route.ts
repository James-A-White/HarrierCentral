import { NextRequest, NextResponse } from 'next/server';
import { validateInviteToken } from '@/lib/api';

export async function GET(req: NextRequest) {
  const token = req.nextUrl.searchParams.get('t');
  if (!token) return NextResponse.json({ error: 'Missing token.' }, { status: 400 });

  const rows = await validateInviteToken(token);
  const result = rows?.[0];

  if (!result) {
    return NextResponse.json({ error: 'Invalid registration link.' }, { status: 404 });
  }

  // Check for error envelope
  if ('Success' in result && Number(result.Success) === 0) {
    return NextResponse.json({ error: result.ErrorMessage }, { status: 400 });
  }

  return NextResponse.json({ id: result.id, firstName: result.firstName, lastName: result.lastName });
}
