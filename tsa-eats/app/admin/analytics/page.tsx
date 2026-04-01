import { redirect } from 'next/navigation';
import { getAdminSession } from '@/lib/session';
import { getRedemptionDetail, getRedemptionSummary } from '@/lib/api';
import AnalyticsPage from '@/app/restaurant-portal/analytics/AnalyticsPage';

export default async function AdminAnalyticsPage() {
  if (!(await getAdminSession())) redirect('/admin/login');

  const [detail, summary] = await Promise.all([
    getRedemptionDetail(),   // no restaurantId = all restaurants
    getRedemptionSummary(),
  ]);

  return <AnalyticsPage detail={detail} summary={summary} showRestaurant={true} backHref="/admin" />;
}
