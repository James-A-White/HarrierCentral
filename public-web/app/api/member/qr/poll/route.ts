import { NextRequest, NextResponse } from "next/server";
import { confirmQrAuthentication } from "@/lib/member-api";
import { setMemberCookie, verifyValue } from "@/lib/member-session";
import { bad, deviceDataOf, jsonBody } from "@/lib/member-routes";

/** POST { ticket, remember } → { pending: true } | { ok: true, hashName } */
export async function POST(req: NextRequest) {
  const body = await jsonBody<{ ticket?: string; remember?: boolean }>(req);
  const t = verifyValue<{ scanData: string; deviceId: string }>(body?.ticket);
  if (!t) return bad("This sign-in has expired. Start again.", 410);
  try {
    const session = await confirmQrAuthentication(t.deviceId, t.scanData, deviceDataOf(req), body?.remember !== false);
    if (!session) return NextResponse.json({ pending: true });
    const res = NextResponse.json({ ok: true, hashName: session.hashName || session.displayName });
    setMemberCookie(res, session);
    return res;
  } catch (e) {
    console.error("qr/poll:", e);
    return bad("We couldn't complete the sign-in just now.", 502);
  }
}
