// Twilio SMS helper — server-side only.

import twilio from 'twilio';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID!,
  process.env.TWILIO_AUTH_TOKEN!
);

function fromNumber(to: string): string {
  if (to.startsWith('+44')) {
    // UK requires an alphanumeric sender ID — phone numbers are rejected by UK carriers
    return process.env.TWILIO_ALPHA_SENDER_UK ?? process.env.TWILIO_FROM_NUMBER!;
  }
  return process.env.TWILIO_FROM_NUMBER!;
}

export async function sendOtpSms(to: string, otp: string): Promise<void> {
  await client.messages.create({
    body: `Your TSA Eats verification code is: ${otp}. Valid for 10 minutes. Do not share this code.`,
    from: fromNumber(to),
    to,
  });
}
