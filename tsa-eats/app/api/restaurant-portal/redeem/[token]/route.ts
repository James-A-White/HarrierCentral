import { NextRequest, NextResponse } from 'next/server';
import { getRestaurantSession } from '@/lib/session';
import { redeemOrder } from '@/lib/api';

export async function POST(
  _req: NextRequest,
  { params }: { params: Promise<{ token: string }> }
) {
  const session = await getRestaurantSession();
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized.' }, { status: 401 });
  }

  const { token } = await params;
  const rows = await redeemOrder(token, session.restaurantId);
  const result = rows?.[0];

  if (!result || Number(result.Success) === 0) {
    return NextResponse.json(
      { error: result?.ErrorMessage ?? 'Redemption failed.' },
      { status: 400 }
    );
  }

  return NextResponse.json({ ok: true });
}
