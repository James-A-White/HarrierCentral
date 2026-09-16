"use client";

/**
 * Member sign-in — two doors, the person chooses (E9.F7, James 2026-09-16).
 *
 *  - On a computer: the QR first (point the phone's camera at it; the app
 *    approves), with "send me a code by email" beneath.
 *  - On a phone: the email code only — there is nothing to scan on a phone.
 *
 * Unknown email → ask for a hash name and create the member for the kennel
 * whose page this is. After any sign-in, offer a passkey so the next visit is
 * one tap. No recency rule, no gate: whoever has the app to hand scans,
 * whoever doesn't types.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import QRCode from "react-qr-code";
import { startRegistration, startAuthentication, browserSupportsWebAuthn } from "@simplewebauthn/browser";

export interface MemberSignInProps {
  slug: string;
  kennelName: string;
  /** Called once the member cookie is set. */
  onSignedIn: (hashName: string) => void;
  onCancel?: () => void;
  /** What the sign-in is for — shown as the title's second line. */
  reason?: string;
}

type Step =
  | { kind: "choose" }
  | { kind: "email" }
  | { kind: "signup"; email: string }
  | { kind: "code"; email: string; created: boolean }
  | { kind: "passkey-offer"; hashName: string }
  | { kind: "done"; hashName: string };

const isPhone = () =>
  typeof navigator !== "undefined" && /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);

async function post<T>(url: string, body?: object): Promise<T & { error?: string }> {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body ?? {}),
  });
  return (await res.json().catch(() => ({ error: "Something went wrong." }))) as T & { error?: string };
}

const inputClass =
  "w-full rounded-lg border border-zinc-300 bg-white px-3 py-2.5 text-base text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-[var(--kennel-primary)]";
const primaryBtn =
  "inline-flex w-full items-center justify-center rounded-full px-5 py-3 text-base font-semibold transition-opacity hover:opacity-85 disabled:opacity-50";
const linkBtn = "text-sm underline underline-offset-2 opacity-80 hover:opacity-100";

export function MemberSignIn({ slug, kennelName, onSignedIn, onCancel, reason }: MemberSignInProps) {
  const [phone, setPhone] = useState(true);
  const [step, setStep] = useState<Step>({ kind: "choose" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [remember, setRemember] = useState(true);
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [hashName, setHashName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");

  useEffect(() => {
    const onPhone = isPhone();
    setPhone(onPhone);
    // A phone has nothing to scan: go straight to the email door.
    if (onPhone) setStep({ kind: "email" });
  }, []);

  // ── QR door ─────────────────────────────────────────────────────────────────
  const [qr, setQr] = useState<{ ticket: string; url: string } | null>(null);
  const pollRef = useRef<number | null>(null);

  const stopPolling = useCallback(() => {
    if (pollRef.current) window.clearInterval(pollRef.current);
    pollRef.current = null;
  }, []);

  useEffect(() => {
    if (step.kind !== "choose" || phone) return;
    let cancelled = false;
    (async () => {
      const t = await post<{ ticket: string; url: string }>("/api/member/qr/start");
      if (cancelled || !t.ticket) return;
      setQr(t);
      pollRef.current = window.setInterval(async () => {
        const r = await post<{ pending?: boolean; ok?: boolean; hashName?: string }>("/api/member/qr/poll", {
          ticket: t.ticket, remember,
        });
        if (r.ok) {
          stopPolling();
          setStep({ kind: "passkey-offer", hashName: r.hashName ?? "" });
        } else if (r.error) {
          stopPolling();
          setQr(null);
          setError(r.error);
        }
      }, 2000);
    })();
    return () => { cancelled = true; stopPolling(); };
    // remember is read at poll time; re-arming on every toggle would restart the QR
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [step.kind, phone, stopPolling]);

  // ── Passkey door (returning member) ─────────────────────────────────────────
  async function signInWithPasskey() {
    setError(null); setBusy(true);
    try {
      const options = await post<Parameters<typeof startAuthentication>[0]["optionsJSON"]>("/api/member/passkey/login-options");
      const response = await startAuthentication({ optionsJSON: options });
      const r = await post<{ ok?: boolean; hashName?: string }>("/api/member/passkey/login-verify", { response, remember });
      if (r.ok) { stopPolling(); setStep({ kind: "done", hashName: r.hashName ?? "" }); onSignedIn(r.hashName ?? ""); }
      else setError(r.error ?? "That passkey didn't work.");
    } catch {
      // The person dismissed the prompt, or has no passkey here — not an error worth words.
    } finally { setBusy(false); }
  }

  async function addPasskey(hashNameForDone: string) {
    setBusy(true);
    try {
      const options = await post<Parameters<typeof startRegistration>[0]["optionsJSON"]>("/api/member/passkey/register-options");
      const response = await startRegistration({ optionsJSON: options });
      await post("/api/member/passkey/register-verify", response);
    } catch {
      // Declined or unsupported — the cookie already signs them in.
    } finally {
      setBusy(false);
      setStep({ kind: "done", hashName: hashNameForDone });
      onSignedIn(hashNameForDone);
    }
  }

  // ── Email door ──────────────────────────────────────────────────────────────
  async function requestCode() {
    setError(null); setBusy(true);
    try {
      const r = await post<{ sent?: boolean; known?: boolean }>("/api/member/request-code", { email });
      if (r.error) setError(r.error);
      else if (r.known) setStep({ kind: "code", email, created: false });
      else setStep({ kind: "signup", email });
    } finally { setBusy(false); }
  }

  async function signup() {
    setError(null); setBusy(true);
    try {
      const r = await post<{ sent?: boolean; created?: boolean }>("/api/member/signup", {
        email, hashName, firstName, lastName, slug,
      });
      if (r.error) setError(r.error);
      else setStep({ kind: "code", email, created: !!r.created });
    } finally { setBusy(false); }
  }

  async function verifyCode() {
    setError(null); setBusy(true);
    try {
      const r = await post<{ ok?: boolean; hashName?: string }>("/api/member/verify-code", { code, remember });
      if (r.ok) { stopPolling(); setStep({ kind: "passkey-offer", hashName: r.hashName ?? "" }); }
      else setError(r.error ?? "That code wasn't recognised.");
    } finally { setBusy(false); }
  }

  const passkeys = typeof window !== "undefined" && browserSupportsWebAuthn();

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="rounded-2xl bg-white p-5 text-zinc-900 shadow-xl sm:p-6" style={{ maxWidth: 420 }}>
      <div className="mb-4">
        <h3 className="text-lg font-bold">Sign in to {kennelName}</h3>
        {reason && <p className="mt-1 text-sm text-zinc-600">{reason}</p>}
      </div>

      {error && <p className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>}

      {step.kind === "choose" && (
        <div className="space-y-4">
          <p className="text-sm text-zinc-700">
            Have the Harrier Central app? Point your phone&apos;s camera at this code.
          </p>
          <div className="flex justify-center rounded-xl border border-zinc-200 p-3">
            {qr ? <QRCode value={qr.url} size={196} /> : <div className="h-[196px] w-[196px] animate-pulse rounded bg-zinc-100" />}
          </div>
          <p className="text-center text-xs text-zinc-500">Waiting for your phone…</p>
          <div className="flex flex-col items-center gap-3 pt-1">
            <button type="button" className={linkBtn} onClick={() => { stopPolling(); setStep({ kind: "email" }); }}>
              No phone handy? Send a code to my email instead
            </button>
            {passkeys && (
              <button type="button" className={linkBtn} onClick={signInWithPasskey} disabled={busy}>
                Sign in with a passkey
              </button>
            )}
          </div>
        </div>
      )}

      {step.kind === "email" && (
        <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); if (!busy) requestCode(); }}>
          <p className="text-sm text-zinc-700">
            We&apos;ll email you a six-letter code. Use the address your kennel has for you.
          </p>
          <input
            className={inputClass} type="email" inputMode="email" autoComplete="email webauthn" placeholder="you@example.com"
            value={email} onChange={(e) => setEmail(e.target.value)} required autoFocus
          />
          <button type="submit" className={primaryBtn} disabled={busy || !email}
            style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
            {busy ? "Sending…" : "Email me a code"}
          </button>
          <div className="flex flex-col items-center gap-2 pt-1">
            {passkeys && (
              <button type="button" className={linkBtn} onClick={signInWithPasskey} disabled={busy}>
                Sign in with a passkey
              </button>
            )}
            {!phone && (
              <button type="button" className={linkBtn} onClick={() => setStep({ kind: "choose" })}>
                Scan with the app instead
              </button>
            )}
          </div>
        </form>
      )}

      {step.kind === "signup" && (
        <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); if (!busy) signup(); }}>
          <p className="text-sm text-zinc-700">
            We don&apos;t have <strong>{step.email}</strong> yet. Tell us who you are and we&apos;ll
            set you up with {kennelName}.
          </p>
          <input className={inputClass} placeholder="Hash name (or the name you go by)" value={hashName}
            onChange={(e) => setHashName(e.target.value)} required autoFocus />
          <div className="grid grid-cols-2 gap-2">
            <input className={inputClass} placeholder="First name (optional)" value={firstName} onChange={(e) => setFirstName(e.target.value)} />
            <input className={inputClass} placeholder="Last name (optional)" value={lastName} onChange={(e) => setLastName(e.target.value)} />
          </div>
          <button type="submit" className={primaryBtn} disabled={busy || hashName.trim().length < 2}
            style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
            {busy ? "Creating…" : "Create my account & email me a code"}
          </button>
          <div className="text-center">
            <button type="button" className={linkBtn} onClick={() => setStep({ kind: "email" })}>Use a different email</button>
          </div>
        </form>
      )}

      {step.kind === "code" && (
        <form className="space-y-3" onSubmit={(e) => { e.preventDefault(); if (!busy) verifyCode(); }}>
          <p className="text-sm text-zinc-700">
            {step.created ? "Welcome! " : ""}We&apos;ve emailed a six-letter code to <strong>{step.email}</strong>.
            It can take a minute — check spam if it doesn&apos;t arrive.
          </p>
          <input
            className={`${inputClass} text-center text-2xl tracking-[0.4em] uppercase`} placeholder="ABCDEF"
            value={code} onChange={(e) => setCode(e.target.value.replace(/[^a-z]/gi, "").toUpperCase().slice(0, 6))}
            autoComplete="one-time-code" inputMode="text" autoFocus required
          />
          <label className="flex items-center gap-2 text-sm text-zinc-700">
            <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} />
            Keep me signed in on this device
          </label>
          <button type="submit" className={primaryBtn} disabled={busy || code.length !== 6}
            style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
            {busy ? "Checking…" : "Sign in"}
          </button>
          <div className="flex justify-center gap-4">
            <button type="button" className={linkBtn} onClick={requestCode} disabled={busy}>Send it again</button>
            <button type="button" className={linkBtn} onClick={() => setStep({ kind: "email" })}>Different email</button>
          </div>
        </form>
      )}

      {step.kind === "passkey-offer" && (
        <div className="space-y-3">
          <p className="text-sm text-zinc-700">
            You&apos;re in{step.hashName ? `, ${step.hashName}` : ""}.
          </p>
          {passkeys ? (
            <>
              <p className="text-sm text-zinc-700">
                Add a passkey so next time is one tap — on this device and any device it syncs to.
              </p>
              <button type="button" className={primaryBtn} disabled={busy} onClick={() => addPasskey(step.hashName)}
                style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
                {busy ? "Setting up…" : "Add a passkey"}
              </button>
              <div className="text-center">
                <button type="button" className={linkBtn} onClick={() => { setStep({ kind: "done", hashName: step.hashName }); onSignedIn(step.hashName); }}>
                  Not now
                </button>
              </div>
            </>
          ) : (
            <button type="button" className={primaryBtn} onClick={() => { setStep({ kind: "done", hashName: step.hashName }); onSignedIn(step.hashName); }}
              style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
              Continue
            </button>
          )}
        </div>
      )}

      {step.kind === "done" && (
        <p className="text-sm text-zinc-700">Signed in{step.hashName ? ` as ${step.hashName}` : ""}.</p>
      )}

      {onCancel && step.kind !== "done" && (
        <div className="mt-4 text-center">
          <button type="button" className={linkBtn} onClick={() => { stopPolling(); onCancel(); }}>Cancel</button>
        </div>
      )}
    </div>
  );
}
