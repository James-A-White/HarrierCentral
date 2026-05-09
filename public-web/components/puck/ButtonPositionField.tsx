"use client";

const GRID = [
  [
    { value: "top-left",    label: "Top left",      symbol: "↖" },
    { value: "top-center",  label: "Top centre",    symbol: "↑" },
    { value: "top-right",   label: "Top right",     symbol: "↗" },
  ],
  [
    { value: "bottom-left",   label: "Bottom left",   symbol: "↙" },
    { value: "bottom-center", label: "Bottom centre", symbol: "↓" },
    { value: "bottom-right",  label: "Bottom right",  symbol: "↘" },
  ],
] as const;

const ACTIVE_STYLE: React.CSSProperties = {
  border: "2px solid #0091ff",
  background: "#e8f4ff",
};

const INACTIVE_STYLE: React.CSSProperties = {
  border: "2px solid #e5e7eb",
  background: "white",
};

const CELL_STYLE: React.CSSProperties = {
  padding: "10px",
  borderRadius: "4px",
  fontSize: "18px",
  lineHeight: 1,
  cursor: "pointer",
  width: "100%",
};

const ROW_LABEL_STYLE: React.CSSProperties = {
  fontSize: "11px",
  color: "#9ca3af",
  fontWeight: 600,
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  marginBottom: "4px",
};

interface Props {
  value: string;
  onChange: (val: string) => void;
}

export function ButtonPositionField({ value, onChange }: Props) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
      {GRID.map((row, rowIndex) => (
        <div key={rowIndex}>
          <div style={ROW_LABEL_STYLE}>{rowIndex === 0 ? "Above content" : "Below content"}</div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "4px" }}>
            {row.map((cell) => (
              <button
                key={cell.value}
                type="button"
                title={cell.label}
                onClick={() => onChange(value === cell.value ? "" : cell.value)}
                style={{ ...CELL_STYLE, ...(value === cell.value ? ACTIVE_STYLE : INACTIVE_STYLE) }}
              >
                {cell.symbol}
              </button>
            ))}
          </div>
        </div>
      ))}
      {value && (
        <button
          type="button"
          onClick={() => onChange("")}
          style={{ fontSize: "12px", color: "#6b7280", background: "none", border: "none", cursor: "pointer", textAlign: "left", padding: 0 }}
        >
          ✕ Remove button
        </button>
      )}
    </div>
  );
}
