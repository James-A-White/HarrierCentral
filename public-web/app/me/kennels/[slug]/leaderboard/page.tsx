import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getLeaderboard, getMyKennels } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { LeaderboardView } from "@/components/member/LeaderboardView";

export const metadata: Metadata = { title: "Get a Life (Leaderboards)" };

/** The app's leaderboard for one kennel (E9.F7.S12). */
export default async function KennelLeaderboardPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s = await requireMember();
  const mine = await getMyKennels(s).catch(() => []);
  const kennel = mine.find((k) => k.KennelSlug.toLowerCase() === slug.toLowerCase()) ?? null;
  if (!kennel) notFound();
  const rows = await getLeaderboard(s, kennel.PublicKennelId.toLowerCase()).catch(() => []);
  return <LeaderboardView rows={rows} kennelShortName={kennel.KennelShortName} back={`/me/kennels/${kennel.KennelSlug}`} />;
}
