import { NextRequest, NextResponse } from "next/server";
import { getReportContext } from "@/lib/member-api";
import { hcToken, readMember } from "@/lib/member-session";
import { bad, ipOf, jsonBody, limited } from "@/lib/member-routes";

const REPORT_URL = `${process.env.HC_API_URL ?? "https://harriercentralpublicapi.azurewebsites.net"}/api/SendRunCountsReport`;

/**
 * POST { publicKennelId? } → { ok, email }
 * The app's "Email run counts" speed-dial action. The Azure Function wants
 * the internal kennel id, the hasher's name and their address, so those are
 * resolved server-side and never handed to the browser. The two access
 * tokens are the ones that function re-validates downstream: one for
 * hcapp_getRuns, one for hcapp_getMyKennelRunTotals.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  // An emailed report per tap is fine; a hundred is not.
  if (limited(`report:${s.userId}`, 5, 10 * 60_000)) return bad("You have asked for that a few times already. Try again shortly.", 429);
  if (limited(`report:ip:${ipOf(req)}`, 20, 10 * 60_000)) return bad("Too many requests.", 429);

  const body = await jsonBody<{ publicKennelId?: string }>(req);
  const publicKennelId = (body?.publicKennelId ?? "").toLowerCase();
  if (publicKennelId && !/^[0-9a-f-]{36}$/.test(publicKennelId)) return bad("Bad request.");

  try {
    const ctx = await getReportContext(s, publicKennelId || undefined);
    if (!ctx) return bad("Couldn't prepare that report.", 502);
    if (!ctx.EmailAddress?.includes("@")) {
      return bad("There is no email address on your account to send it to.", 400);
    }

    const res = await fetch(REPORT_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        queryType: "SendRunCountsReport",
        deviceId: s.deviceId,
        accessToken1: hcToken(s.userId, "hcapp_getRuns", { paramString: s.deviceSecret, timeWindow: s.timeWindow }),
        accessToken2: hcToken(s.userId, "hcapp_getMyKennelRunTotals", { paramString: s.deviceSecret, timeWindow: s.timeWindow }),
        kennelId: ctx.KennelId,
        kennelName: ctx.KennelName,
        userName: ctx.UserName,
        emailAddress: ctx.EmailAddress,
      }),
      signal: AbortSignal.timeout(30_000),
    });
    if (!res.ok) {
      console.error("run-counts-report:", res.status, (await res.text()).slice(0, 200));
      return bad("The report could not be sent just now. Please try again.", 502);
    }
    return NextResponse.json({ ok: true, email: ctx.EmailAddress });
  } catch (e) {
    console.error("run-counts-report:", e);
    return bad("The report could not be sent just now. Please try again.", 502);
  }
}
