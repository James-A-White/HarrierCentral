"use client";

import { Music2 } from "lucide-react";
import { useKennelData } from "@/components/puck/KennelDataContext";
import { SongsSection } from "@/components/kennel/SongsSection";

export function SongsListBlock() {
  const { songs, slug } = useKennelData();

  if (!songs) {
    return (
      <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] p-12 flex flex-col items-center gap-3 text-center">
        <Music2 className="h-8 w-8 opacity-40" />
        <p className="text-xl opacity-60">Songs data not available on this page.</p>
      </div>
    );
  }

  if (songs.length === 0) {
    return (
      <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] p-12 flex flex-col items-center gap-3 text-center">
        <Music2 className="h-8 w-8" style={{ color: "var(--kennel-text-muted)" }} />
        <p className="text-2xl" style={{ color: "var(--kennel-text-body)" }}>
          No songs have been added yet.
        </p>
      </div>
    );
  }

  return <SongsSection songs={songs} slug={slug} />;
}
