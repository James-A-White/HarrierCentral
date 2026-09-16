import type { Metadata } from "next";
import { getMyRuns } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { MyRunsList } from "@/components/member/MyRunsList";

export const metadata: Metadata = { title: "My runs" };

export default async function MyRunsPage() {
  const s = await requireMember();
  const runs = await getMyRuns(s).catch(() => []);
  return <MyRunsList initialRuns={runs} />;
}
