"use client";

import { ICON_LIST } from "./icons";

const CELL_BASE: React.CSSProperties = {
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  gap: "4px",
  padding: "8px 4px",
  borderRadius: "4px",
  cursor: "pointer",
  fontSize: "10px",
  color: "#6b7280",
  lineHeight: 1.2,
  textAlign: "center",
};

const ACTIVE_STYLE: React.CSSProperties = {
  border: "2px solid #0091ff",
  background: "#e8f4ff",
  color: "#0057b3",
};

const INACTIVE_STYLE: React.CSSProperties = {
  border: "2px solid #e5e7eb",
  background: "white",
};

interface Props {
  value: string;
  onChange: (val: string) => void;
}

export function IconPickerField({ value, onChange }: Props) {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "4px" }}>
      {ICON_LIST.map(({ name, Icon, label }) => {
        const isActive = value === name;
        return (
          <button
            key={name}
            type="button"
            title={label}
            onClick={() => onChange(isActive ? "" : name)}
            style={{ ...CELL_BASE, ...(isActive ? ACTIVE_STYLE : INACTIVE_STYLE) }}
          >
            <Icon size={18} />
            <span>{label}</span>
          </button>
        );
      })}
    </div>
  );
}
