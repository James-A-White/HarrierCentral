import { getKennelLandingData, getEvents } from "@/lib/api";
import { kennelBaseUrl } from "@/lib/seo";

function buildXml(urls: Array<{ loc: string; lastmod: string; changefreq: string; priority: number }>): string {
  const entries = urls
    .map(
      (u) =>
        `  <url>\n    <loc>${u.loc}</loc>\n    <lastmod>${u.lastmod}</lastmod>\n    <changefreq>${u.changefreq}</changefreq>\n    <priority>${u.priority}</priority>\n  </url>`
    )
    .join("\n");

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    entries,
    "</urlset>",
  ].join("\n");
}

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);

  if (!kennel) {
    return new Response(buildXml([]), {
      headers: { "Content-Type": "application/xml" },
    });
  }

  const base = kennelBaseUrl(slug, kennel.CustomDomain);
  const now = new Date().toISOString().split("T")[0];

  const [futureResult, pastResult] = await Promise.all([
    getEvents(kennel.PublicKennelId, { isFuture: true, maxEvents: 2000, summaryOnly: true }),
    getEvents(kennel.PublicKennelId, { isFuture: false, daysOffset: 90, summaryOnly: true }),
  ]);

  const toRunUrl = (r: { EventNumber: number; EventStartDatetime: string }, changefreq: string) => ({
    loc: `${base}/${r.EventNumber}`,
    lastmod: r.EventStartDatetime.split("T")[0],
    changefreq,
    priority: 0.6,
  });

  const runUrls = [
    ...(futureResult?.events ?? []).filter((r) => r.EventNumber).map((r) => toRunUrl(r, "daily")),
    ...(pastResult?.events ?? []).filter((r) => r.EventNumber).map((r) => toRunUrl(r, "monthly")),
  ];

  const urls = [
    { loc: base,           lastmod: now, changefreq: "hourly",  priority: 1.0 },
    { loc: `${base}/runs`, lastmod: now, changefreq: "daily",   priority: 0.9 },
    { loc: `${base}/about`,lastmod: now, changefreq: "monthly", priority: 0.5 },
    ...runUrls,
  ];

  return new Response(buildXml(urls), {
    headers: {
      "Content-Type": "application/xml",
      "Cache-Control": "public, max-age=3600, stale-while-revalidate=86400",
    },
  });
}
