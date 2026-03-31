import { redirect } from 'next/navigation';
import { getWorkerSession, getTodayOrder } from '@/lib/session';
import { getRestaurants, getMenuItems } from '@/lib/api';
import BrowsePage from './BrowsePage';
import OrderQrPage from './OrderQrPage';

export default async function HomePage() {
  const worker = await getWorkerSession();
  if (!worker) redirect('/register');

  const order = await getTodayOrder();
  if (order) {
    return <OrderQrPage worker={worker} order={order} />;
  }

  const restaurants = await getRestaurants();
  const menuItemsMap = Object.fromEntries(
    await Promise.all(restaurants.map(async (r) => [r.id, (await getMenuItems(r.id)) ?? []]))
  );

  return <BrowsePage worker={worker} restaurants={restaurants} menuItemsMap={menuItemsMap} />;
}
