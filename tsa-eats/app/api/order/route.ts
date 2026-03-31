import { NextRequest, NextResponse } from 'next/server';
import { getWorkerSession, orderCookieOptions, type OrderCookieData } from '@/lib/session';
import { createOrder } from '@/lib/api';

export async function POST(req: NextRequest) {
  const worker = await getWorkerSession();
  if (!worker) {
    return NextResponse.json({ error: 'Unauthorized.' }, { status: 401 });
  }

  const { restaurantId, restaurantName, mealId, mealName } = await req.json();
  if (!restaurantId || !restaurantName || !mealId || !mealName) {
    return NextResponse.json({ error: 'Missing required fields.' }, { status: 400 });
  }

  const rows = await createOrder(worker.workerId, restaurantId, mealId);
  const result = rows?.[0];
  if (!result || Number(result.Success) === 0) {
    return NextResponse.json({ error: result?.ErrorMessage ?? 'Failed to create order.' }, { status: 500 });
  }

  const today = new Date().toISOString().split('T')[0];
  const order: OrderCookieData = {
    restaurantId,
    restaurantName,
    mealId,
    mealName,
    workerId: worker.workerId,
    workerName: `${worker.firstName} ${worker.lastName}`,
    date: today,
    token: result.token,
  };

  const res = NextResponse.json({ ok: true });
  res.cookies.set(orderCookieOptions(order));
  return res;
}
