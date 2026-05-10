"use client";

import { RichText } from "@/components/ui/RichText";
import type { PaddingValue } from "@/components/puck/PaddingCrossField";

interface RichTextBlockProps {
  content: string;
  textColor: string;
  align: "left" | "center" | "right";
  maxWidth: boolean;
  padding: PaddingValue;
  blockBg: string;
}

export function RichTextBlock({ content, textColor, align, maxWidth, padding, blockBg }: RichTextBlockProps) {
  return (
    <div
      style={{
        paddingTop:    `${padding?.top    ?? 0}px`,
        paddingBottom: `${padding?.bottom ?? 0}px`,
        paddingLeft:   `${padding?.left   ?? 0}%`,
        paddingRight:  `${padding?.right  ?? 0}%`,
        backgroundColor: blockBg || undefined,
      }}
    >
      <div className={maxWidth ? "max-w-2xl" : "w-full"}>
        <RichText
          content={content}
          color={textColor || undefined}
          align={align}
        />
      </div>
    </div>
  );
}
