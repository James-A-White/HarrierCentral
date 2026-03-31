import { redirect } from 'next/navigation';
import { getWorkerSession } from '@/lib/session';
import { getRestaurants } from '@/lib/api';
import BrowsePage from './BrowsePage';

export default async function HomePage() {
  const worker = await getWorkerSession();
  if (!worker) redirect('/register');

  const restaurants = await getRestaurants();
  return <BrowsePage worker={worker} restaurants={restaurants} />;
}
