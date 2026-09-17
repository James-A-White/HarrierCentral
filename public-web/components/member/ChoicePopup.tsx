"use client";

/**
 * The app's option list dialog (Utilities.showOptionsDialog): a white sheet
 * of rows, each an icon and a title, one tap chooses. Used for the follow
 * checkbox, the bell and the envelope on kennel cards and run cards.
 */
import { useEffect } from "react";

export interface Choice<T> { title: string; icon: string; value: T }

export function ChoicePopup<T>({ title, choices, onPick, onClose, busy }: {
  title?: string; choices: Choice<T>[]; onPick: (v: T) => void; onClose: () => void; busy?: boolean;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-6" onClick={onClose} role="dialog" aria-modal="true">
      <div className="w-full max-w-sm overflow-hidden rounded-2xl bg-white text-zinc-900 shadow-2xl" onClick={(e) => e.stopPropagation()}>
        {title && <div className="border-b border-zinc-200 px-5 py-3 text-[18px] font-bold">{title}</div>}
        <ul className="divide-y divide-zinc-200">
          {choices.map((c, i) => (
            <li key={i}>
              <button type="button" disabled={busy} onClick={() => onPick(c.value)}
                className="flex w-full items-center gap-4 px-5 py-3 text-left text-[18px] hover:bg-zinc-100 disabled:opacity-50">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                {c.icon.startsWith("lucide:") ? <HomeGlyph /> : <img src={`/images/icons/${c.icon}.png`} alt="" className="h-[30px] w-[30px] shrink-0" />}
                <span>{c.title}</span>
              </button>
            </li>
          ))}
        </ul>
        <button type="button" onClick={onClose} className="w-full border-t border-zinc-200 px-5 py-3 text-[17px] font-semibold text-zinc-600 hover:bg-zinc-100">Cancel</button>
      </div>
    </div>
  );
}

/** FontAwesome.home, red, as the app draws it in the follow popup. */
function HomeGlyph() {
  return (
    <svg viewBox="0 0 24 24" className="h-[30px] w-[30px] shrink-0" fill="#B71C1C" aria-hidden="true">
      <path d="M12 3 2 12h3v8h5v-6h4v6h5v-8h3L12 3z" />
    </svg>
  );
}

// ── The app's option sets ────────────────────────────────────────────────────

/** kennel_list_item._showFollowingPopup */
export function followChoices(distanceText: string, isHome: boolean): Choice<{ following?: 0 | 1 | 2; isHomeKennel?: 0 | 1 }>[] {
  return [
    { title: "Always show runs", icon: "checkbox_yes", value: { following: 1 } },
    { title: "Never show runs", icon: "checkbox_no", value: { following: 2 } },
    { title: `Show runs within ${distanceText}`, icon: "checkbox_empty", value: { following: 0 } },
    isHome ? { title: "Clear home kennel", icon: "lucide:home", value: { isHomeKennel: 0 } }
           : { title: "Set home kennel", icon: "lucide:home", value: { isHomeKennel: 1 } },
  ];
}

/** kennel_list_item._showNotificationPopup */
export const kennelBellChoices: Choice<number>[] = [
  { title: "Always on", icon: "bell_gold_50px", value: 1 },
  { title: "On 6 hours before run", icon: "bell_time_50px", value: 4 },
  { title: "On but muted", icon: "bell_silver_50px", value: 3 },
  { title: "Off", icon: "bell_silver_strike_out_50px", value: 2 },
];

/** kennel_list_item._showEmailPopup */
export const kennelEnvelopeChoices: Choice<number>[] = [
  { title: "Turn email alerts on", icon: "envelope_gold_50px", value: 1 },
  { title: "Turn email alerts off", icon: "envelope_silver_strike_out_50px", value: 2 },
];

/** run_list_item: the run's bell */
export const runBellChoices: Choice<number>[] = [
  { title: "Notifications on", icon: "bell_gold_50px", value: 1 },
  { title: "Notifications off", icon: "bell_silver_strike_out_50px", value: 2 },
];

/** run_list_item: the run's envelope */
export const runEnvelopeChoices: Choice<number>[] = [
  { title: "Send e-mail", icon: "envelope_gold_50px", value: 1 },
  { title: "Don't send email", icon: "envelope_silver_strike_out_50px", value: 2 },
];
