"use client";

/**
 * The app's floating action button (flutter_speed_dial): a round button
 * bottom-right that swaps to a close cross, dims the page behind it, and
 * fans its actions upward, each a white label beside a coloured disc.
 * Used on the run history drill-downs, as in the app.
 */
import { useEffect, useState } from "react";
import { Menu, X } from "lucide-react";

export interface SpeedDialAction {
  label: string;
  color: string;
  icon: React.ReactNode;
  onSelect: () => void | Promise<void>;
}

export function SpeedDial({ actions, color = "#1565C0", busy }: {
  actions: SpeedDialAction[]; color?: string; busy?: boolean;
}) {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") setOpen(false); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <>
      {/* The app dims everything behind the dial at 50% */}
      {open && <div className="fixed inset-0 z-40 bg-black/50" onClick={() => setOpen(false)} aria-hidden="true" />}

      <div className="fixed bottom-24 right-4 z-50 flex flex-col items-end gap-4">
        {open && actions.map((a, i) => (
          <button
            key={i}
            type="button"
            disabled={busy}
            onClick={async () => { setOpen(false); await a.onSelect(); }}
            className="flex items-center gap-3 disabled:opacity-60"
          >
            <span className="whitespace-pre-line rounded-md bg-white px-4 py-2 text-left text-[18px] leading-tight text-zinc-900 shadow-lg">
              {a.label}
            </span>
            <span className="flex h-14 w-14 items-center justify-center rounded-full text-white shadow-xl" style={{ backgroundColor: a.color }}>
              {a.icon}
            </span>
          </button>
        ))}

        <button
          type="button"
          aria-label={open ? "Close menu" : "More actions"}
          aria-expanded={open}
          onClick={() => setOpen((o) => !o)}
          className="flex h-14 w-14 items-center justify-center rounded-full text-white shadow-xl transition-transform"
          style={{ backgroundColor: color }}
        >
          {open ? <X className="h-7 w-7" /> : <Menu className="h-7 w-7" />}
        </button>
      </div>
    </>
  );
}
