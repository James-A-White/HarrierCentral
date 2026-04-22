import type { MetadataRoute } from "next";
import { getKennelLandingData, getEvents } from "@/lib/api";
import { kennelBaseUrl } from "@/lib/seo";

export default async function sitemap({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<MetadataRoute.Sitemap> {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);
  if (!kennel) return [];

  const base = kennelBaseUrl(slug, kennel.CustomDomain);

  const [futureResult, pastResult] = await Promise.all([
    getEvents(kennel.PublicKennelId, { isFuture: true, maxEvents: 2000, summaryOnly: true }),
    getEvents(kennel.PublicKennelId, { isFuture: false, summaryOnly: true }),
  ]);

  const runUrls: MetadataRoute.Sitemap = [
    ...(futureResult?.events ?? []),
    ...(pastResult?.events ?? []),
  ]
    .filter((r) => r.EventNumber)
    .map((r) => ({
      url: `${base}/${r.EventNumber}`,
      lastModified: new Date(r.EventStartDatetime),
      changeFrequency: "monthly" as const,
      priority: 0.6,
    }));

  return [
    { url: base,                 lastModified: new Date(), changeFrequency: "hourly",  priority: 1   },
    { url: `${base}/runs`,       lastModified: new Date(), changeFrequency: "daily",   priority: 0.9 },
    { url: `${base}/about`,      lastModified: new Date(), changeFrequency: "monthly", priority: 0.5 },
    ...runUrls,
  ];
}
