import type { Metadata } from "next";
import { getMyRuns } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { MyRunsMapLoader } from "@/components/member/MyRunsMapLoader";

export const metadata: Metadata = { title: "Map" };

export default async function MyMapPage() {
  const s = await requireMember();
  const runs = await getMyRuns(s).catch(() => []);
  return (
    <div>
      <h1 className="mb-3 text-xl font-bold">Where my kennels are running</h1>
      <MyRunsMapLoader runs={runs.filter((r) => !r.IsPast)} />
    </div>
  );
}
