import { NextRequest, NextResponse } from 'next/server';
// ── SMS disabled — re-enable these imports when SMS infrastructure is active ──
// import { generateOtp, hashOtp } from '@/lib/otp';
// import { createOtp } from '@/lib/api';
// import { sendOtpSms } from '@/lib/twilio';
// ─────────────────────────────────────────────────────────────────────────────
import { createWorkerAndSession } from '@/lib/api';
import { sessionCookieOptions } from '@/lib/session';

export async function POST(req: NextRequest) {
  try {
    const { phoneNumber, inviteId } = await req.json();

    // Accept any valid E.164 number (US +1 or UK +44)
    if (!phoneNumber || !/^\+(1\d{10}|44\d{10})$/.test(phoneNumber)) {
      return NextResponse.json({ error: 'Enter a valid US or UK phone number.' }, { status: 400 });
    }

    // ── SMS disabled — OTP generation, storage, and sending commented out ────
    // const otp = generateOtp();
    // const otpHash = hashOtp(otp);
    // const rows = await createOtp(phoneNumber, otpHash);
    // const result = rows?.[0];
    // if (!result || Number(result.Success) === 0) {
    //   return NextResponse.json({ error: result?.ErrorMessage ?? 'Failed to create OTP.' }, { status: 500 });
    // }
    // await sendOtpSms(phoneNumber, otp);
    // return NextResponse.json({ ok: true });
    // ─────────────────────────────────────────────────────────────────────────

    // Temporary bypass: create session directly on phone format validation.
    // Once SMS is active, remove this block and restore the OTP flow above.
    if (inviteId) {
      // New registration
      const regRows = await createWorkerAndSession(inviteId, phoneNumber, new Date().toISOString());
      const reg = regRows?.[0];
      if (!reg || Number(reg.Success) === 0) {
        return NextResponse.json({ error: reg?.ErrorMessage ?? 'Registration error.' }, { status: 500 });
      }
      const res = NextResponse.json({ ok: true, firstName: reg.firstName, lastName: reg.lastName });
      res.cookies.set(sessionCookieOptions(reg.sessionId as string));
      return res;
    } else {
      // Returning user — workerId lookup requires OTP validation.
      // Re-enable when SMS infrastructure is active.
      return NextResponse.json(
        { error: 'SMS verification is temporarily unavailable. Please contact support.' },
        { status: 503 }
      );
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('send-otp error:', message);
    const detail = process.env.NODE_ENV === 'development' ? message : 'An unexpected error occurred. Please try again.';
    return NextResponse.json({ error: detail }, { status: 500 });
  }
}
