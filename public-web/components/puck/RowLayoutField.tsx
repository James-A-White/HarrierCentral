"use client";

export type RowLayout = {
  columns: 2 | 3 | 4;
  flex: [number, number, number, number];
};

interface Props {
  value: RowLayout;
  onChange: (val: RowLayout) => void;
}

const LABEL: React.CSSProperties = {
  fontSize: "11px",
  fontWeight: 600,
  color: "#6b7280",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  marginBottom: "6px",
};

const COL_LABEL: React.CSSProperties = {
  fontSize: "12px",
  color: "#6b7280",
  fontWeight: 500,
  width: "38px",
  flexShrink: 0,
};

const BTN: React.CSSProperties = {
  width: "40px",
  height: "32px",
  borderRadius: "6px",
  cursor: "pointer",
  fontSize: "13px",
  fontWeight: 700,
  lineHeight: 1,
};

const ACTIVE: React.CSSProperties = {
  border: "2px solid #0091ff",
  background: "#e8f4ff",
  color: "#0057b3",
};

const INACTIVE: React.CSSProperties = {
  border: "2px solid #e5e7eb",
  background: "white",
  color: "#9ca3af",
};

const SELECT: React.CSSProperties = {
  height: "30px",
  flex: 1,
  borderRadius: "4px",
  border: "1px solid #e5e7eb",
  fontSize: "13px",
  padding: "0 4px",
  background: "white",
};

const FLEX_OPTIONS = Array.from({ length: 10 }, (_, i) => i + 1);

export function RowLayoutField({ value, onChange }: Props) {
  function setColumns(n: 2 | 3 | 4) {
    onChange({ ...value, columns: n });
  }

  function setFlex(i: number, n: number) {
    const next = [...value.flex] as [number, number, number, number];
    next[i] = n;
    onChange({ ...value, flex: next });
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
      <div>
        <div style={LABEL}>Columns</div>
        <div style={{ display: "flex", gap: "4px" }}>
          {([2, 3, 4] as const).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setColumns(n)}
              style={{ ...BTN, ...(value.columns === n ? ACTIVE : INACTIVE) }}
            >
              {n}
            </button>
          ))}
        </div>
      </div>

      <div>
        <div style={LABEL}>Column widths (flex)</div>
        <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
          {[0, 1, 2, 3].map((i) => {
            const disabled = i >= value.columns;
            return (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  opacity: disabled ? 0.35 : 1,
                }}
              >
                <span style={COL_LABEL}>Col {i + 1}</span>
                <select
                  value={value.flex[i]}
                  disabled={disabled}
                  onChange={(e) => setFlex(i, Number(e.target.value))}
                  style={SELECT}
                >
                  {FLEX_OPTIONS.map((n) => (
                    <option key={n} value={n}>{n}</option>
                  ))}
                </select>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
