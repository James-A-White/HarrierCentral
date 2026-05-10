"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { FeaturedRunCard, type FeaturedDisplayOptions } from "@/components/kennel/FeaturedRunCard";

interface NextRunBlockProps {
  offset?: number;
  hideWhenNoRun?: boolean;
  noRunText?: string;
  showRunNumber?: boolean;
  showRunName?: boolean;
  showDate?: boolean;
  showTime?: boolean;
  showLocation?: boolean;
  showHares?: boolean;
  showDescription?: boolean;
  showTags?: boolean;
  showMap?: boolean;
  showImage?: boolean;
}

export function NextRunBlock({
  offset         = 0,
  hideWhenNoRun  = true,
  noRunText      = "",
  showRunNumber  = true,
  showRunName    = true,
  showDate       = true,
  showTime       = true,
  showLocation   = true,
  showHares      = true,
  showDescription = true,
  showTags       = false,
  showMap        = false,
  showImage      = true,
}: NextRunBlockProps) {
  const { futureRuns, pastRuns, slug } = useKennelData();

  // Positive offset → future runs; negative → past runs (offset -1 = pastRuns[0])
  const run = offset >= 0
    ? (futureRuns[offset] ?? null)
    : (pastRuns[Math.abs(offset) - 1] ?? null);

  if (!run) {
    if (hideWhenNoRun || !noRunText.trim()) return null;
    return (
      <div
        className="w-full rounded-[2.5rem] border dark:border-white/25 border-zinc-200 px-6 py-8 text-center text-2xl"
        style={{
          backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))",
          color: "var(--kennel-text-muted)",
        }}
      >
        {noRunText}
      </div>
    );
  }

  const display: Partial<FeaturedDisplayOptions> = {
    showRunNumber,
    showRunName,
    showDate,
    showTime,
    showLocation,
    showHares,
    showDescription,
    showTags,
    showMap,
    showImage,
  };

  return (
    <FeaturedRunCard
      run={run}
      href={`/${slug}/${run.EventNumber}`}
      display={display}
    />
  );
}
