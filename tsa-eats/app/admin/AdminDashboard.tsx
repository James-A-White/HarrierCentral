'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { Invite } from '@/lib/api';

interface NewInviteResult {
  id: string;
  token: string;
  firstName: string;
  lastName: string;
  expiresAt: string;
  registrationUrl: string;
}

export default function AdminDashboard({ invites: initial }: { invites: Invite[] }) {
  const router = useRouter();
  const [invites, setInvites] = useState(initial);
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [newInvite, setNewInvite] = useState<NewInviteResult | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState('');
  const [copied, setCopied] = useState(false);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    setNewInvite(null);
    setQrDataUrl('');

    const res = await fetch('/api/admin/invite', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ firstName: firstName.trim(), lastName: lastName.trim() }),
    });
    const data = await res.json();

    if (!res.ok) { setError(data.error ?? 'Failed to create invite.'); setSubmitting(false); return; }

    setNewInvite(data);

    // Generate QR code client-side
    const QRCode = (await import('qrcode')).default;
    const url = await QRCode.toDataURL(data.registrationUrl, { width: 300, margin: 2 });
    setQrDataUrl(url);

    setFirstName('');
    setLastName('');
    setSubmitting(false);
    router.refresh();
  }

  async function copyUrl() {
    if (!newInvite) return;
    await navigator.clipboard.writeText(newInvite.registrationUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  const pending = invites.filter((i) => i.status === 'Pending').length;
  const registered = invites.filter((i) => i.status === 'Registered').length;

  return (
    <main className="min-h-screen bg-zinc-950 p-6">
      <div className="max-w-3xl mx-auto space-y-8">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-white">TSA Eats — Admin</h1>
          <div className="flex items-center gap-4">
            <div className="flex gap-4 text-sm text-zinc-400">
              <span><span className="text-white font-medium">{pending}</span> pending</span>
              <span><span className="text-white font-medium">{registered}</span> registered</span>
            </div>
            <a
              href="/analytics"
              className="bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white text-sm font-medium rounded-xl px-4 py-2 transition-colors whitespace-nowrap"
            >
              Analytics →
            </a>
          </div>
        </div>

        {/* Create invite */}
        <div className="bg-zinc-900 rounded-2xl p-6 border border-zinc-800">
          <h2 className="text-lg font-semibold text-white mb-4">Register a TSA Officer</h2>
          <form onSubmit={handleCreate} className="flex gap-3 flex-wrap">
            <input
              placeholder="First name"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              className="flex-1 min-w-36 bg-zinc-800 border border-zinc-700 rounded-lg px-4 py-2 text-white placeholder-zinc-500 focus:outline-none focus:border-blue-500"
              required
            />
            <input
              placeholder="Last name"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              className="flex-1 min-w-36 bg-zinc-800 border border-zinc-700 rounded-lg px-4 py-2 text-white placeholder-zinc-500 focus:outline-none focus:border-blue-500"
              required
            />
            <button
              type="submit"
              disabled={submitting}
              className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white font-semibold rounded-lg px-5 py-2 transition-colors whitespace-nowrap"
            >
              {submitting ? 'Creating…' : 'Create QR'}
            </button>
          </form>
          {error && <p className="mt-3 text-red-400 text-sm">{error}</p>}

          {newInvite && (
            <div className="mt-6 flex gap-6 items-start flex-wrap">
              {qrDataUrl && (
                <div className="bg-white p-3 rounded-xl">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={qrDataUrl} alt="Registration QR code" width={180} height={180} />
                </div>
              )}
              <div className="flex-1 min-w-48 space-y-2">
                <p className="text-white font-medium">{newInvite.firstName} {newInvite.lastName}</p>
                <p className="text-zinc-400 text-xs">Expires: {new Date(newInvite.expiresAt).toLocaleString()}</p>
                <button onClick={copyUrl} className="text-sm text-blue-400 hover:text-blue-300 underline">
                  {copied ? 'Copied!' : 'Copy registration link'}
                </button>
                <p className="text-zinc-500 text-xs break-all">{newInvite.registrationUrl}</p>
              </div>
            </div>
          )}
        </div>

        {/* Invite list */}
        <div className="bg-zinc-900 rounded-2xl p-6 border border-zinc-800">
          <h2 className="text-lg font-semibold text-white mb-4">All Invites</h2>
          {invites.length === 0 ? (
            <p className="text-zinc-500 text-sm">No invites yet.</p>
          ) : (
            <div className="space-y-2">
              {invites.map((inv) => (
                <div key={inv.id} className="flex items-center justify-between py-2 border-b border-zinc-800 last:border-0">
                  <div>
                    <p className="text-white text-sm font-medium">{inv.firstName} {inv.lastName}</p>
                    <p className="text-zinc-500 text-xs">{new Date(inv.createdAt).toLocaleDateString()}</p>
                  </div>
                  <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                    inv.status === 'Registered' ? 'bg-green-900 text-green-300' :
                    inv.status === 'Expired'    ? 'bg-zinc-800 text-zinc-500' :
                                                  'bg-blue-900 text-blue-300'
                  }`}>
                    {inv.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
