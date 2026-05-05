"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { FeaturedRunCard } from "@/components/kennel/FeaturedRunCard";

export function NextRunBlock() {
  const { futureRuns, slug } = useKennelData();
  const nextRun = futureRuns[0] ?? null;
  if (!nextRun) return null;
  return (
    <FeaturedRunCard
      run={nextRun}
      href={`/${slug}/${nextRun.EventNumber}`}
    />
  );
}
