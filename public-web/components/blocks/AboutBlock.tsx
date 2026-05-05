"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { Card, CardContent } from "@/components/ui/card";

export function AboutBlock() {
  const { kennelData } = useKennelData();
  const description = kennelData.KennelDescription ?? kennelData.WelcomeText;

  return (
    <div className="relative z-10 mx-auto w-full max-w-3xl px-4 pb-12 md:px-6">
      <h1 className="text-4xl font-black mb-6 md:text-5xl" style={{ color: "var(--kennel-text-title)" }}>
        About {kennelData.KennelName}
      </h1>
      <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
        <CardContent className="p-6 md:p-8">
          {description ? (
            <p className="text-lg leading-relaxed whitespace-pre-wrap" style={{ color: "var(--kennel-text-body)" }}>
              {description}
            </p>
          ) : (
            <p className="text-lg leading-relaxed" style={{ color: "var(--kennel-text-muted)" }}>
              More information about this kennel is coming soon.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
