"use client";

/**
 * The app's Runs tab on the web (E9.F7.S8): the next year of runs for the
 * kennels I follow, my attended runs from the last ten days above them,
 * each card with my RSVP inline. Check-in at the start and PackTrack are
 * the phone's; the card says so rather than pretending.
 */
import { useState } from "react";
import Link from "next/link";
import type { MyRun } from "@/lib/member-api";
import { formatRunDate, relativeTime } from "@/lib/member-format";

const RSVP_YES = 3, RSVP_MAYBE = 2, RSVP_NO = 1, AT_HASH = 20;
type Answer = "yes" | "no" | "maybe";

function Logo({ run }: { run: MyRun }) {
  if (run.KennelLogo?.startsWith("https://")) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={run.KennelLogo} alt={run.KennelName} className="h-12 w-12 shrink-0 object-contain" />;
  }
  return (
    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg text-lg font-bold text-white" style={{ backgroundColor: run.PrimaryColor ?? "#dc2626" }}>
      {run.KennelName.charAt(0).toUpperCase()}
    </div>
  );
}

export function MyRunsList({ initialRuns }: { initialRuns: MyRun[] }) {
  const [runs, setRuns] = useState<MyRun[]>(initialRuns);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function rsvp(run: MyRun, answer: Answer) {
    setBusyId(run.PublicEventId); setError(null);
    try {
      const r = await fetch("/api/member/rsvp", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicEventId: run.PublicEventId.toLowerCase(), rsvp: answer }),
      });
      const j = (await r.json()) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't save your RSVP."); return; }
      const state = answer === "yes" ? RSVP_YES : answer === "maybe" ? RSVP_MAYBE : RSVP_NO;
      setRuns((rs) => rs.map((x) => x.PublicEventId === run.PublicEventId
        ? { ...x, MyRsvpState: state, GoingCount: x.GoingCount + (state === RSVP_YES && x.MyRsvpState !== RSVP_YES ? 1 : 0) - (state !== RSVP_YES && x.MyRsvpState === RSVP_YES ? 1 : 0) }
        : x));
    } finally { setBusyId(null); }
  }

  const past = runs.filter((r) => r.IsPast === 1);
  const future = runs.filter((r) => r.IsPast !== 1);

  if (runs.length === 0) {
    return (
      <div className="rounded-2xl bg-black/30 p-6 text-center">
        <h1 className="text-xl font-bold">No runs yet</h1>
        <p className="mt-2 text-zinc-300">
          Follow a kennel and its runs land here.{" "}
          <Link href="/me/kennels" className="underline underline-offset-2">Find your kennel</Link>
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {error && <p className="rounded-lg bg-red-500/20 px-3 py-2 text-sm text-red-200">{error}</p>}

      {past.length > 0 && (
        <section>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">Just ran</h2>
          <ul className="space-y-2">
            {past.map((run) => <RunCard key={run.PublicEventId} run={run} />)}
          </ul>
        </section>
      )}

      <section>
        <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">Coming up</h2>
        {future.length === 0 && <p className="text-zinc-300">Nothing on the books for the kennels you follow.</p>}
        <ul className="space-y-2">
          {future.map((run) => (
            <RunCard key={run.PublicEventId} run={run}>
              <div className="mt-3 flex flex-wrap items-center gap-2">
                <RsvpButton label="✅ I'll be there" active={run.MyRsvpState === RSVP_YES || run.MyAttendenceState >= AT_HASH} activeColor="#16a34a" busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "yes")} primary />
                <RsvpButton label="🤔 Maybe" active={run.MyRsvpState === RSVP_MAYBE} activeColor="#ca8a04" busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "maybe")} />
                <RsvpButton label="❌ Can't" active={run.MyRsvpState === RSVP_NO} activeColor="#dc2626" busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "no")} />
                <span className="ml-auto text-xs text-zinc-400">{run.GoingCount} going</span>
              </div>
            </RunCard>
          ))}
        </ul>
      </section>

      <p className="text-center text-xs text-zinc-500">
        Checking in at the start and PackTrack need the phone — they&apos;re in the Harrier Central app.
      </p>
    </div>
  );
}

function RsvpButton({ label, active, activeColor, busy, onClick, primary }: { label: string; active: boolean; activeColor: string; busy: boolean; onClick: () => void; primary?: boolean }) {
  return (
    <button
      type="button" onClick={onClick} disabled={busy}
      className="rounded-full px-4 py-1.5 text-sm font-semibold transition-opacity hover:opacity-85 disabled:opacity-50"
      style={active ? { backgroundColor: activeColor, color: "#fff" } : primary ? { backgroundColor: "#dc2626", color: "#fff" } : { backgroundColor: "rgba(255,255,255,0.12)", color: "#fff" }}
    >
      {label}
    </button>
  );
}

function RunCard({ run, children }: { run: MyRun; children?: React.ReactNode }) {
  const d = formatRunDate(run);
  const when = run.EventStartDatetimeGmt ?? run.EventStartDatetime;
  return (
    <li className="rounded-2xl bg-black/30 p-4">
      <div className="flex items-start gap-3">
        <Logo run={run} />
        <div className="min-w-0 flex-1">
          <Link href={`/${run.KennelSlug}/${run.EventNumber}?back=/me/runs`} className="block">
            <p className="truncate text-base font-bold leading-snug hover:underline">{run.EventName}</p>
          </Link>
          <p className="text-sm text-zinc-300">
            {run.KennelShortName} · Run #{run.EventNumber}
            {run.MyIsHare === 1 && <span title="You're haring"> 🐰</span>}
            {run.MyAttendenceState >= AT_HASH && <span title="Checked in"> 📍</span>}
          </p>
          <p className="mt-1 text-sm text-zinc-400">
            {d.short} · {d.time} <span className="text-zinc-500">· {relativeTime(when)}</span>
          </p>
          {run.Hares && <p className="text-sm text-zinc-400">🐰 {run.Hares}</p>}
          {run.LocationOneLineDesc && <p className="truncate text-sm text-zinc-400">📍 {run.LocationOneLineDesc}</p>}
          {children}
        </div>
      </div>
    </li>
  );
}
