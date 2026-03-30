import { NextRequest, NextResponse } from 'next/server';
import { generateOtp, hashOtp } from '@/lib/otp';
import { createOtp } from '@/lib/api';
import { sendOtpSms } from '@/lib/twilio';

export async function POST(req: NextRequest) {
  const { phoneNumber } = await req.json();

  if (!phoneNumber || !/^\+1\d{10}$/.test(phoneNumber)) {
    return NextResponse.json({ error: 'Enter a valid US phone number.' }, { status: 400 });
  }

  const otp = generateOtp();
  const otpHash = hashOtp(otp);

  const rows = await createOtp(phoneNumber, otpHash);
  const result = rows?.[0];
  if (!result || Number(result.Success) === 0) {
    return NextResponse.json({ error: result?.ErrorMessage ?? 'Failed to create OTP.' }, { status: 500 });
  }

  await sendOtpSms(phoneNumber, otp);

  return NextResponse.json({ ok: true });
}
