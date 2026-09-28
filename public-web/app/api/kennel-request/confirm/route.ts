import { NextRequest, NextResponse } from "next/server";
import { callAdminApi, userMessageOf } from "@/lib/member-api";
import { bad, ipOf, jsonBody, limited } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * POST { requestId, code } → { confirmed: true, alreadyConfirmed }.
 * The emailed six-digit code moves the request into the review queue
 * (publicWeb_confirmKennelRequest). Five wrong codes and the SP marks the
 * request as spam; the limit here only stops hammering.
 */
export async function POST(req: NextRequest) {
  const body = await jsonBody<{ requestId?: string; code?: string }>(req);
  const requestId = (body?.requestId ?? "").trim();
  const code = (body?.code ?? "").replace(/\s+/g, "");
  if (!GUID.test(requestId)) return bad("Please send the form first.");
  if (!/^\d{6}$/.test(code)) return bad("The code is six digits.");
  if (limited(`kennel-confirm:ip:${ipOf(req)}`, 20, 60 * 60_000)) {
    return bad("Too many attempts. Please try again later.", 429);
  }
  try {
    const rowsets = await callAdminApi("confirmKennelRequest", { requestId, code });
    const envelope = rowsets?.[0]?.[0] as { success?: number } | undefined;
    if (envelope?.success !== 1) return bad(userMessageOf(rowsets));
    const row = (rowsets[1]?.[0] ?? {}) as { alreadyConfirmed?: number };
    return NextResponse.json({ confirmed: true, alreadyConfirmed: row.alreadyConfirmed === 1 });
  } catch (e) {
    await logWebError({ source: "/api/kennel-request/confirm", error: e });
    return bad("We couldn't check the code just now. Please try again in a few minutes.", 502);
  }
}
