"use client";

import dynamic from "next/dynamic";
import type { MyRun } from "@/lib/member-api";

// Leaflet touches window at import time, so the map is client-only.
const MyRunsMap = dynamic(() => import("./MyRunsMap"), {
  ssr: false,
  loading: () => <div className="h-[70vh] min-h-[360px] animate-pulse rounded-2xl bg-black/30" />,
});

export function MyRunsMapLoader({ runs }: { runs: MyRun[] }) {
  return <MyRunsMap runs={runs} />;
}
