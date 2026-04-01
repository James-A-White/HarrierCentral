import { redirect } from 'next/navigation';
import { getRestaurantSession } from '@/lib/session';
import { getOrderByToken } from '@/lib/api';
import ScanPage from './ScanPage';

export default async function RestaurantScanPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const session = await getRestaurantSession();
  if (!session) redirect('/login');

  const { token } = await params;
  const order = await getOrderByToken(token);

  if (!order) {
    return (
      <main className="min-h-screen bg-zinc-950 flex items-center justify-center p-4">
        <div className="text-center space-y-3">
          <div className="text-5xl">❌</div>
          <h1 className="text-white text-xl font-bold">Order not found</h1>
          <p className="text-zinc-400 text-sm">This QR code is not recognised.</p>
        </div>
      </main>
    );
  }

  // Both IDs come from the DB (SQL Server uppercase UUIDs) — lowercase compare is belt-and-braces
  if (order.restaurantId.toLowerCase() !== session.restaurantId.toLowerCase()) {
    return (
      <main className="min-h-screen bg-zinc-950 flex items-center justify-center p-4">
        <div className="text-center space-y-3">
          <div className="text-5xl">⛔</div>
          <h1 className="text-white text-xl font-bold">Wrong restaurant</h1>
          <p className="text-zinc-400 text-sm">This order is for {order.restaurantName}.</p>
        </div>
      </main>
    );
  }

  return <ScanPage order={order} token={token} />;
}
