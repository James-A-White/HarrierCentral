import { redirect } from 'next/navigation';
import { getRestaurantSession } from '@/lib/session';
import { getRedemptionDetail, getRedemptionSummary } from '@/lib/api';
import AnalyticsPage from './AnalyticsPage';

export default async function RestaurantAnalyticsPage() {
  const session = await getRestaurantSession();
  if (!session) redirect('/login');

  const [detail, summary] = await Promise.all([
    getRedemptionDetail(session.restaurantId),
    getRedemptionSummary(session.restaurantId),
  ]);

  return <AnalyticsPage detail={detail} summary={summary} showRestaurant={false} backHref="/" />;
}
