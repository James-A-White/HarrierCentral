import { createHash } from "node:crypto";
import { getKennelRunsFeed } from "@/lib/api";
import { buildCalendar } from "@/lib/ical";
import { kennelBaseUrl } from "@/lib/seo";

/**
 * A kennel's runs as an iCal feed (E3.F6.S8): subscribe once in any calendar
 * app and the runs keep themselves current. Every entry links back to the
 * run's page, which opens the app where it is installed.
 *
 * Load: one call to its own small procedure (publicWeb_getKennelRunsFeed,
 * ~45 page reads), and the answer is the same for every subscriber, so it is
 * cached for 15 minutes per kennel (the Next data cache) — a deliberate
 * exception to the web's `no-store` rule, because a calendar app re-reads
 * hourly at best. However many hashers subscribe, the procedure runs at most
 * four times an hour per kennel. A repeat that sends the ETag back gets 304.
 */
const CACHE_SECONDS = 900;

function calendarResponse(body: string, req: Request): Response {
  const etag = `"${createHash("sha256").update(body).digest("base64url").slice(0, 27)}"`;
  const headers = {
    "Content-Type": "text/calendar; charset=utf-8",
    "Content-Disposition": 'inline; filename="runs.ics"',
    "Cache-Control": `public, max-age=${CACHE_SECONDS}`,
    ETag: etag,
  };
  const inm = req.headers.get("if-none-match");
  if (inm && inm.split(",").some((t) => t.trim().replace(/^W\//, "") === etag)) {
    return new Response(null, { status: 304, headers });
  }
  return new Response(body, { headers });
}

export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const feed = await getKennelRunsFeed(slug, { next: { revalidate: CACHE_SECONDS } });
  if (!feed) return new Response("No such kennel", { status: 404 });

  const { kennel, runs } = feed;
  // A Defunct or Inactive-Hidden kennel's feed is valid but empty (the
  // procedure returns no runs), so subscribers see its runs go away rather
  // than an error.
  const feedKennel = {
    name: kennel.KennelName,
    shortName: kennel.KennelShortName,
    timeZone: kennel.KennelIANATimezone,
    baseUrl: kennelBaseUrl(slug, kennel.CustomDomain),
  };

  // DTSTAMP must not be "now", or every read would differ and the ETag would
  // never match: the latest edit to any run changes only with the data.
  const latest = runs.reduce((m, r) => {
    const t = r.UpdatedAt ? Date.parse(r.UpdatedAt) : NaN;
    return Number.isNaN(t) ? m : Math.max(m, t);
  }, 0);

  return calendarResponse(buildCalendar(feedKennel, runs, new Date(latest)), req);
}
