import { GLOBAL_BASE_URL } from "@/lib/seo";

const PAGES = [
  { loc: GLOBAL_BASE_URL,              changefreq: "hourly",  priority: "1.0" },
  { loc: `${GLOBAL_BASE_URL}/calendar`, changefreq: "hourly",  priority: "0.8" },
];

function buildXml(): string {
  const entries = PAGES.map(
    ({ loc, changefreq, priority }) =>
      `  <url>\n    <loc>${loc}</loc>\n    <changefreq>${changefreq}</changefreq>\n    <priority>${priority}</priority>\n  </url>`
  ).join("\n");

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    entries,
    "</urlset>",
  ].join("\n");
}

export function GET() {
  return new Response(buildXml(), {
    headers: {
      "Content-Type": "application/xml",
      "Cache-Control": "public, max-age=86400",
    },
  });
}
