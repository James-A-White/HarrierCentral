'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { OrderDetails } from '@/lib/api';

export default function ScanPage({
  order,
  token,
}: {
  order: OrderDetails;
  token: string;
}) {
  const router = useRouter();
  const [redeeming, setRedeeming] = useState(false);
  const [error, setError] = useState('');
  const [redeemed, setRedeemed] = useState(!!order.redeemedAt);
  const [redeemedAt, setRedeemedAt] = useState<string | null>(order.redeemedAt);

  const isExpired = order.date !== new Date().toISOString().split('T')[0];

  async function handleRedeem() {
    setRedeeming(true);
    setError('');
    const res = await fetch(`/api/restaurant-portal/redeem/${token}`, { method: 'POST' });
    const data = await res.json();
    if (!res.ok) {
      setError(data.error ?? 'Redemption failed.');
      setRedeeming(false);
      return;
    }
    setRedeemed(true);
    setRedeemedAt(new Date().toISOString());
    setRedeeming(false);
  }

  return (
    <main className="min-h-screen bg-zinc-950">
      <header className="sticky top-0 bg-zinc-950/90 backdrop-blur border-b border-zinc-800 z-10">
        <div className="max-w-lg mx-auto px-4 py-3 flex items-center justify-between">
          <h1 className="text-white font-bold">TSA Eats — Order</h1>
          <button
            onClick={() => router.push('/')}
            className="text-zinc-400 hover:text-white text-sm transition-colors"
          >
            ← Back
          </button>
        </div>
      </header>

      <div className="max-w-lg mx-auto px-4 py-8 space-y-6">

        {/* Status banner */}
        {isExpired ? (
          <StatusBanner colour="yellow" icon="⚠️" title="Expired" detail="This order is not from today." />
        ) : redeemed ? (
          <StatusBanner colour="green" icon="✅" title="Redeemed"
            detail={`Collected at ${redeemedAt ? new Date(redeemedAt).toLocaleTimeString() : 'unknown time'}`} />
        ) : (
          <StatusBanner colour="blue" icon="🎟️" title="Valid order" detail="Ready to redeem" />
        )}

        {/* Order details */}
        <div className="bg-zinc-900 rounded-2xl border border-zinc-800 p-5 space-y-4">
          <DetailRow label="Name"        value={`${order.firstName} ${order.lastName}`} highlight />
          <DetailRow label="Restaurant"  value={order.restaurantName} />
          <DetailRow label="Meal"        value={order.mealName} />
          <DetailRow label="Date"        value={order.date} />
        </div>

        {/* Redeem button */}
        {!redeemed && !isExpired && (
          <>
            {error && <p className="text-red-400 text-sm">{error}</p>}
            <button
              onClick={handleRedeem}
              disabled={redeeming}
              className="w-full bg-green-600 hover:bg-green-500 disabled:opacity-50 text-white text-lg font-bold rounded-2xl py-4 transition-colors"
            >
              {redeeming ? 'Redeeming…' : 'Redeem meal'}
            </button>
            <p className="text-zinc-600 text-xs text-center">
              Ask the worker to show a valid ID matching the name above before redeeming.
            </p>
          </>
        )}
      </div>
    </main>
  );
}

function StatusBanner({ colour, icon, title, detail }: {
  colour: 'blue' | 'green' | 'yellow';
  icon: string;
  title: string;
  detail: string;
}) {
  const styles = {
    blue:   'bg-blue-950 border-blue-800 text-blue-200',
    green:  'bg-green-950 border-green-800 text-green-200',
    yellow: 'bg-yellow-950 border-yellow-800 text-yellow-200',
  };
  return (
    <div className={`rounded-2xl border p-4 flex items-center gap-3 ${styles[colour]}`}>
      <span className="text-2xl">{icon}</span>
      <div>
        <p className="font-semibold">{title}</p>
        <p className="text-sm opacity-75">{detail}</p>
      </div>
    </div>
  );
}

function DetailRow({ label, value, highlight }: { label: string; value: string; highlight?: boolean }) {
  return (
    <div className="flex justify-between items-center gap-4">
      <span className="text-zinc-500 text-sm">{label}</span>
      <span className={`text-sm font-medium text-right ${highlight ? 'text-white text-base' : 'text-zinc-200'}`}>
        {value}
      </span>
    </div>
  );
}
