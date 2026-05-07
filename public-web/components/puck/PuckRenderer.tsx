"use client";

import { Render } from "@measured/puck";
import type { Data } from "@measured/puck";
import { createPuckConfig } from "./config";

const puckConfig = createPuckConfig("");
import { KennelDataProvider } from "./KennelDataContext";
import type { KennelPageData } from "./KennelDataContext";

interface PuckRendererProps {
  data: Data;
  pageData: KennelPageData;
}

export function PuckRenderer({ data, pageData }: PuckRendererProps) {
  return (
    <KennelDataProvider data={pageData}>
      <Render config={puckConfig} data={data} />
    </KennelDataProvider>
  );
}
