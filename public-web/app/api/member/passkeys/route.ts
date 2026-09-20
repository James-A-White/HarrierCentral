import { NextRequest, NextResponse } from "next/server";
import { listPasskeys, deletePasskey } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * GET → { passkeys } — the signed-in hasher's registered passkeys (E9.F7.S18).
 */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  try {
    return NextResponse.json({ passkeys: await listPasskeys(s) });
  } catch (e) {
    await logWebError({ source: "/api/member/passkeys", error: e, session: s });
    return bad("Couldn't load your passkeys just now.", 502);
  }
}

/**
 * DELETE { targetDeviceId } → { ok, passkeys } — removes one passkey and
 * hands back what remains. Removing THIS browser's own passkey does not sign
 * it out: the device row and its secret survive, only the credential goes.
 */
export async function DELETE(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ targetDeviceId?: string }>(req);
  const target = (body?.targetDeviceId ?? "").toLowerCase();
  if (!/^[0-9a-f-]{36}$/.test(target)) return bad("Bad request.");
  try {
    const r = await deletePasskey(s, target);
    return r.ok
      ? NextResponse.json({ ok: true, passkeys: r.remaining })
      : bad(r.message ?? "Couldn't remove that passkey.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/passkeys", error: e, session: s });
    return bad("Couldn't remove that passkey just now.", 502);
  }
}
