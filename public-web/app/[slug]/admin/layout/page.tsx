import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { notFound } from "next/navigation";
import { getKennelLandingData, getEvents, getPageLayout } from "@/lib/api";
import { verifySession } from "@/lib/admin-session";
import { PuckEditor } from "@/components/puck/PuckEditor";
import { defaultLayout } from "@/components/puck/defaultLayout";
import type { Data } from "@measured/puck";

interface PageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ token?: string }>;
}

export const dynamic = "force-dynamic";

export default async function AdminLayoutPage({ params, searchParams }: PageProps) {
  const { slug } = await params;
  const { token } = await searchParams;

  // Session check — httpOnly cookie set by /api/admin/auth after token redemption
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

  const [kennelData, layoutJson] = await Promise.all([
    getKennelLandingData(slug),
    getPageLayout(slug),
  ]);

  if (!kennelData) notFound();

  const [eventsResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  maxEvents: 20 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 365, maxEvents: 20 }),
  ]);

  const futureRuns = eventsResult?.events ?? [];
  const pastRuns   = pastResult?.events   ?? [];

  const initialData: Data = layoutJson ? (JSON.parse(layoutJson) as Data) : defaultLayout;

  return (
    <html lang="en">
      <body style={{ margin: 0, height: "100vh", overflow: "hidden" }}>
        <PuckEditor
          slug={slug}
          initialData={initialData}
          pageData={{ kennelData, slug, futureRuns, pastRuns }}
        />
      </body>
    </html>
  );
}
