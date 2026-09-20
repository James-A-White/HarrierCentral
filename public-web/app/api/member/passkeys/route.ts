import { NextRequest, NextResponse } from "next/server";
import { listDevices, deletePasskey, signOutDevice } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

/**
 * GET → { passkeys } — every device that can reach this account, with its
 * passkey and signed-out state (E9.F7.S19; the key name is kept so the page
 * and this route stay in step).
 */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  try {
    return NextResponse.json({ passkeys: await listDevices(s) });
  } catch (e) {
    await logWebError({ source: "/api/member/passkeys", error: e, session: s });
    return bad("Couldn't load your devices just now.", 502);
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

/**
 * POST { targetDeviceId } → { ok, passkeys } — signs one device out. The
 * server rotates that device's secret, which is what actually revokes it, and
 * drops its push tokens so it stops receiving this hasher's notifications.
 *
 * Signing out does NOT remove that device's passkey: two acts, two
 * consequences. A signed-out device holding a passkey stays listed so the
 * second one can still be done.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ targetDeviceId?: string }>(req);
  const target = (body?.targetDeviceId ?? "").toLowerCase();
  if (!/^[0-9a-f-]{36}$/.test(target)) return bad("Bad request.");
  try {
    const r = await signOutDevice(s, target);
    return r.ok
      ? NextResponse.json({ ok: true, passkeys: r.remaining })
      : bad(r.message ?? "Couldn't sign that device out.", 502);
  } catch (e) {
    await logWebError({ source: "/api/member/passkeys", error: e, session: s });
    return bad("Couldn't sign that device out just now.", 502);
  }
}
