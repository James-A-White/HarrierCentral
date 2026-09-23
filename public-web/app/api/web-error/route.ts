import { NextRequest, NextResponse } from "next/server";
import { logWebError } from "@/lib/web-log";
import { readMember } from "@/lib/member-session";
import { ipOf, jsonBody, limited } from "@/lib/member-routes";

/**
 * Where the browser reports what it could not survive: the React error
 * boundaries post here so a client-side crash reaches HC.ErrorLog too,
 * not just the visitor's console.
 *
 * Rate-limited per IP because this is an unauthenticated write, and it
 * always answers 204 so a reporting failure never cascades in the page
 * that is already broken.
 */
export async function POST(req: NextRequest) {
  if (limited(`weberr:${ipOf(req)}`, 20, 60_000)) return new NextResponse(null, { status: 204 });
  const body = await jsonBody<{ source?: string; message?: string; stack?: string; url?: string; digest?: string }>(req);
  if (!body?.message) return new NextResponse(null, { status: 204 });
  await logWebError({
    source: (body.source ?? "browser").slice(0, 120),
    error: body.message.slice(0, 240),
    // The user agent goes FIRST: the SP keeps 2500 characters and the stack
    // can fill 2000 of them on its own. It is here so that "is this a bot?"
    // is answered by the row rather than by inference from timing — six
    // guard reports on one page, forty-five minutes apart, took an afternoon
    // to read as a crawler.
    detail: [
      `ua ${req.headers.get("user-agent") ?? "-"}`,
      body.digest ? `digest ${body.digest}` : "",
      body.stack ?? "",
    ].filter(Boolean).join("\n"),
    url: body.url,
    session: readMember(req),
  });
  return new NextResponse(null, { status: 204 });
}
