// Twilio SMS helper — server-side only.

import twilio from 'twilio';

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID!,
  process.env.TWILIO_AUTH_TOKEN!
);

export async function sendOtpSms(to: string, otp: string): Promise<void> {
  await client.messages.create({
    body: `Your TSA Eats verification code is: ${otp}. Valid for 10 minutes. Do not share this code.`,
    from: process.env.TWILIO_FROM_NUMBER!,
    to,
  });
}
