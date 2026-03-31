import { redirect } from 'next/navigation';
import { getWorkerSession } from '@/lib/session';
import { getRestaurants, getMenuItems } from '@/lib/api';
import RestaurantPage from './RestaurantPage';

export default async function RestaurantDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const worker = await getWorkerSession();
  if (!worker) redirect('/register');

  const restaurants = await getRestaurants();
  const restaurant = restaurants.find((r) => r.id === id);
  if (!restaurant) redirect('/');

  const menuItems = (await getMenuItems(id)) ?? [];

  return <RestaurantPage worker={worker} restaurant={restaurant} menuItems={menuItems} />;
}
