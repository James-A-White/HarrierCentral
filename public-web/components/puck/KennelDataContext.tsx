"use client";

import { createContext, useContext } from "react";
import type { RunEvent, KennelLandingData } from "@/lib/api";

export interface KennelPageData {
  kennelData: KennelLandingData;
  slug: string;
  futureRuns: RunEvent[];
  pastRuns: RunEvent[];
}

const KennelDataContext = createContext<KennelPageData | null>(null);

export function KennelDataProvider({
  data,
  children,
}: {
  data: KennelPageData;
  children: React.ReactNode;
}) {
  return (
    <KennelDataContext.Provider value={data}>
      {children}
    </KennelDataContext.Provider>
  );
}

export function useKennelData(): KennelPageData {
  const ctx = useContext(KennelDataContext);
  if (!ctx) throw new Error("useKennelData must be used inside KennelDataProvider");
  return ctx;
}
