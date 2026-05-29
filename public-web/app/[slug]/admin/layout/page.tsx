import { cookies } from "next/headers";
import { getIsCustomDomain } from "@/lib/server-utils";
import { redirect, notFound, unauthorized } from "next/navigation";
import { getKennelLandingData, getEvents, getPageLayout, getSongs, getStats } from "@/lib/api";
import { verifySession } from "@/lib/admin-session";
import { toKennelContext } from "@/lib/kennel-utils";
import { PuckEditor } from "@/components/puck/PuckEditor";
import { parseSiteConfig } from "@/lib/page-layout";

interface PageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ token?: string }>;
}

export const dynamic = "force-dynamic";

export default async function AdminLayoutPage({ params, searchParams }: PageProps) {
  const { slug } = await params;
  const { token } = await searchParams;

  const cookieStore = await cookies();
  const session = verifySession(cookieStore.get("hc_admin_session")?.value);

  if (!session || session.kennelSlug !== slug) {
    if (token) {
      redirect(`/api/admin/auth?token=${encodeURIComponent(token)}&slug=${encodeURIComponent(slug)}`);
    }
    unauthorized();
  }

  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();
  const kennel = toKennelContext(kennelData);

  const [futureResult, pastResult, layoutJson, songs, statsResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  maxEvents: 20 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 20 }),
    getPageLayout(slug),
    getSongs(kennelData.PublicKennelId),
    getStats(kennelData.PublicKennelId),
  ]);

  const futureRuns = futureResult?.events ?? [];
  const pastRuns   = pastResult?.events   ?? [];

  const initialConfig = parseSiteConfig(layoutJson);

  return (
    <html
      lang="en"
      className={kennel.theme === "dark" ? "dark" : ""}
      style={{
        "--kennel-primary":    kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent":     kennel.accentColor,
        "--kennel-text-title": kennel.textTitleColor,
        "--kennel-text-body":  kennel.textBodyColor,
        "--kennel-text-muted": kennel.textMutedColor,
        "--kennel-card-bg":    kennel.cardBackgroundColor,
      } as React.CSSProperties}
    >
      <body style={{ margin: 0, height: "100vh", overflow: "hidden" }}>
        <PuckEditor
          slug={slug}
          initialConfig={initialConfig}
          pageData={{
            kennelData,
            slug,
            futureRuns,
            pastRuns,
            songs,
            statsRows: statsResult?.rows ?? [],
            hasherCount: statsResult?.hasherCount ?? 0,
            isCustomDomain: await getIsCustomDomain(),
          }}
        />
      </body>
    </html>
  );
}
