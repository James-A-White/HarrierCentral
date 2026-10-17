import { getKennelRunsFeed } from "@/lib/api";
import { buildSingleRun } from "@/lib/ical";
import { kennelBaseUrl } from "@/lib/seo";

/**
 * One run as a calendar file (James, 2026-10-17): the run page's "This run
 * only", as the app offers. A snapshot — the file says so and points to the
 * kennel's feed (/<slug>/runs.ics) for updates.
 *
 * The run comes from the kennel's feed (publicWeb_getKennelRunsFeed: runs
 * from 30 days ago on), read through the same 15-minute cache as the feed,
 * so a download costs no extra database work. A run outside that window is
 * not offered on its page and gets 404 here.
 */
const CACHE_SECONDS = 900;

export async function GET(_req: Request, { params }: { params: Promise<{ slug: string; runNumber: string }> }) {
  const { slug, runNumber } = await params;
  if (!/^\d+$/.test(runNumber)) return new Response("No such run", { status: 404 });
  const feed = await getKennelRunsFeed(slug, { next: { revalidate: CACHE_SECONDS } });
  if (!feed) return new Response("No such kennel", { status: 404 });

  const { kennel, runs } = feed;
  const run = runs.find((r) => String(r.EventNumber) === runNumber);
  if (!run) return new Response("This run is not in the calendar range", { status: 404 });

  const baseUrl = kennelBaseUrl(slug, kennel.CustomDomain);
  const updated = run.UpdatedAt && !Number.isNaN(Date.parse(run.UpdatedAt)) ? new Date(run.UpdatedAt) : new Date();
  const body = buildSingleRun(
    { name: kennel.KennelName, shortName: kennel.KennelShortName, timeZone: kennel.KennelIANATimezone, baseUrl },
    run, updated, `${baseUrl}/runs.ics`,
  );
  if (!body) return new Response("This run has no start time", { status: 404 });

  const file = `${slug}-${runNumber}.ics`.replace(/[^A-Za-z0-9._-]+/g, "_");
  return new Response(body, {
    headers: {
      "Content-Type": "text/calendar; charset=utf-8",
      "Content-Disposition": `attachment; filename="${file}"`,
      "Cache-Control": "public, max-age=300",
    },
  });
}
