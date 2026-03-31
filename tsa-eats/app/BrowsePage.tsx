'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { Restaurant, WorkerSession } from '@/lib/api';

const SERVICE_LABELS: Record<string, string> = {
  pickup: 'Pickup',
  delivery: 'Delivery',
  'dine-in': 'Dine-in',
  'food-truck': 'Food truck',
};

export default function BrowsePage({
  worker,
  restaurants,
}: {
  worker: WorkerSession;
  restaurants: Restaurant[];
}) {
  const router = useRouter();
  const [filter, setFilter] = useState('');
  const [loggingOut, setLoggingOut] = useState(false);

  async function logout() {
    setLoggingOut(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/register');
  }

  const filtered = restaurants.filter((r) => {
    if (!filter) return true;
    return (
      r.cuisineType?.toLowerCase().includes(filter.toLowerCase()) ||
      r.serviceTypes?.toLowerCase().includes(filter.toLowerCase()) ||
      r.name.toLowerCase().includes(filter.toLowerCase())
    );
  });

  return (
    <main className="min-h-screen bg-zinc-950">
      {/* Header */}
      <header className="sticky top-0 bg-zinc-950/90 backdrop-blur border-b border-zinc-800 z-10">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
          <div>
            <h1 className="text-white font-bold">TSA Eats</h1>
            <p className="text-zinc-400 text-xs">Welcome, {worker.firstName}</p>
          </div>
          <button
            onClick={logout}
            disabled={loggingOut}
            className="text-zinc-400 hover:text-white text-sm transition-colors"
          >
            Sign out
          </button>
        </div>
      </header>

      <div className="max-w-2xl mx-auto px-4 py-6 space-y-4">
        {/* Filter */}
        <input
          type="search"
          placeholder="Search by name, cuisine, or service type…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="w-full bg-zinc-900 border border-zinc-800 rounded-xl px-4 py-2.5 text-white placeholder-zinc-500 focus:outline-none focus:border-blue-500"
        />

        <p className="text-zinc-500 text-sm">{filtered.length} restaurant{filtered.length !== 1 ? 's' : ''} available</p>

        {/* Restaurant cards */}
        <div className="space-y-3">
          {filtered.map((r) => (
            <div key={r.id} className="bg-zinc-900 rounded-2xl p-5 border border-zinc-800">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <h2 className="text-white font-semibold truncate">{r.name}</h2>
                  <p className="text-zinc-400 text-sm mt-0.5">{r.address}</p>
                  {r.description && (
                    <p className="text-zinc-500 text-sm mt-2 line-clamp-2">{r.description}</p>
                  )}
                  <div className="flex flex-wrap gap-1.5 mt-3">
                    {r.cuisineType && (
                      <span className="bg-zinc-800 text-zinc-300 text-xs px-2 py-0.5 rounded-full">
                        {r.cuisineType}
                      </span>
                    )}
                    {r.serviceTypes?.split(',').map((s) => (
                      <span key={s} className="bg-blue-950 text-blue-300 text-xs px-2 py-0.5 rounded-full">
                        {SERVICE_LABELS[s.trim()] ?? s.trim()}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
              <button className="mt-4 w-full bg-zinc-800 hover:bg-zinc-700 text-white text-sm font-medium rounded-lg py-2 transition-colors">
                View menu & reserve
              </button>
            </div>
          ))}
        </div>

        {filtered.length === 0 && (
          <p className="text-zinc-500 text-sm text-center py-8">No restaurants match your search.</p>
        )}
      </div>
    </main>
  );
}
