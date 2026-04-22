import { getAllKennelSlugs } from "@/lib/api";
import { GLOBAL_BASE_URL } from "@/lib/seo";

// Sitemap index — references the static global sitemap and every
// per-kennel sitemap. Submit hashruns.org/sitemap.xml to Google
// Search Console once; it discovers all kennels automatically.

function buildXml(kennelSlugs: string[]): string {
  const sitemaps = [
    // Global platform pages (home, calendar)
    `${GLOBAL_BASE_URL}/sitemap-global.xml`,
    // Per-kennel sitemaps
    ...kennelSlugs.map((slug) => `${GLOBAL_BASE_URL}/${slug}/sitemap.xml`),
  ];

  const entries = sitemaps
    .map((loc) => `  <sitemap><loc>${loc}</loc></sitemap>`)
    .join("\n");

  return [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    entries,
    "</sitemapindex>",
  ].join("\n");
}

export async function GET() {
  const slugs = await getAllKennelSlugs();
  const xml = buildXml(slugs);
  return new Response(xml, {
    headers: {
      "Content-Type": "application/xml",
      "Cache-Control": "public, max-age=3600, stale-while-revalidate=86400",
    },
  });
}
