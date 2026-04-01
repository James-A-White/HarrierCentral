'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import type { WorkerSession } from '@/lib/api';
import type { OrderCookieData } from '@/lib/session';

export default function OrderQrPage({
  worker,
  order,
}: {
  worker: WorkerSession;
  order: OrderCookieData;
}) {
  const router = useRouter();
  const [qrDataUrl, setQrDataUrl] = useState('');

  useEffect(() => {
    const qrContent = `https://restaurant.tsaeats.org/scan/${order.token}`;

    import('qrcode').then(({ default: QRCode }) => {
      QRCode.toDataURL(qrContent, { width: 280, margin: 2, color: { dark: '#000', light: '#fff' } })
        .then(setQrDataUrl);
    });
  }, [order]);

  return (
    <main className="min-h-screen bg-zinc-950">
      <img src="https://harriercentral.blob.core.windows.net/harrier/tsaEatsLogo.jpg" alt="TSA Eats" className="w-full h-auto block" />
      <header className="sticky top-0 bg-zinc-950/90 backdrop-blur border-b border-zinc-800 z-10">
        <div className="max-w-2xl mx-auto px-4 py-3 flex items-center justify-between">
          <div>
            <h1 className="text-white font-bold">TSA Eats</h1>
            <p className="text-zinc-400 text-xs">Welcome, {worker.firstName}</p>
          </div>
          <button
            onClick={async () => {
              await fetch('/api/auth/logout', { method: 'POST' });
              router.push('/register');
            }}
            className="text-zinc-400 hover:text-white text-sm transition-colors"
          >
            Sign out
          </button>
        </div>
      </header>

      <div className="max-w-2xl mx-auto px-4 py-8 flex flex-col items-center gap-6">
        <div className="text-center">
          <h2 className="text-white text-xl font-bold">Your meal is reserved</h2>
          <p className="text-zinc-400 text-sm mt-1">Show this QR code when you collect your meal</p>
        </div>

        {/* QR code */}
        <div className="bg-white p-4 rounded-2xl shadow-lg">
          {qrDataUrl ? (
            <img src={qrDataUrl} alt="Meal QR code" width={280} height={280} />
          ) : (
            <div className="w-[280px] h-[280px] flex items-center justify-center">
              <p className="text-zinc-400 text-sm">Generating…</p>
            </div>
          )}
        </div>

        {/* Order details */}
        <div className="w-full bg-zinc-900 rounded-2xl border border-zinc-800 p-5 space-y-3">
          <DetailRow label="Name" value={order.workerName} />
          <DetailRow label="Restaurant" value={order.restaurantName} />
          <DetailRow label="Meal" value={order.mealName} />
          <DetailRow label="Date" value={order.date} />
        </div>

        <p className="text-zinc-600 text-xs text-center">
          This QR code is valid for today only. A new meal can be selected tomorrow.
        </p>
      </div>
    </main>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between items-center gap-4">
      <span className="text-zinc-500 text-sm">{label}</span>
      <span className="text-white text-sm font-medium text-right">{value}</span>
    </div>
  );
}
