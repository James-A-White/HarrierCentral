"use client";

import { useState } from "react";
import { KeyRound, Loader2, Smartphone, Monitor } from "lucide-react";
import type { Passkey } from "@/lib/member-api";

/**
 * Everything that can reach this account, with the two ways to take that
 * away: sign the device out, or remove its passkey (E9.F7.S18, E9.F7.S19).
 *
 * Both ask twice. These are the controls in the member area that take access
 * away, and on a phone they sit under a thumb that was scrolling a moment ago.
 *
 * A row disappears once the device is BOTH signed out and passkey-free — at
 * that point it cannot reach the account by any route, so there is nothing
 * left to show (James, 2026-09-20).
 */
export function PasskeysView({ initial }: { initial: Passkey[] }) {
  const [keys, setKeys] = useState<Passkey[]>(initial);
  const [confirming, setConfirming] = useState<string | null>(null);
  const [confirmingSignOut, setConfirmingSignOut] = useState<string | null>(null);
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

  async function signOut(k: Passkey) {
    setBusy(k.DeviceId); setError(""); setDone("");
    try {
      const res = await fetch("/api/member/passkeys", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ targetDeviceId: k.DeviceId }),
      });
      const data = await res.json().catch(() => null);
      if (!res.ok) { setError(data?.error ?? "That device could not be signed out."); return; }
      setKeys(data.passkeys ?? []);
      setDone(`${k.Label} has been signed out.`);
    } catch {
      setError("That device could not be signed out just now.");
    } finally {
      setBusy(null); setConfirmingSignOut(null);
    }
  }

  return (
    <div className="pt-3">
      <h2 className="mb-1 flex items-center gap-2 text-xl font-bold">
        <KeyRound className="h-5 w-5" /> Devices
      </h2>
      <p className="mb-4 text-sm text-white/70">
Everything signed in to your account. Sign out anything you no longer have; remove a passkey to stop its one-tap sign-in.
      </p>

      {keys.length === 0 ? (
        <div className="rounded-2xl border border-white/10 bg-black/30 p-5 text-sm text-white/70">
Nothing is signed in to your account but this browser.
        </div>
      ) : (
        <ul className="space-y-2">
          {keys.map((k) => {
            const isConfirming = confirming === k.DeviceId;
            const isConfirmingOut = confirmingSignOut === k.DeviceId;
            const isBusy = busy === k.DeviceId;
            const hasPasskey = k.HasPasskey !== 0;   // absent ⇒ older SP, always a passkey
            const isSignedOut = k.IsSignedOut === 1;
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
                        {[
                          k.LastLogin
                            ? `Last used ${new Date(k.LastLogin).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" })}`
                            : "Not used yet",
                          ...(hasPasskey ? ["passkey"] : []),
                          ...(isSignedOut ? ["signed out"] : []),
                        ].join(" · ")}
                      </p>
                    </div>
                  </div>

                  {isConfirming ? (
                    <div className="flex items-center gap-2">
                      <button type="button" disabled={isBusy} onClick={() => remove(k)}
                        className="inline-flex items-center gap-2 rounded-full bg-red-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50">
                        {isBusy && <Loader2 className="h-4 w-4 animate-spin" />} Remove passkey
                      </button>
                      <button type="button" disabled={isBusy} onClick={() => setConfirming(null)}
                        className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold disabled:opacity-50">
                        Keep
                      </button>
                    </div>
                  ) : isConfirmingOut ? (
                    <div className="flex items-center gap-2">
                      <button type="button" disabled={isBusy} onClick={() => signOut(k)}
                        className="inline-flex items-center gap-2 rounded-full bg-red-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50">
                        {isBusy && <Loader2 className="h-4 w-4 animate-spin" />} Sign it out
                      </button>
                      <button type="button" disabled={isBusy} onClick={() => setConfirmingSignOut(null)}
                        className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold disabled:opacity-50">
                        Leave it
                      </button>
                    </div>
                  ) : (
                    <div className="flex flex-wrap items-center gap-2">
                      {hasPasskey && (
                        <button type="button" onClick={() => { setConfirming(k.DeviceId); setError(""); setDone(""); }}
                          className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold hover:bg-white/20">
                          Remove passkey
                        </button>
                      )}
                      {/* Already-signed-out rows are only still listed because
                          they hold a passkey — there is nothing left to sign out. */}
                      {!isSignedOut && (
                        <button type="button" onClick={() => { setConfirmingSignOut(k.DeviceId); setError(""); setDone(""); }}
                          className="rounded-full bg-white/12 px-4 py-2 text-sm font-semibold hover:bg-white/20">
                          Sign out
                        </button>
                      )}
                    </div>
                  )}
                </div>

                {isConfirming && (
                  <p className="mt-3 text-sm text-white/70">
                    {k.IsThisDevice === 1
                      ? "This is the device you are using. Removing its passkey will not sign you out — you will just need an email code next time."
                      : "That device will need an email code to sign in again."}
                  </p>
                )}
                {isConfirmingOut && (
                  <p className="mt-3 text-sm text-white/70">
                    {k.IsThisDevice === 1
                      ? "This is the browser you are using. It will be signed out and you will have to sign in again."
                      : "That device loses access at once and stops receiving your notifications."}
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
          Signing a device out takes its access away at once and stops its notifications.
          Removing a passkey stops that one-tap sign-in — the passkey itself still sits in the
          device&apos;s own password manager (on an iPhone or Mac, Settings → Passwords →
          hashruns.org) until you delete it there too.
        </p>
      )}
    </div>
  );
}
