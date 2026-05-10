"use client";

import type { RowLayout } from "@/components/puck/RowLayoutField";
import type React from "react";

// All class combinations written as literals so Tailwind's scanner includes them.

export const DIR_CLASSES: Record<string, string> = {
  sm:    "flex-col sm:flex-row",
  md:    "flex-col md:flex-row",
  lg:    "flex-col lg:flex-row",
  never: "flex-row",
};

export const ALIGN_CLASSES: Record<string, Record<string, string>> = {
  sm: {
    "flex-start": "sm:items-start",
    center:       "sm:items-center",
    stretch:      "sm:items-stretch",
  },
  md: {
    "flex-start": "md:items-start",
    center:       "md:items-center",
    stretch:      "md:items-stretch",
  },
  lg: {
    "flex-start": "lg:items-start",
    center:       "lg:items-center",
    stretch:      "lg:items-stretch",
  },
  never: {
    "flex-start": "items-start",
    center:       "items-center",
    stretch:      "items-stretch",
  },
};

interface Props {
  layout: RowLayout;
  gap: number;
  verticalAlign: "flex-start" | "center" | "stretch";
  collapseBelow?: string;
  children: React.ReactNode;
}

export function RowBlock({ layout, gap, verticalAlign, collapseBelow = "sm", children }: Props) {
  const bp         = collapseBelow in DIR_CLASSES ? collapseBelow : "sm";
  const dirClass   = DIR_CLASSES[bp];
  const alignClass = ALIGN_CLASSES[bp][verticalAlign] ?? "";

  return (
    <div className={`flex ${dirClass} ${alignClass}`} style={{ gap }}>
      {children}
    </div>
  );
}
