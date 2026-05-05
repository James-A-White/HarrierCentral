"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { UpcomingRunsList } from "@/components/kennel/UpcomingRunsList";
import { PhotoGrid } from "@/components/kennel/PhotoGrid";
import { toKennelContext } from "@/lib/kennel-utils";

interface RunListBlockProps {
  isFuture: boolean;
  count: number;
}

export function RunListBlock({ isFuture, count }: RunListBlockProps) {
  const { futureRuns, pastRuns, kennelData, slug } = useKennelData();
  const kennel = toKennelContext(kennelData);

  if (isFuture) {
    // Slice off the first run — that's shown by NextRunBlock as the featured card
    const runs = futureRuns.slice(1, count + 1);
    return <UpcomingRunsList runs={runs} slug={slug} />;
  }

  const runs = pastRuns.slice(0, count);
  return <PhotoGrid runs={runs} kennel={kennel} slug={slug} />;
}
