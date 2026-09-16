import { NextRequest, NextResponse } from "next/server";
import { setKennelFollowing } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad, jsonBody } from "@/lib/member-routes";

/** POST { publicKennelId, following } → { ok } — the app's own joinKennel, self-mode. */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const body = await jsonBody<{ publicKennelId?: string; following?: boolean }>(req);
  const id = (body?.publicKennelId ?? "").toLowerCase();
  if (!/^[0-9a-f-]{36}$/.test(id)) return bad("Bad request.");
  try {
    const r = await setKennelFollowing(s, id, !!body?.following);
    return r.ok ? NextResponse.json({ ok: true }) : bad(r.message ?? "Couldn't update.", 502);
  } catch (e) {
    console.error("follow:", e);
    return bad("Couldn't update just now.", 502);
  }
}
