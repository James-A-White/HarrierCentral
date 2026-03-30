import { NextRequest, NextResponse } from 'next/server';
import { hashOtp } from '@/lib/otp';
import { validateOtp, createWorkerAndSession, createReturnSession } from '@/lib/api';
import { sessionCookieOptions } from '@/lib/session';

export async function POST(req: NextRequest) {
  const { phoneNumber, otp, inviteId } = await req.json();

  if (!phoneNumber || !otp) {
    return NextResponse.json({ error: 'Missing required fields.' }, { status: 400 });
  }

  const otpHash = hashOtp(otp);
  const rows = await validateOtp(phoneNumber, otpHash);
  const result = rows?.[0];

  if (!result || Number(result.Success) === 0) {
    return NextResponse.json({ error: result?.ErrorMessage ?? 'Invalid code.' }, { status: 400 });
  }

  const workerId = result.workerId as string | null;
  let sessionId: string;
  let firstName: string;
  let lastName: string;

  if (workerId) {
    // Returning user — create a new session
    const sessionRows = await createReturnSession(workerId);
    const session = sessionRows?.[0];
    if (!session || Number(session.Success) === 0) {
      return NextResponse.json({ error: session?.ErrorMessage ?? 'Session error.' }, { status: 500 });
    }
    sessionId = session.sessionId as string;
    firstName = session.firstName as string;
    lastName = session.lastName as string;
  } else {
    // New registration — needs inviteId
    if (!inviteId) {
      return NextResponse.json({ error: 'Invite ID required for new registration.' }, { status: 400 });
    }
    const regRows = await createWorkerAndSession(inviteId, phoneNumber, new Date().toISOString());
    const reg = regRows?.[0];
    if (!reg || Number(reg.Success) === 0) {
      return NextResponse.json({ error: reg?.ErrorMessage ?? 'Registration error.' }, { status: 500 });
    }
    sessionId = reg.sessionId as string;
    firstName = reg.firstName as string;
    lastName = reg.lastName as string;
  }

  const res = NextResponse.json({ ok: true, firstName, lastName });
  res.cookies.set(sessionCookieOptions(sessionId));
  return res;
}
