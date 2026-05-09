"use client";

export type PaddingValue = { top: number; right: number; bottom: number; left: number };

export interface StepOption { label: string; value: number }

// Block padding — vertical in px, horizontal in %
export const BLOCK_V: StepOption[] = [
  { label: "—",  value: 0   },
  { label: "S",  value: 16  },
  { label: "M",  value: 40  },
  { label: "L",  value: 80  },
  { label: "XL", value: 128 },
];
export const BLOCK_H: StepOption[] = [
  { label: "—",  value: 0  },
  { label: "S",  value: 5  },
  { label: "M",  value: 10 },
  { label: "L",  value: 20 },
  { label: "XL", value: 30 },
];

// Spacing — moderate scale for gaps between elements (all px)
export const SPACING_V: StepOption[] = [
  { label: "—",  value: 0  },
  { label: "S",  value: 8  },
  { label: "M",  value: 16 },
  { label: "L",  value: 32 },
  { label: "XL", value: 64 },
];
export const SPACING_H: StepOption[] = [
  { label: "—",  value: 0  },
  { label: "S",  value: 8  },
  { label: "M",  value: 16 },
  { label: "L",  value: 32 },
  { label: "XL", value: 64 },
];

function cycle(current: number, options: StepOption[]): number {
  const idx = options.findIndex(o => o.value === current);
  return options[idx === -1 ? 0 : (idx + 1) % options.length].value;
}

function getLabel(current: number, options: StepOption[]): string {
  return options.find(o => o.value === current)?.label ?? "—";
}

interface Props {
  label: string;
  value: PaddingValue;
  onChange: (val: PaddingValue) => void;
  verticalOptions: StepOption[];
  horizontalOptions: StepOption[];
}

function arm(active: boolean): React.CSSProperties {
  return {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: "2px",
    width: "100%",
    height: "100%",
    borderRadius: "6px",
    border: `2px solid ${active ? "#0091ff" : "#e5e7eb"}`,
    background: active ? "#e8f4ff" : "white",
    color: active ? "#0057b3" : "#9ca3af",
    cursor: "pointer",
    fontSize: "11px",
    fontWeight: 700,
    lineHeight: 1,
  };
}

const GRID: React.CSSProperties = {
  display: "grid",
  gridTemplateColumns: "52px 52px 52px",
  gridTemplateRows: "44px 44px 44px",
  gap: "4px",
  justifyContent: "center",
};

const CENTRE: React.CSSProperties = {
  background: "#f3f4f6",
  borderRadius: "6px",
  width: "100%",
  height: "100%",
};

const LABEL_STYLE: React.CSSProperties = {
  fontSize: "11px",
  fontWeight: 600,
  color: "#6b7280",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  marginBottom: "8px",
};

export function PaddingCrossField({ label, value, onChange, verticalOptions, horizontalOptions }: Props) {
  const v = value ?? { top: 0, right: 0, bottom: 0, left: 0 };
  const set = (side: keyof PaddingValue, opts: StepOption[]) =>
    onChange({ ...v, [side]: cycle(v[side], opts) });

  return (
    <div>
      <div style={LABEL_STYLE}>{label}</div>
      <div style={GRID}>
        <div /><button type="button" style={arm(v.top !== 0)} onClick={() => set("top", verticalOptions)} title="Top"><span style={{ fontSize: "14px" }}>↑</span><span>{getLabel(v.top, verticalOptions)}</span></button><div />
        <button type="button" style={arm(v.left !== 0)} onClick={() => set("left", horizontalOptions)} title="Left"><span style={{ fontSize: "14px" }}>←</span><span>{getLabel(v.left, horizontalOptions)}</span></button><div style={CENTRE} /><button type="button" style={arm(v.right !== 0)} onClick={() => set("right", horizontalOptions)} title="Right"><span style={{ fontSize: "14px" }}>→</span><span>{getLabel(v.right, horizontalOptions)}</span></button>
        <div /><button type="button" style={arm(v.bottom !== 0)} onClick={() => set("bottom", verticalOptions)} title="Bottom"><span style={{ fontSize: "14px" }}>↓</span><span>{getLabel(v.bottom, verticalOptions)}</span></button><div />
      </div>
    </div>
  );
}
