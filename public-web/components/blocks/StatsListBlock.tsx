"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { StatsPageClient } from "@/components/kennel/StatsPageClient";

export function StatsListBlock() {
  const { statsRows, kennelData } = useKennelData();

  if (!statsRows) {
    return (
      <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] p-12 text-center opacity-60">
        Stats data not available on this page.
      </div>
    );
  }

  return (
    <StatsPageClient
      rows={statsRows}
      kennelName={kennelData.KennelName}
      kennelShortName={kennelData.KennelShortName}
    />
  );
}
