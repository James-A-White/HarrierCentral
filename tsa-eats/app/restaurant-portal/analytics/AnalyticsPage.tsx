'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { RedemptionDetail, RedemptionSummaryRow } from '@/lib/api';

function formatDate(dateStr: string) {
  return new Date(dateStr + 'T00:00:00Z').toLocaleDateString('en-US', {
    weekday: 'long', month: 'long', day: 'numeric', timeZone: 'UTC',
  });
}

function formatTime(isoStr: string) {
  return new Date(isoStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function groupBy<T>(items: T[], key: (item: T) => string): [string, T[]][] {
  const map = new Map<string, T[]>();
  for (const item of items) {
    const k = key(item);
    if (!map.has(k)) map.set(k, []);
    map.get(k)!.push(item);
  }
  return Array.from(map.entries());
}

export default function AnalyticsPage({
  detail,
  summary,
  showRestaurant,
  backHref,
}: {
  detail: RedemptionDetail[];
  summary: RedemptionSummaryRow[];
  showRestaurant: boolean;
  backHref: string;
}) {
  const router = useRouter();
  const [view, setView] = useState<'detail' | 'summary'>('detail');

  const detailByDate = groupBy(detail, (r) => r.date);
  const summaryByDate = groupBy(summary, (r) => r.date);

  const totalRedeemed = detail.length;

  return (
    <main className="min-h-screen bg-zinc-950">
      <header className="sticky top-0 bg-zinc-950/90 backdrop-blur border-b border-zinc-800 z-10">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
          <h1 className="text-white font-bold">Analytics</h1>
          <button
            onClick={() => router.push(backHref)}
            className="text-zinc-400 hover:text-white text-sm transition-colors"
          >
            ← Back
          </button>
        </div>
      </header>

      <div className="max-w-2xl mx-auto px-4 py-6 space-y-4">

        {/* View toggle */}
        <div className="flex gap-2">
          <button
            onClick={() => setView('detail')}
            className={`flex-1 py-2 rounded-xl text-sm font-medium transition-colors ${
              view === 'detail'
                ? 'bg-blue-600 text-white'
                : 'bg-zinc-800 text-zinc-400 hover:text-white'
            }`}
          >
            Individual meals
          </button>
          <button
            onClick={() => setView('summary')}
            className={`flex-1 py-2 rounded-xl text-sm font-medium transition-colors ${
              view === 'summary'
                ? 'bg-blue-600 text-white'
                : 'bg-zinc-800 text-zinc-400 hover:text-white'
            }`}
          >
            Meals by day
          </button>
        </div>

        {totalRedeemed === 0 && (
          <p className="text-zinc-500 text-sm text-center py-12">No meals redeemed yet.</p>
        )}

        {/* Detail view */}
        {view === 'detail' && detailByDate.map(([date, rows]) => (
          <div key={date} className="bg-zinc-900 rounded-2xl border border-zinc-800 overflow-hidden">
            <div className="px-5 py-3 border-b border-zinc-800 flex items-center justify-between">
              <p className="text-white font-semibold text-sm">{formatDate(date)}</p>
              <p className="text-zinc-500 text-xs">{rows.length} meal{rows.length !== 1 ? 's' : ''}</p>
            </div>
            <div className="divide-y divide-zinc-800">
              {rows.map((row, i) => (
                <div key={i} className="px-5 py-3 flex items-center justify-between gap-4">
                  <div>
                    <p className="text-white text-sm">{row.firstName} {row.lastName}</p>
                    {showRestaurant && (
                      <p className="text-zinc-500 text-xs">{row.restaurantName}</p>
                    )}
                    <p className="text-zinc-400 text-xs">{row.mealName}</p>
                  </div>
                  <p className="text-zinc-500 text-xs shrink-0">{formatTime(row.redeemedAt)}</p>
                </div>
              ))}
            </div>
          </div>
        ))}

        {/* Summary view */}
        {view === 'summary' && summaryByDate.map(([date, rows]) => {
          const dayTotal = rows.reduce((sum, r) => sum + Number(r.count), 0);
          return (
            <div key={date} className="bg-zinc-900 rounded-2xl border border-zinc-800 overflow-hidden">
              <div className="px-5 py-3 border-b border-zinc-800 flex items-center justify-between">
                <p className="text-white font-semibold text-sm">{formatDate(date)}</p>
                <p className="text-zinc-500 text-xs">{dayTotal} total</p>
              </div>
              <div className="divide-y divide-zinc-800">
                {rows.map((row, i) => (
                  <div key={i} className="px-5 py-3 flex items-center justify-between gap-4">
                    <div>
                      {showRestaurant && (
                        <p className="text-zinc-500 text-xs">{row.restaurantName}</p>
                      )}
                      <p className="text-white text-sm">{row.mealName}</p>
                    </div>
                    <p className="text-zinc-400 text-sm font-semibold shrink-0">× {row.count}</p>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </main>
  );
}
