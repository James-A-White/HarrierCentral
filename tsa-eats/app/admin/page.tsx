import { redirect } from 'next/navigation';
import { getAdminSession } from '@/lib/session';
import { listInvites } from '@/lib/api';
import AdminDashboard from './AdminDashboard';

export default async function AdminPage() {
  if (!(await getAdminSession())) redirect('/admin/login');

  const invites = await listInvites();
  return <AdminDashboard invites={invites} />;
}
