'use client';

import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

interface InviteData {
  id: string;
  firstName: string;
  lastName: string;
}

export default function RegisterPage() {
  return (
    <Suspense fallback={
      <main className="min-h-screen flex items-center justify-center bg-zinc-950">
        <p className="text-zinc-400">Loading…</p>
      </main>
    }>
      <RegisterForm />
    </Suspense>
  );
}

function RegisterForm() {
  const router = useRouter();
  const params = useSearchParams();
  const token = params.get('t');

  const [invite, setInvite] = useState<InviteData | null>(null);
  const [tokenError, setTokenError] = useState('');
  const [phone, setPhone] = useState('');
  const [termsAccepted, setTermsAccepted] = useState(false);
  const [step, setStep] = useState<'loading' | 'form' | 'phone-only'>('loading');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!token) {
      setStep('phone-only');
      return;
    }
    fetch(`/api/auth/verify-token?t=${token}`)
      .then((r) => r.json())
      .then((data) => {
        if (data.error) { setTokenError(data.error); setStep('phone-only'); }
        else { setInvite(data); setStep('form'); }
      })
      .catch(() => { setTokenError('Unable to validate link. Please try again.'); setStep('phone-only'); });
  }, [token]);

  function formatPhone(raw: string): string {
    const trimmed = raw.trim();
    // Already E.164 — accept as-is
    if (/^\+\d{7,15}$/.test(trimmed)) return trimmed;
    const digits = trimmed.replace(/\D/g, '');
    // US: 10 digits or 11 starting with 1
    if (digits.length === 10) return `+1${digits}`;
    if (digits.length === 11 && digits[0] === '1') return `+${digits}`;
    // UK: 11 digits starting with 07 → +44 7...
    if (digits.length === 11 && digits.startsWith('07')) return `+44${digits.slice(1)}`;
    // UK: 10 digits starting with 7 (already dropped leading 0)
    if (digits.length === 10 && digits.startsWith('7')) return `+44${digits}`;
    // UK: 12 digits starting with 44
    if (digits.length === 12 && digits.startsWith('44')) return `+${digits}`;
    return '';
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const e164 = formatPhone(phone);
    if (!e164) { setError('Enter a valid US or UK phone number.'); return; }
    if (step === 'form' && !termsAccepted) { setError('You must accept the terms to continue.'); return; }

    setSubmitting(true);
    setError('');
    const res = await fetch('/api/auth/send-otp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: e164, ...(invite ? { inviteId: invite.id } : {}) }),
    });
    const data = await res.json();
    if (!res.ok) { setError(data.error ?? 'Failed to proceed.'); setSubmitting(false); return; }

    // ── SMS disabled — OTP verify step commented out ─────────────────────────
    // sessionStorage.setItem('tsa_phone', e164);
    // if (invite) sessionStorage.setItem('tsa_invite_id', invite.id);
    // router.push('/register/verify');
    // ─────────────────────────────────────────────────────────────────────────

    router.push('/');
  }

  if (step === 'loading') {
    return (
      <main className="min-h-screen flex items-center justify-center bg-zinc-950">
        <p className="text-zinc-400">Validating your registration link…</p>
      </main>
    );
  }

  return (
    <main className="min-h-screen flex items-center justify-center bg-zinc-950 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex justify-center">
          <img src="https://harriercentral.blob.core.windows.net/harrier/tsaEatsLogo.png" alt="TSA Eats" className="w-80" />
        </div>

        <div className="bg-zinc-900 rounded-2xl p-6 border border-zinc-800">
          {tokenError && (
            <div className="mb-4 p-3 bg-red-950 border border-red-800 rounded-lg text-red-300 text-sm">{tokenError}</div>
          )}

          {invite ? (
            <p className="text-zinc-300 mb-4">
              Welcome, <span className="text-white font-semibold">{invite.firstName} {invite.lastName}</span>.
              Enter your mobile number to complete registration.
            </p>
          ) : (
            <p className="text-zinc-300 mb-4">Enter your mobile number to access your account.</p>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm text-zinc-400 mb-1">Mobile phone number</label>
              <input
                type="tel"
                placeholder="(555) 555-5555"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-4 py-2.5 text-white placeholder-zinc-500 focus:outline-none focus:border-blue-500"
                required
              />
            </div>

            {step === 'form' && (
              <label className="flex items-start gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={termsAccepted}
                  onChange={(e) => setTermsAccepted(e.target.checked)}
                  className="mt-0.5 accent-blue-500"
                />
                <span className="text-sm text-zinc-400">
                  I agree to the{' '}
                  <a href="/terms" className="text-blue-400 underline">Terms of Service</a>
                  {' '}and{' '}
                  <a href="/privacy" className="text-blue-400 underline">Privacy Policy</a>.
                  I understand this service is only available to active TSA employees during a government shutdown.
                </span>
              </label>
            )}

            {error && <p className="text-red-400 text-sm">{error}</p>}

            <button
              type="submit"
              disabled={submitting}
              className="w-full bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white font-semibold rounded-lg py-2.5 transition-colors"
            >
              {submitting ? 'Continuing…' : 'Continue'}
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}
