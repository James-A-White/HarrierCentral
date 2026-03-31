import { redirect } from 'next/navigation';
import { getRestaurantSession } from '@/lib/session';

export default async function RestaurantPortalHomePage() {
  if (!(await getRestaurantSession())) redirect('/login');

  return (
    <main className="min-h-screen bg-zinc-950 flex items-center justify-center p-4">
      <div className="text-center space-y-4 max-w-sm">
        <div className="text-6xl">📷</div>
        <h1 className="text-white text-2xl font-bold">Ready to scan</h1>
        <p className="text-zinc-400 text-sm">
          Use your camera to scan a worker&apos;s QR code. The order details and redeem
          button will appear automatically.
        </p>
      </div>
    </main>
  );
}
