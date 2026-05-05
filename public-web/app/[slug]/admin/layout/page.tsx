import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents, getPageLayout, getSongs, getStats } from "@/lib/api";
import { verifySession } from "@/lib/admin-session";
import { PuckEditor } from "@/components/puck/PuckEditor";
import type { PageLayoutBlob } from "@/lib/page-layout";

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
    return (
      <html lang="en">
        <body style={{ margin: 0, display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", fontFamily: "system-ui, sans-serif", background: "#0f0f0f", color: "#666" }}>
          <p>Access denied. Open this page from the Harrier Central portal app.</p>
        </body>
      </html>
    );
  }

  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const [futureResult, pastResult, layoutJson, songs, statsResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  maxEvents: 20 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 20 }),
    getPageLayout(slug),
    getSongs(kennelData.PublicKennelId),
    getStats(kennelData.PublicKennelId),
  ]);

  const futureRuns = futureResult?.events ?? [];
  const pastRuns   = pastResult?.events   ?? [];

  const initialBlob: PageLayoutBlob = layoutJson
    ? (JSON.parse(layoutJson) as PageLayoutBlob)
    : {};

  return (
    <html lang="en">
      <body style={{ margin: 0, height: "100vh", overflow: "hidden" }}>
        <PuckEditor
          slug={slug}
          initialBlob={initialBlob}
          pageData={{
            kennelData,
            slug,
            futureRuns,
            pastRuns,
            songs,
            statsRows: statsResult?.rows ?? [],
            hasherCount: statsResult?.hasherCount ?? 0,
          }}
        />
      </body>
    </html>
  );
}
