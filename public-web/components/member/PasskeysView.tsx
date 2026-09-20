"use client";

import { useState } from "react";
import { KeyRound, Loader2, Smartphone, Monitor } from "lucide-react";
import type { Passkey } from "@/lib/member-api";

/**
 * The passkeys on this account, with a Remove on each (E9.F7.S18).
 *
 * Removing asks twice. This is the one control in the member area that takes
 * access away, and on a phone the Remove sits under a thumb that was
 * scrolling a moment ago.
 */
export function PasskeysView({ initial }: { initial: Passkey[] }) {
  const [keys, setKeys] = useState<Passkey[]>(initial);
  const [confirming, setConfirming] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState("");
  const [done, setDone] = useState("");

  async function remove(k: Passkey) {
    setBusy(k.DeviceId); setError(""); setDone("");
    try {
      const res = await fetch("/api/member/passkeys", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ targetDeviceId: k.DeviceId }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok) { setError(data?.error ?? "That passkey could not be removed."); return; }
      setKeys(data.passkeys ?? []);
      setDone(`${k.Label} can no longer sign you in.`);
    } catch {
      setError("That passkey could not be removed just now.");
    } finally {
      setBusy(null); setConfirming(null);
    }
  }

  return (
    <div className="pt-3">
      <h2 className="mb-1 flex items-center gap-2 text-xl font-bold">
        <KeyRound className="h-5 w-5" /> Passkeys
      </h2>
      <p className="mb-4 text-sm text-white/70">
        A passkey signs you in with your face, fingerprint or screen lock — no code, no password.
      </p>

      {keys.length === 0 ? (
        <div className="rounded-2xl border border-white/10 bg-black/30 p-5 text-sm text-white/70">
          No passkeys yet. Next time you sign in with an email code, say yes when we offer to
          remember this device — that is what makes one.
        </div>
      ) : (
        <ul className="space-y-2">
          {keys.map((k) => {
            const isConfirming = confirming === k.DeviceId;
            const isBusy = busy === k.DeviceId;
            return (
              <li key={k.DeviceId} className="rounded-2xl border border-white/10 bg-black/30 p-4">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex min-w-0 items-center gap-3">
                    {k.IsMobile === 1 ? <Smartphone className="h-5 w-5 shrink-0 text-white/70" />
                                      : <Monitor className="h-5 w-5 shrink-0 text-white/70" />}
                    <div className="min-w-0">
                      <p className="truncate font-semibold">
                        {k.Label}
                        {k.IsThisDevice === 1 && (
                          <span className="ml-2 rounded-full bg-white/15 px-2 py-0.5 text-xs font-normal align-middle">
                            This device
                          </span>
                        )}
                      </p>
                      <p className="text-xs text-white/60">
                        {k.LastLogin ? `Last used ${new Date(k.LastLogin).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}` : "Not used yet"}
                      </p>
                    </div>
                  </div>

                  {isConfirming ? (
                    <div className="flex items-center gap-2">
                      <button type="button" disabled={isBusy} onClick={() => remove(k)}
                        className="inline-flex items-center gap-2 rounded-full bg-red-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50">
                        {isBusy && <Loader2 className="h-4 w-4 animate-spin" />} Remove it
                      </button>
                      <button type="button" disabled={isBusy} onClick={() => setConfirming(null)}
                        className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold disabled:opacity-50">
                        Keep
                      </button>
                    </div>
                  ) : (
                    <button type="button" onClick={() => { setConfirming(k.DeviceId); setError(""); setDone(""); }}
                      className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold hover:bg-white/20">
                      Remove
                    </button>
                  )}
                </div>

                {isConfirming && (
                  <p className="mt-3 text-sm text-white/70">
                    {k.IsThisDevice === 1
                      ? "This is the device you are using. Removing its passkey will not sign you out — you will just need an email code next time."
                      : "That device will need an email code to sign in again."}
                  </p>
                )}
              </li>
            );
          })}
        </ul>
      )}

      {done && <p className="mt-4 text-sm text-green-400">{done}</p>}
      {error && <p className="mt-4 text-sm text-red-400">{error}</p>}

      {keys.length > 0 && (
        // The half people get wrong: revoking here stops the server accepting
        // the credential, but the phone or browser still holds its copy and
        // will keep offering it until it is deleted there too.
        <p className="mt-6 rounded-2xl border border-white/10 bg-black/20 p-4 text-xs text-white/60">
          Removing a passkey here stops it signing you in. The passkey itself still sits in the
          device&apos;s own password manager — on an iPhone or Mac, Settings → Passwords →
          hashruns.org — and you can delete it there too if you want it gone for good.
        </p>
      )}
    </div>
  );
}
