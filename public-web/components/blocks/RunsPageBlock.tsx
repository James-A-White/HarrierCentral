"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { RunsPageClient } from "@/components/kennel/RunsPageClient";
import { toKennelContext } from "@/lib/kennel-utils";

export function RunsPageBlock() {
  const { futureRuns, pastRuns, kennelData, slug } = useKennelData();
  const kennel = toKennelContext(kennelData);

  return (
    <RunsPageClient
      futureRuns={futureRuns}
      pastRuns={pastRuns}
      kennel={kennel}
      slug={slug}
    />
  );
}
