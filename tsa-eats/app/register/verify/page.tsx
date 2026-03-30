'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function VerifyPage() {
  const router = useRouter();
  const [otp, setOtp] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!/^\d{6}$/.test(otp)) { setError('Enter the 6-digit code from your SMS.'); return; }

    const phoneNumber = sessionStorage.getItem('tsa_phone');
    const inviteId = sessionStorage.getItem('tsa_invite_id');
    if (!phoneNumber) { router.push('/register'); return; }

    setSubmitting(true);
    setError('');

    const res = await fetch('/api/auth/verify-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber, otp, inviteId }),
    });
    const data = await res.json();

    if (!res.ok) { setError(data.error ?? 'Incorrect code. Please try again.'); setSubmitting(false); return; }

    sessionStorage.removeItem('tsa_phone');
    sessionStorage.removeItem('tsa_invite_id');
    router.push('/');
  }

  async function handleResend() {
    const phoneNumber = sessionStorage.getItem('tsa_phone');
    if (!phoneNumber) { router.push('/register'); return; }
    await fetch('/api/auth/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber }),
    });
    setError('');
    setOtp('');
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-zinc-950 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-white mb-2">TSA Eats</h1>
          <p className="text-zinc-400 text-sm">Enter the 6-digit code we sent to your phone</p>
        </div>

        <div className="bg-zinc-900 rounded-2xl p-6 border border-zinc-800">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm text-zinc-400 mb-1">Verification code</label>
              <input
                type="text"
                inputMode="numeric"
                pattern="\d{6}"
                maxLength={6}
                placeholder="000000"
                value={otp}
                onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-4 py-2.5 text-white text-center text-2xl tracking-widest placeholder-zinc-600 focus:outline-none focus:border-blue-500"
                autoFocus
                required
              />
            </div>

            {error && <p className="text-red-400 text-sm">{error}</p>}

            <button
              type="submit"
              disabled={submitting}
              className="w-full bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white font-semibold rounded-lg py-2.5 transition-colors"
            >
              {submitting ? 'Verifying…' : 'Verify'}
            </button>

            <button
              type="button"
              onClick={handleResend}
              className="w-full text-zinc-400 hover:text-zinc-200 text-sm py-1 transition-colors"
            >
              Resend code
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}
