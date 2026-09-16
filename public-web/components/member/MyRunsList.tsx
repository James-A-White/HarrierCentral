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
import { bodyText } from "@/components/member/app-look";
import { relativeTime } from "@/lib/member-format";
import { APP_BAR, HC_BLUE, appDate, card, cardDivider, mutedText, titleText } from "@/components/member/app-look";

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
      <div className={`${card} p-6 text-center`}>
        <h1 className={titleText}>No runs yet</h1>
        <p className={`mt-2 ${mutedText}`}>
          Follow a kennel and its runs land here.{" "}
          <Link href="/me/kennels" className="underline underline-offset-2" style={{ color: HC_BLUE }}>Find your kennel</Link>
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {error && <p className="rounded-lg bg-white px-3 py-2 text-sm font-semibold" style={{ color: "#B71C1C" }}>{error}</p>}

      {past.length > 0 && (
        <section>
          <Banner>My recent runs</Banner>
          <ul className="space-y-2">
            {past.map((run) => <RunCard key={run.PublicEventId} run={run} />)}
          </ul>
        </section>
      )}

      <section>
        <Banner>Runs from Kennels I follow</Banner>
        {future.length === 0 && <p className="text-center text-yellow-300">[No upcoming runs for the kennels you follow]</p>}
        <ul className="space-y-2">
          {future.map((run) => (
            <RunCard key={run.PublicEventId} run={run}>
              <div className={`flex items-center justify-between px-3 pb-2 pt-2 ${cardDivider}`}>
                <div className="flex items-center gap-5">
                  <RsvpIcon icon="checkbox_yes" label="Going" active={run.MyRsvpState === RSVP_YES || run.MyAttendenceState >= AT_HASH} busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "yes")} />
                  <RsvpIcon icon="checkbox_maybe" label="Maybe" active={run.MyRsvpState === RSVP_MAYBE} busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "maybe")} />
                  <RsvpIcon icon="checkbox_no" label="Not going" active={run.MyRsvpState === RSVP_NO} busy={busyId === run.PublicEventId} onClick={() => rsvp(run, "no")} />
                </div>
                <span className={mutedText}>{run.GoingCount} going</span>
              </div>
            </RunCard>
          ))}
        </ul>
      </section>

      <p className="text-center text-xs text-white/70">
        Checking in at the start and PackTrack need the phone — they&apos;re in the Harrier Central app.
      </p>
    </div>
  );
}

/** The app's RSVP control: the checkbox icon, full colour when chosen, faded otherwise. */
function RsvpIcon({ icon, label, active, busy, onClick }: { icon: string; label: string; active: boolean; busy: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} disabled={busy} title={label} aria-label={label} aria-pressed={active}
      className="flex flex-col items-center gap-0.5 disabled:opacity-50">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={`/images/icons/${active ? icon : "checkbox_empty"}.png`} alt="" className="h-8 w-8" style={active ? undefined : { opacity: 0.55 }} />
      <span className="text-[11px] text-zinc-600">{label}</span>
    </button>
  );
}

/** The app's purple section banner. */
function Banner({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mb-2 rounded-md py-1.5 text-center text-[17px] font-bold text-white" style={{ backgroundColor: APP_BAR }}>
      {children}
    </h2>
  );
}

function stateIcon(run: MyRun): string {
  if (run.MyAttendenceState >= AT_HASH) return run.MyIsHare === 1 ? "checkbox_on_in_hare" : "checkbox_on_in";
  if (run.MyIsHare === 1) return "checkbox_hare";
  if (run.MyRsvpState === RSVP_YES) return "checkbox_yes";
  if (run.MyRsvpState === RSVP_MAYBE) return "checkbox_maybe";
  if (run.MyRsvpState === RSVP_NO) return "checkbox_no";
  return "checkbox_empty";
}

function RunCard({ run, children }: { run: MyRun; children?: React.ReactNode }) {
  const when = run.EventStartDatetimeGmt ?? run.EventStartDatetime;
  return (
    <li className={`${card} overflow-hidden`}>
      {/* Header: my state as the app's checkbox, then the title. */}
      <div className="flex items-center gap-2 px-2 pt-2 pb-1.5">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={`/images/icons/${stateIcon(run)}.png`} alt="" className="h-6 w-6 shrink-0" />
        <Link href={`/${run.KennelSlug}/${run.EventNumber}?back=/me/runs`} className={`${titleText} min-w-0 flex-1 truncate hover:underline`}>
          {run.EventName}
        </Link>
      </div>
      <div className={cardDivider} />
      {/* Body: kennel logo, then the app's lines in its order. */}
      <div className="flex items-start gap-3 px-2 py-2">
        <Logo run={run} />
        <div className="min-w-0 flex-1 leading-snug">
          <Link href={`/${run.KennelSlug}`} className="text-[15px] font-semibold hover:underline" style={{ color: HC_BLUE }}>{run.KennelName}</Link>
          <p className="text-[15px] font-bold text-zinc-900" suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ` : "Run / Event "}{relativeTime(when)}
          </p>
          <p className={bodyText} suppressHydrationWarning>{appDate(run.EventStartDatetime, run.EventStartDatetimeGmt, run.KennelIANATimezone)}</p>
          {run.Hares && <p className={bodyText}>Hares: {run.Hares}</p>}
          {run.LocationOneLineDesc
            ? <p className={`${bodyText} truncate`}>{run.LocationOneLineDesc}</p>
            : <p className={bodyText}>No location provided</p>}
          {run.MyAttendenceState >= AT_HASH && <p className={mutedText}>Checked in{run.MyIsHare === 1 ? " · haring" : ""}</p>}
        </div>
      </div>
      {run.EventImage?.startsWith("http") && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={run.EventImage} alt="" className="w-full object-cover" style={{ maxHeight: 240 }} />
      )}
      {children}
    </li>
  );
}
