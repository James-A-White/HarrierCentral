"use client";

/**
 * RSVP on the run page for people without the app (E9.F7.S1/S4).
 *
 * Reads `?RSVP=Yes|No` from the WhatsApp notice. Signed in → the answer is
 * recorded at once and the panel shows the tick and who else is coming.
 * Signed out → "I'll be there / Can't make it" open the sign-in; the pending
 * answer is completed the moment the cookie lands. The whole thing is one
 * client island on an otherwise server-rendered page.
 */
import { useCallback, useEffect, useState } from "react";
import { MemberSignIn } from "@/components/member/MemberSignIn";

interface PackMember { hasherId: string; name: string; photo: string; rsvpState: number; attendenceState: number; isHare: number }
interface RunPack {
  me: { hasherId: string; hashName: string; rsvpState: number; attendenceState: number; isHare: number; isPast: number };
  pack: PackMember[];
}

export interface RsvpPanelProps {
  slug: string;
  kennelName: string;
  publicEventId: string;
  /** From the URL: 'yes' | 'no' | null. */
  rsvpFromUrl: "yes" | "no" | null;
  /** The run's UTC instant; "past" is decided on the client so the server render stays pure. */
  eventStartGmt: string | null;
}

type Answer = "yes" | "no" | "maybe";
const RSVP_YES = 3, RSVP_MAYBE = 2, RSVP_NO = 1, AT_HASH = 20;

const btn = "inline-flex items-center justify-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold transition-opacity hover:opacity-85 disabled:opacity-50";

export function RsvpPanel({ slug, kennelName, publicEventId, rsvpFromUrl, eventStartGmt }: RsvpPanelProps) {
  const [isPast, setIsPast] = useState(false);
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [hashName, setHashName] = useState("");
  const [pack, setPack] = useState<RunPack | null>(null);
  const [pending, setPending] = useState<Answer | null>(rsvpFromUrl);
  const [showSignIn, setShowSignIn] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadPack = useCallback(async () => {
    const r = await fetch(`/api/member/pack?publicEventId=${publicEventId}`, { cache: "no-store" });
    if (!r.ok) return;
    const j = (await r.json()) as { pack: RunPack | null };
    setPack(j.pack);
  }, [publicEventId]);

  const send = useCallback(async (answer: Answer) => {
    setBusy(true); setError(null);
    try {
      const r = await fetch("/api/member/rsvp", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicEventId, rsvp: answer }),
      });
      const j = (await r.json()) as { ok?: boolean; message?: string; error?: string; pack?: RunPack | null };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't save your RSVP."); return; }
      if (j.pack) setPack(j.pack);
      setNotice(j.message ?? (answer === "yes" ? "You're in — see you at the start." : answer === "no" ? "Noted — marked as not coming." : "Noted — maybe."));
    } finally { setBusy(false); }
  }, [publicEventId]);

  // Who am I? Then, if the link carried an answer, give it.
  useEffect(() => {
    let cancelled = false;
    const past = !!eventStartGmt && new Date(eventStartGmt).getTime() < Date.now();
    setIsPast(past);
    (async () => {
      const r = await fetch("/api/member/me", { cache: "no-store" });
      const j = (await r.json()) as { signedIn: boolean; hashName?: string };
      if (cancelled) return;
      setSignedIn(j.signedIn);
      setHashName(j.hashName ?? "");
      if (j.signedIn) {
        if (pending && !past) { const a = pending; setPending(null); await send(a); }
        else await loadPack();
      } else if (pending && !past) {
        setShowSignIn(true);
      }
    })();
    return () => { cancelled = true; };
    // run once on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function onSignedIn(name: string) {
    setSignedIn(true); setHashName(name); setShowSignIn(false);
    if (pending && !isPast) { const a = pending; setPending(null); await send(a); }
    else await loadPack();
  }

  function answer(a: Answer) {
    if (signedIn) { void send(a); return; }
    setPending(a); setShowSignIn(true);
  }

  const my = pack?.me;
  const myState = my?.attendenceState !== undefined && my.attendenceState >= AT_HASH ? "here"
    : my?.rsvpState === RSVP_YES ? "yes" : my?.rsvpState === RSVP_MAYBE ? "maybe" : my?.rsvpState === RSVP_NO ? "no" : null;

  return (
    <section className="mb-6 rounded-2xl p-4 sm:p-5" style={{ backgroundColor: "var(--kennel-card-bg, rgba(0,0,0,0.25))" }}>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h3 className="text-base font-bold" style={{ color: "var(--kennel-text-title)" }}>
          {isPast ? "Who came" : "Are you coming?"}
        </h3>
        {signedIn && (
          <span className="text-xs" style={{ color: "var(--kennel-text-muted)" }}>
            Signed in{hashName ? ` as ${hashName}` : ""}
          </span>
        )}
      </div>

      {!isPast && (
        <div className="mt-3 flex flex-wrap gap-2">
          <button type="button" className={btn} disabled={busy} onClick={() => answer("yes")}
            style={myState === "yes" || myState === "here"
              ? { backgroundColor: "#16a34a", color: "#fff" }
              : { backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
            ✅ I&apos;ll be there
          </button>
          <button type="button" className={btn} disabled={busy} onClick={() => answer("maybe")}
            style={myState === "maybe"
              ? { backgroundColor: "#ca8a04", color: "#fff" }
              : { backgroundColor: "var(--kennel-btn-secondary, rgba(255,255,255,0.12))", color: "var(--kennel-text-body)" }}>
            🤔 Maybe
          </button>
          <button type="button" className={btn} disabled={busy} onClick={() => answer("no")}
            style={myState === "no"
              ? { backgroundColor: "#dc2626", color: "#fff" }
              : { backgroundColor: "var(--kennel-btn-secondary, rgba(255,255,255,0.12))", color: "var(--kennel-text-body)" }}>
            ❌ Can&apos;t make it
          </button>
        </div>
      )}

      {notice && <p className="mt-3 text-sm" style={{ color: "var(--kennel-text-body)" }}>{notice}</p>}
      {error && <p className="mt-3 text-sm text-red-400">{error}</p>}

      {signedIn === false && !showSignIn && (
        <p className="mt-3 text-sm" style={{ color: "var(--kennel-text-muted)" }}>
          {isPast ? "Sign in to see who came." : "Answer and we'll ask who you are — email code or a scan with the app."}
          {" "}
          <button type="button" className="underline underline-offset-2" onClick={() => setShowSignIn(true)}>Sign in</button>
        </p>
      )}

      {pack && pack.pack.length > 0 && (
        <div className="mt-4">
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide" style={{ color: "var(--kennel-text-muted)" }}>
            {isPast ? "Came" : "Coming"} · {pack.pack.filter((p) => p.rsvpState === RSVP_YES || p.attendenceState >= AT_HASH || p.isHare === 1).length}
            {pack.pack.some((p) => p.rsvpState === RSVP_MAYBE && p.attendenceState < AT_HASH && p.isHare !== 1) &&
              ` · maybe ${pack.pack.filter((p) => p.rsvpState === RSVP_MAYBE && p.attendenceState < AT_HASH && p.isHare !== 1).length}`}
          </p>
          <ul className="flex flex-wrap gap-2">
            {pack.pack.map((p) => (
              <li key={p.hasherId} className="flex items-center gap-2 rounded-full py-1 pl-1 pr-3 text-sm"
                style={{ backgroundColor: "rgba(255,255,255,0.08)", color: "var(--kennel-text-body)" }}
                title={p.isHare ? "Hare" : p.attendenceState >= AT_HASH ? "Checked in" : p.rsvpState === RSVP_MAYBE ? "Maybe" : "Coming"}>
                {p.photo?.startsWith("http") ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={p.photo} alt="" className="h-7 w-7 rounded-full object-cover" />
                ) : (
                  <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white/20 text-xs font-bold">
                    {(p.name || "?").slice(0, 1).toUpperCase()}
                  </span>
                )}
                <span>{p.name}</span>
                {p.isHare === 1 && <span aria-label="hare">🐰</span>}
                {p.attendenceState >= AT_HASH && <span aria-label="checked in">📍</span>}
                {p.isHare !== 1 && p.attendenceState < AT_HASH && p.rsvpState === RSVP_MAYBE && <span className="opacity-60">?</span>}
              </li>
            ))}
          </ul>
        </div>
      )}
      {pack && pack.pack.length === 0 && (
        <p className="mt-3 text-sm" style={{ color: "var(--kennel-text-muted)" }}>Nobody has answered yet — be the first.</p>
      )}

      {showSignIn && (
        <div className="fixed inset-0 z-[100] flex items-end justify-center bg-black/60 p-3 sm:items-center" onClick={() => setShowSignIn(false)}>
          <div onClick={(e) => e.stopPropagation()} className="w-full sm:w-auto">
            <MemberSignIn
              slug={slug}
              kennelName={kennelName}
              reason={pending === "yes" ? "So we can put your name down as coming." : pending === "no" ? "So we can mark you as not coming." : "To answer for this run."}
              onSignedIn={onSignedIn}
              onCancel={() => { setShowSignIn(false); setPending(null); }}
            />
          </div>
        </div>
      )}
    </section>
  );
}
