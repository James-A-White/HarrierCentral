import { NextRequest, NextResponse } from "next/server";
import { callAdminApi, userMessageOf } from "@/lib/member-api";
import { bad, ipOf, jsonBody, limited } from "@/lib/member-routes";
import { checkFormStamp, type KennelRequestForm } from "@/lib/kennel-request";
import { logWebError } from "@/lib/web-log";

const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Body = Partial<KennelRequestForm> & {
  stamp?: string;
  website?: string;
  terms1?: string;
  terms2?: string;
  terms3?: string;
};

/**
 * POST the add-kennel form → { requestId, alreadySubmitted, codeSent }.
 * The request is stored awaiting email (publicWeb_submitKennelRequest) and
 * the API emails a six-digit code, which /api/kennel-request/confirm takes.
 * The SP holds the rules and the messages; this route only keeps bots away
 * from it — honeypot, time-to-submit stamp, per-IP limit — and passes the
 * caller's address along for the SP's own daily limit.
 */
export async function POST(req: NextRequest) {
  const body = await jsonBody<Body>(req);
  if (!body) return bad("Please fill in the form.");

  // Honeypot: a field people never see. Answer as if it worked, so a bot
  // learns nothing — and send nothing.
  if ((body.website ?? "").trim().length > 0) {
    return NextResponse.json({ requestId: null, alreadySubmitted: false, codeSent: true });
  }
  const stamp = checkFormStamp(body.stamp);
  if (stamp === "bad") return bad("This form has expired. Please reload the page and try again.");
  if (stamp === "too-fast") return bad("That was quick! Please check the details and send the form again.");

  const ip = ipOf(req);
  if (limited(`kennel-request:ip:${ip}`, 5, 60 * 60_000)) {
    return bad("Too many requests from your network. Please try again later.", 429);
  }

  const text = (v: string | undefined) => {
    const t = (v ?? "").trim();
    return t.length ? t : null;
  };
  const guid = (v: string | undefined) => (v && GUID.test(v) ? v : null);

  try {
    const rowsets = await callAdminApi("submitKennelRequest", {
      firstName: text(body.firstName),
      lastName: text(body.lastName),
      hashName: text(body.hashName),
      email: text(body.email),
      kennelName: text(body.kennelName),
      kennelShortName: text(body.kennelShortName),
      kennelDescription: text(body.kennelDescription),
      kennelUrl: text(body.kennelUrl),
      kennelFacebookUrl: text(body.kennelFacebookUrl),
      countryId: guid(body.countryId),
      regionId: guid(body.regionId),
      cityId: guid(body.cityId),
      cityText: guid(body.cityId) ? null : text(body.cityText),
      runsPerMonth: text(body.runsPerMonth),
      hashersPerRun: text(body.hashersPerRun),
      hashCash: text(body.hashCash),
      nonMemberPrice: text(body.nonMemberPrice),
      nextRunNumber: text(body.nextRunNumber),
      howDidYouLearn: text(body.howDidYouLearn),
      comments: text(body.comments),
      submitIp: ip,
      terms1: text(body.terms1),
      terms2: text(body.terms2),
      terms3: text(body.terms3),
    });
    const envelope = rowsets?.[0]?.[0] as { success?: number } | undefined;
    if (envelope?.success !== 1) return bad(userMessageOf(rowsets));
    const row = (rowsets[1]?.[0] ?? {}) as { requestId?: string; alreadySubmitted?: number; codeSent?: number };
    return NextResponse.json({
      requestId: row.requestId ?? null,
      alreadySubmitted: row.alreadySubmitted === 1,
      codeSent: row.codeSent === 1,
    });
  } catch (e) {
    await logWebError({ source: "/api/kennel-request", error: e });
    return bad("We couldn't send your request just now. Please try again in a few minutes.", 502);
  }
}
