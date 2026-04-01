'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function RestaurantLoginPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    const res = await fetch('/api/restaurant-portal/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password }),
    });
    const data = await res.json();

    if (!res.ok) { setError(data.error ?? 'Incorrect password.'); setSubmitting(false); return; }
    router.push('/');
  }

  return (
    <main className="min-h-screen bg-zinc-950">
      <img src="https://harriercentral.blob.core.windows.net/harrier/tsaEatsLogo.jpg" alt="TSA Eats" className="w-full h-auto block" />
      <div className="flex items-center justify-center p-4 py-8">
      <div className="w-full max-w-sm">
        <div className="bg-zinc-900 rounded-2xl p-6 border border-zinc-800">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm text-zinc-400 mb-1">Passphrase</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:border-blue-500"
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
              {submitting ? 'Signing in…' : 'Sign in'}
            </button>
          </form>
        </div>
      </div>
      </div>
    </main>
  );
}
