"use client";

import Link from "next/link";

type ButtonStyle = "primary" | "outline" | "ghost";
type ButtonAlign = "left" | "center" | "right";

type Props = {
  label: string;
  href: string;
  buttonStyle: ButtonStyle;
  align: ButtonAlign;
  paddingTop: number;
  paddingBottom: number;
};

const STYLE_MAP: Record<ButtonStyle, React.CSSProperties> = {
  primary: {
    backgroundColor: "var(--kennel-primary)",
    color: "var(--kennel-primary-fg)",
    border: "none",
  },
  outline: {
    backgroundColor: "transparent",
    color: "var(--kennel-primary)",
    border: "2px solid var(--kennel-primary)",
  },
  ghost: {
    backgroundColor: "transparent",
    color: "var(--kennel-text-body)",
    border: "none",
    textDecoration: "underline",
    textUnderlineOffset: "3px",
  },
};

const JUSTIFY_MAP: Record<ButtonAlign, string> = {
  left:   "flex-start",
  center: "center",
  right:  "flex-end",
};

export function ButtonBlock({ label, href, buttonStyle, align, paddingTop, paddingBottom }: Props) {
  return (
    <div
      style={{
        paddingTop: `${paddingTop}px`,
        paddingBottom: `${paddingBottom}px`,
        display: "flex",
        justifyContent: JUSTIFY_MAP[align],
      }}
    >
      <Link
        href={href || "#"}
        style={{
          display: "inline-flex",
          alignItems: "center",
          padding: "0.625rem 1.75rem",
          borderRadius: "9999px",
          fontSize: "1rem",
          fontWeight: 600,
          fontFamily: "system-ui, sans-serif",
          textDecoration: "none",
          transition: "opacity 0.15s ease",
          cursor: "pointer",
          whiteSpace: "nowrap",
          ...STYLE_MAP[buttonStyle],
        }}
      >
        {label || "Button"}
      </Link>
    </div>
  );
}
