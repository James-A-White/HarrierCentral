import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getMyRunsFor } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { HistoryRunsView } from "@/components/member/HistoryRunsView";
import { LightBackground } from "@/components/member/LightBackground";

export const metadata: Metadata = { title: "My runs" };

/** The app's "My runs for <kennel>" (E9.F7.S5). */
export default async function MyRunsForKennelPage({ params }: { params: Promise<{ publicKennelId: string }> }) {
  const { publicKennelId } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(publicKennelId)) notFound();
  const s = await requireMember();
  const r = await getMyRunsFor(s, { publicKennelId: publicKennelId.toLowerCase(), allRuns: false }).catch(() => null);
  if (!r?.header) notFound();
  return (
    <>
      <LightBackground />
      <HistoryRunsView kind="kennel" id={publicKennelId.toLowerCase()} header={r.header} initialRuns={r.runs} showKennelLogo={false} showFlag={true} />
    </>
  );
}
