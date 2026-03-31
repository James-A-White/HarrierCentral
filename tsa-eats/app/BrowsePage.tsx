'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { Restaurant, MenuItem, WorkerSession } from '@/lib/api';

const SERVICE_LABELS: Record<string, string> = {
  pickup: 'Pickup',
  delivery: 'Delivery',
  'dine-in': 'Dine-in',
  'food-truck': 'Food truck',
};

export default function BrowsePage({
  worker,
  restaurants,
  menuItemsMap,
}: {
  worker: WorkerSession;
  restaurants: Restaurant[];
  menuItemsMap: Record<string, MenuItem[]>;
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
        <div className="space-y-4">
          {filtered.map((r) => {
            const meals = menuItemsMap[r.id]?.filter((m) => m.isAvailable) ?? [];
            return (
              <div
                key={r.id}
                className="bg-zinc-900 rounded-2xl border border-zinc-800 overflow-hidden"
              >
                {/* Restaurant image */}
                {r.imageUrl ? (
                  <img
                    src={r.imageUrl}
                    alt={r.name}
                    className="w-full h-44 object-cover"
                  />
                ) : (
                  <div className="w-full h-44 bg-zinc-800 flex items-center justify-center">
                    <span className="text-zinc-600 text-sm">No image</span>
                  </div>
                )}

                <div className="p-5">
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

                  {/* Available meals */}
                  {meals.length > 0 && (
                    <div className="mt-4">
                      <p className="text-zinc-400 text-xs font-medium uppercase tracking-wide mb-2">
                        Available meals
                      </p>
                      <ul className="space-y-1">
                        {meals.slice(0, 3).map((m) => (
                          <li key={m.id} className="text-zinc-300 text-sm flex items-center gap-2">
                            <span className="w-1 h-1 rounded-full bg-zinc-500 flex-shrink-0" />
                            {m.name}
                          </li>
                        ))}
                        {meals.length > 3 && (
                          <li className="text-zinc-500 text-sm pl-3">
                            +{meals.length - 3} more
                          </li>
                        )}
                      </ul>
                    </div>
                  )}

                  <button
                    onClick={() => router.push(`/restaurant/${r.id}`)}
                    className="mt-4 w-full bg-blue-600 hover:bg-blue-500 text-white text-sm font-medium rounded-lg py-2.5 transition-colors"
                  >
                    View menu &amp; select meal
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        {filtered.length === 0 && (
          <p className="text-zinc-500 text-sm text-center py-8">No restaurants match your search.</p>
        )}
      </div>
    </main>
  );
}
