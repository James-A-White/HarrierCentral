import { redirect } from 'next/navigation';
import { getRestaurantSession } from '@/lib/session';
import Link from 'next/link';

export default async function RestaurantPortalHomePage() {
  if (!(await getRestaurantSession())) redirect('/login');

  return (
    <main className="min-h-screen bg-zinc-950">
      <img src="https://harriercentral.blob.core.windows.net/harrier/tsaEatsLogo.jpg" alt="TSA Eats" className="w-full h-auto block" />
      <div className="flex items-center justify-center p-4 py-8">
      <div className="text-center space-y-6 max-w-sm w-full">
        <div className="text-6xl">📷</div>
        <h1 className="text-white text-2xl font-bold">Ready to scan</h1>
        <p className="text-zinc-400 text-sm">
          Use your camera to scan a worker&apos;s QR code. The order details and redeem
          button will appear automatically.
        </p>
        <Link
          href="/analytics"
          className="block w-full bg-zinc-800 hover:bg-zinc-700 text-zinc-300 hover:text-white text-sm font-medium rounded-xl py-3 transition-colors"
        >
          View analytics →
        </Link>
      </div>
      </div>
    </main>
  );
}
