// OTP generation and hashing — server-side only.

import { createHash, randomInt } from 'crypto';

export function generateOtp(): string {
  return randomInt(100000, 999999).toString();
}

export function hashOtp(otp: string): string {
  return createHash('sha256').update(otp).digest('hex');
}
