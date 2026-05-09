"use client";

import type { StepOption } from "./PaddingCrossField";

interface Props {
  label: string;
  value: number;
  onChange: (val: number) => void;
  options: StepOption[];
}

export function StepCycleField({ label, value, onChange, options }: Props) {
  function cycle() {
    const idx = options.findIndex(o => o.value === value);
    onChange(options[idx === -1 ? 0 : (idx + 1) % options.length].value);
  }

  const current = options.find(o => o.value === value)?.label ?? "—";
  const isOff = value === options[0].value;

  return (
    <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
      <span style={{
        flex: 1,
        fontSize: "11px",
        fontWeight: 600,
        color: "#6b7280",
        textTransform: "uppercase",
        letterSpacing: "0.05em",
      }}>
        {label}
      </span>
      <button
        type="button"
        onClick={cycle}
        style={{
          width: "52px",
          height: "32px",
          borderRadius: "6px",
          border: `2px solid ${isOff ? "#e5e7eb" : "#0091ff"}`,
          background: isOff ? "white" : "#e8f4ff",
          color: isOff ? "#9ca3af" : "#0057b3",
          cursor: "pointer",
          fontSize: "11px",
          fontWeight: 700,
          lineHeight: 1,
        }}
      >
        {current}
      </button>
    </div>
  );
}
