"use client";

import { useState } from "react";
import { Loader2, UserX } from "lucide-react";
import type { BlockedHasher } from "@/lib/member-api";

/**
 * Everyone this member has blocked, and the way to undo it (E9.F1.S16).
 *
 * Unblock asks twice, as the Devices page does: this is the one control
 * here that changes what reaches them, and on a phone it sits under a thumb
 * that was scrolling a moment ago. The list repaints from the server's
 * reply, never from a guess.
 */
export function BlockedHashersView({ initial }: { initial: BlockedHasher[] }) {
  const [blocked, setBlocked] = useState<BlockedHasher[]>(initial);
  const [confirming, setConfirming] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [done, setDone] = useState("");

  async function unblock(h: BlockedHasher) {
    setBusy(h.PublicHasherId); setError(""); setDone("");
    try {
      const res = await fetch("/api/member/blocked", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ targetPublicHasherId: h.PublicHasherId.toLowerCase(), blocked: 0 }),
      });
      const data = (await res.json().catch(() => null)) as { error?: string; blocked?: BlockedHasher[] } | null;
      if (!res.ok) { setError(data?.error ?? "They could not be unblocked."); return; }
      setBlocked(data?.blocked ?? []);
      setDone(`${h.DisplayName} is unblocked. Their messages will show again.`);
    } catch {
      setError("They could not be unblocked just now.");
    } finally {
      setBusy(null); setConfirming(null);
    }
  }

  return (
    <div className="pt-3">
      <h2 className="mb-1 flex items-center gap-2 text-xl font-bold">
        <UserX className="h-5 w-5" /> Blocked hashers
      </h2>
      <p className="mb-4 text-sm text-white/70">
        You don&apos;t see a blocked hasher&apos;s messages in any chat, and they aren&apos;t told. Block someone from the menu on one of their messages.
      </p>

      {blocked.length === 0 ? (
        <div className="rounded-2xl border border-white/10 bg-black/30 p-5 text-sm text-white/70">
          You haven&apos;t blocked anyone.
        </div>
      ) : (
        <ul className="space-y-2">
          {blocked.map((h) => {
            const isConfirming = confirming === h.PublicHasherId;
            const isBusy = busy === h.PublicHasherId;
            return (
              <li key={h.PublicHasherId} className="rounded-2xl border border-white/10 bg-black/30 p-4">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex min-w-0 items-center gap-3">
                    {/* A hasher's photo is a portrait, so it keeps the circle. */}
                    <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full bg-white/15">
                      {h.Photo?.startsWith("http") && (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={h.Photo} alt="" className="h-full w-full object-cover" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate font-semibold">{h.DisplayName}</p>
                      <p className="text-xs text-white/60" suppressHydrationWarning>
                        Blocked {new Date(h.BlockedAt).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}
                      </p>
                    </div>
                  </div>

                  {isConfirming ? (
                    <div className="flex items-center gap-2">
                      <button type="button" disabled={isBusy} onClick={() => unblock(h)}
                        className="inline-flex items-center gap-2 rounded-full bg-red-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50">
                        {isBusy && <Loader2 className="h-4 w-4 animate-spin" />} Unblock
                      </button>
                      <button type="button" disabled={isBusy} onClick={() => setConfirming(null)}
                        className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold disabled:opacity-50">
                        Keep blocked
                      </button>
                    </div>
                  ) : (
                    <button type="button" onClick={() => { setConfirming(h.PublicHasherId); setError(""); setDone(""); }}
                      className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold hover:bg-white/20">
                      Unblock
                    </button>
                  )}
                </div>

                {isConfirming && (
                  <p className="mt-3 text-sm text-white/70">
                    Their messages will show in your chats again, and their notifications will reach you.
                  </p>
                )}
              </li>
            );
          })}
        </ul>
      )}

      {done && <p className="mt-4 text-sm text-green-400">{done}</p>}
      {error && <p className="mt-4 text-sm text-red-400">{error}</p>}
    </div>
  );
}
