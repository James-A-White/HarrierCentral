"use client";

import { Render, migrate } from "@measured/puck";
import type { Data } from "@measured/puck";
import { useMemo } from "react";
import { createPuckConfig } from "./config";
import { KennelDataProvider } from "./KennelDataContext";
import type { KennelPageData } from "./KennelDataContext";

interface PuckRendererProps {
  data: Data;
  pageData: KennelPageData;
}

export function PuckRenderer({ data, pageData }: PuckRendererProps) {
  // migrate() converts legacy DropZone zone data to the current slot format
  // transparently, so old saved layouts continue to render correctly.
  const puckConfig = useMemo(() => createPuckConfig(""), []);
  const migratedData = useMemo(() => migrate(data, puckConfig), [data, puckConfig]);

  return (
    <KennelDataProvider data={pageData}>
      <Render config={puckConfig} data={migratedData} />
    </KennelDataProvider>
  );
}
