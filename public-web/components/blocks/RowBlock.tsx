"use client";

import { DropZone } from "@measured/puck";
import type { RowLayout } from "@/components/puck/RowLayoutField";

interface Props {
  layout: RowLayout;
  gap: number;
  verticalAlign: "flex-start" | "center" | "stretch";
}

export function RowBlock({ layout, gap, verticalAlign }: Props) {
  const { columns, flex } = layout;
  return (
    <div style={{ display: "flex", gap, alignItems: verticalAlign }}>
      {Array.from({ length: columns }).map((_, i) => (
        <div key={i} style={{ flex: flex[i], minWidth: 0 }}>
          <DropZone zone={`column-${i}`} disallow={["RowBlock"]} />
        </div>
      ))}
    </div>
  );
}
