"use client";

import { useState } from "react";
import { Loader2, MessageCircle } from "lucide-react";
import type { DmPreference } from "@/lib/member-api";

const OPTIONS: { value: DmPreference; label: string; hint: string }[] = [
  { value: 0, label: "Friends only", hint: "Anyone else who wants to message you has to ask first." },
  { value: 1, label: "Anyone", hint: "Any hasher can open a conversation with you." },
  { value: 2, label: "Nobody", hint: "Nobody can start a conversation with you. Existing ones stay open." },
];

/**
 * Who may message me (E9.F1.S18): a three-way control that saves on each
 * tap and repaints from the server's reply, so what is shown is what is
 * stored. Friends only is the default and needs no data to be so.
 */
export function DirectMessagePreferenceView({ initial }: { initial: DmPreference }) {
  const [value, setValue] = useState<DmPreference>(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [done, setDone] = useState("");

  async function save(p: DmPreference) {
    if (busy || p === value) return;
    setBusy(true); setError(""); setDone("");
    try {
      const res = await fetch("/api/member/dm/preference", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ preference: p }),
      });
      const data = (await res.json().catch(() => null)) as { error?: string; preference?: DmPreference } | null;
      if (!res.ok) { setError(data?.error ?? "That setting could not be saved."); return; }
      const stored = data?.preference ?? p;
      setValue(stored);
      setDone(`Saved: ${OPTIONS.find((o) => o.value === stored)?.label ?? ""}.`);
    } catch {
      setError("That setting could not be saved just now.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="pt-3">
      <h2 className="mb-1 flex items-center gap-2 text-xl font-bold">
        <MessageCircle className="h-5 w-5" /> Direct messages
      </h2>
      <p className="mb-4 text-sm text-white/70">
        Who can message you directly. Friends are hashers who have accepted your request, or whose request you accepted.
      </p>
      <div className="rounded-2xl border border-white/10 bg-black/30 p-4">
        <div role="radiogroup" aria-label="Who can message you" className="flex flex-wrap justify-center gap-2">
          {OPTIONS.map((o) => {
            const on = o.value === value;
            return (
              <button key={o.value} type="button" role="radio" aria-checked={on} disabled={busy} onClick={() => save(o.value)}
                className={`inline-flex items-center gap-2 rounded-full px-4 py-2 text-center text-sm font-semibold transition disabled:opacity-60 ${on ? "bg-white text-zinc-900" : "bg-white/12 text-white hover:bg-white/20"}`}>
                {busy && on && <Loader2 className="h-4 w-4 animate-spin" />}
                {o.label}
              </button>
            );
          })}
        </div>
        <p className="mt-3 text-center text-sm text-white/70">{OPTIONS.find((o) => o.value === value)?.hint}</p>
      </div>
      {done && <p className="mt-3 text-center text-sm text-green-400">{done}</p>}
      {error && <p className="mt-3 text-center text-sm text-red-400">{error}</p>}
    </section>
  );
}
