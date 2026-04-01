'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { Restaurant, MenuItem, WorkerSession } from '@/lib/api';

export default function RestaurantPage({
  worker,
  restaurant,
  menuItems,
}: {
  worker: WorkerSession;
  restaurant: Restaurant;
  menuItems: MenuItem[];
}) {
  const router = useRouter();
  const [selecting, setSelecting] = useState<string | null>(null);
  const [error, setError] = useState('');

  const available = menuItems.filter((m) => m.isAvailable);

  async function selectMeal(meal: MenuItem) {
    setSelecting(meal.id);
    setError('');
    const res = await fetch('/api/order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        mealId: meal.id,
        mealName: meal.name,
      }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({})) as { error?: string };
      setError(data.error ?? 'Failed to reserve meal. Please try again.');
      setSelecting(null);
      return;
    }
    router.push('/');
  }

  return (
    <main className="min-h-screen bg-zinc-950">
      <img src="https://harriercentral.blob.core.windows.net/harrier/tsaEatsLogo.jpg" alt="TSA Eats" className="w-full h-auto block" />
      <header className="sticky top-0 bg-zinc-950/90 backdrop-blur border-b border-zinc-800 z-10">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="text-zinc-400 hover:text-white transition-colors"
            aria-label="Go back"
          >
            ← Back
          </button>
        </div>
      </header>

      <div className="max-w-2xl mx-auto">
        {/* Restaurant image */}
        {restaurant.imageUrl ? (
          <img
            src={restaurant.imageUrl}
            alt={restaurant.name}
            className="w-full h-56 object-cover"
          />
        ) : (
          <div className="w-full h-56 bg-zinc-800 flex items-center justify-center">
            <span className="text-zinc-600 text-sm">No image</span>
          </div>
        )}

        <div className="px-4 py-6 space-y-6">
          {/* Restaurant info */}
          <div>
            <h1 className="text-white text-2xl font-bold">{restaurant.name}</h1>
            <p className="text-zinc-400 text-sm mt-1">{restaurant.address}</p>
            {restaurant.description && (
              <p className="text-zinc-400 text-sm mt-3">{restaurant.description}</p>
            )}
          </div>

          {/* Meal selection */}
          <div>
            <h2 className="text-white font-semibold mb-3">Select your meal</h2>

            {error && (
              <p className="text-red-400 text-sm mb-3">{error}</p>
            )}

            {available.length === 0 ? (
              <p className="text-zinc-500 text-sm">No meals available right now.</p>
            ) : (
              <div className="space-y-3">
                {available.map((meal) => (
                  <div
                    key={meal.id}
                    className="bg-zinc-900 rounded-2xl border border-zinc-800 p-4"
                  >
                    {meal.imageUrl && (
                      <img
                        src={meal.imageUrl}
                        alt={meal.name}
                        className="w-full h-36 object-cover rounded-xl mb-3"
                      />
                    )}
                    <h3 className="text-white font-semibold">{meal.name}</h3>
                    {meal.description && (
                      <p className="text-zinc-400 text-sm mt-1">{meal.description}</p>
                    )}
                    <button
                      onClick={() => selectMeal(meal)}
                      disabled={selecting !== null}
                      className="mt-3 w-full bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white text-sm font-medium rounded-lg py-2.5 transition-colors"
                    >
                      {selecting === meal.id ? 'Reserving…' : 'Select this meal'}
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
