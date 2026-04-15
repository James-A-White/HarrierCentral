import type { Metadata } from "next";
import { getGlobalRuns } from "@/lib/api";
import { GlobalRunsList } from "@/components/global/GlobalRunsList";

export const metadata: Metadata = {
  title: "hashruns.org — Hash Runs Worldwide",
  description:
    "Browse upcoming hash runs from kennels around the world. Find your next run, get directions, and share links.",
};

export default async function GlobalRunsPage() {
  let initialRuns: Awaited<ReturnType<typeof getGlobalRuns>> = {
    totalMatchingEvents: 0,
    runs: [],
  };
  try {
    initialRuns = await getGlobalRuns({ isFuture: true, pageSize: 50, offset: 0 });
  } catch {
    // Gracefully degrade — client will retry on tab switch
  }

  return (
    <GlobalRunsList
      initialRuns={initialRuns.runs}
      initialTotal={initialRuns.totalMatchingEvents}
    />
  );
}
