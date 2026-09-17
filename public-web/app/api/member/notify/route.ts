import { NextRequest, NextResponse } from "next/server";
import { setNotificationPrefs } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";

/**
 * POST { publicKennelId? | publicEventId?, notification?: 0..4, email?: 1|2 }
 * → { ok } — the bell and the envelope (E9.F7.S14), through the app's own
 * hcapp_setEmailAndNotificationPrefs.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ publicKennelId?: string; publicEventId?: string; notification?: number; email?: number }>(req);
  const kennel = (body?.publicKennelId ?? "").toLowerCase();
  const event = (body?.publicEventId ?? "").toLowerCase();
  const uuid = /^[0-9a-f-]{36}$/;
  if ((kennel && !uuid.test(kennel)) || (event && !uuid.test(event)) || (!kennel && !event)) return bad("Bad request.");
  const notification = body?.notification, email = body?.email;
  if ((notification != null && ![0, 1, 2, 3, 4].includes(notification)) || (email != null && ![1, 2].includes(email)) || (notification == null && email == null)) return bad("Bad request.");
  try {
    const r = await setNotificationPrefs(s, { publicKennelId: kennel || undefined, publicEventId: event || undefined, notification, email });
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "Couldn't update.", 502);
  } catch (e) {
    console.error("notify:", e);
    return bad("Couldn't update just now.", 502);
  }
}
