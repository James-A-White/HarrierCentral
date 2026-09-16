"use client";

/**
 * The app's kennel screen (kennel_admin_main.dart) on the web: description,
 * info rows, next runs with my RSVP, mismanagement, and the buttons in the
 * app's order — Open website, Join the group, Leaderboards, Songs.
 * Run tools, kennel chat and the run art gallery stay in the app and are
 * named as such.
 */
import { useState } from "react";
import Link from "next/link";
import type { MyKennel, MyRun } from "@/lib/member-api";
import { relativeTime } from "@/lib/member-format";
import { APP_BAR, HC_BLUE, HC_RED, appDate, card, cardDivider, mutedText, titleText } from "@/components/member/app-look";
import { splitLinks } from "@/lib/link-text";

const RSVP_YES = 3, RSVP_MAYBE = 2, RSVP_NO = 1, AT_HASH = 20;
const PLATFORM: Record<number, string> = { 1: "WhatsApp", 2: "Telegram", 3: "Signal", 4: "Messenger", 5: "WeChat" };

interface Landing {
  PublicKennelId: string; KennelName: string; KennelShortName: string; KennelLogo: string | null;
  KennelDescription: string | null; CustomDomain: string | null;
}

export function MyKennelPage({ slug, landing, kennel, nextRuns }: { slug: string; landing: Landing; kennel: MyKennel | null; nextRuns: MyRun[] }) {
  const [following, setFollowing] = useState(!!kennel && (kennel.Following === 1 || kennel.IsHomeKennel === 1));
  const [runs, setRuns] = useState(nextRuns);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function toggleFollow() {
    setBusy("follow"); setError(null);
    try {
      const r = await fetch("/api/member/follow", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicKennelId: landing.PublicKennelId.toLowerCase(), following: !following }),
      });
      const j = (await r.json()) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't update."); return; }
      setFollowing(!following);
    } finally { setBusy(null); }
  }

  async function rsvp(run: MyRun, answer: "yes" | "maybe" | "no") {
    setBusy(run.PublicEventId); setError(null);
    try {
      const r = await fetch("/api/member/rsvp", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicEventId: run.PublicEventId.toLowerCase(), rsvp: answer }),
      });
      const j = (await r.json()) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't save your RSVP."); return; }
      const state = answer === "yes" ? RSVP_YES : answer === "maybe" ? RSVP_MAYBE : RSVP_NO;
      setRuns((rs) => rs.map((x) => x.PublicEventId === run.PublicEventId ? { ...x, MyRsvpState: state } : x));
    } finally { setBusy(null); }
  }

  const website = kennel?.KennelWebsiteUrl?.trim() || (landing.CustomDomain ? `https://${landing.CustomDomain}` : `/${slug}`);
  const mm = parseMismanagement(kennel?.KennelMismanagementTeam ?? null);
  const desc = (kennel?.KennelDescription ?? landing.KennelDescription ?? "").trim();
  const credit = kennel && kennel.AllowSelfPayment === 1 ? money(kennel.KennelCredit, kennel.CurrencySymbol, kennel.DigitsAfterDecimal) : null;

  return (
    <div className="space-y-4">
      {/* Header — the app's: logo, name, follow. */}
      <section className={`${card} p-3`}>
        <div className="flex items-center gap-3">
          {landing.KennelLogo?.startsWith("https://") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={landing.KennelLogo} alt="" className="h-16 w-16 shrink-0 object-contain" />
          ) : (
            <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-lg text-2xl font-bold text-white" style={{ backgroundColor: HC_RED }}>{landing.KennelShortName.charAt(0)}</div>
          )}
          <div className="min-w-0 flex-1">
            <h2 className={titleText}>{landing.KennelName}</h2>
            <p className={mutedText}>{landing.KennelShortName}{kennel?.IsHomeKennel === 1 ? " · your home kennel" : ""}{kennel?.IsMember === 1 ? " · member" : ""}</p>
          </div>
          {kennel?.IsHomeKennel !== 1 && (
            <button type="button" onClick={toggleFollow} disabled={busy === "follow"}
              className="shrink-0 rounded-full px-4 py-1.5 text-sm font-semibold disabled:opacity-50"
              style={following ? { backgroundColor: "#e4e4e7", color: "#27272a" } : { backgroundColor: HC_RED, color: "#fff" }}>
              {following ? "Following" : "Follow"}
            </button>
          )}
        </div>
      </section>

      {error && <p className="rounded-lg bg-white px-3 py-2 text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}

      {/* Description — plain text with links, as the app's Linkify. */}
      {desc && (
        <section className={`${card} p-3`}>
          <p className="whitespace-pre-line text-[15px] leading-relaxed text-zinc-800">
            {splitLinks(desc).map((run, i) => run.url
              ? <a key={i} href={run.url} target="_blank" rel="noopener noreferrer" className="underline" style={{ color: HC_BLUE }}>{run.text}</a>
              : <span key={i}>{run.text}</span>)}
          </p>
        </section>
      )}

      {/* Info rows — the app's order. */}
      <section className={`${card} p-3`}>
        <Row label="Location:" value={dedupe([kennel?.City, kennel?.Region, kennel?.Country]).join(", ") || "—"} />
        <Row label="Last run:" value={kennel?.DateOfLastRun ? appDate(kennel.DateOfLastRun).replace(/ at .*$/, "") : "—"} />
        <Row label="Next run:" value={runs[0] ? `${appDate(runs[0].EventStartDatetime, runs[0].EventStartDatetimeGmt, runs[0].KennelIANATimezone)} (${relativeTime(runs[0].EventStartDatetimeGmt ?? runs[0].EventStartDatetime)})` : "None scheduled"} hydrate />
        {credit !== null && <Row label="Hash cash:" value={credit} />}
        {kennel && (kennel.Runs > 0 || kennel.Haring > 0) && (
          <Row label="My runs:" value={`${kennel.IsEstimate ? "~" : ""}${kennel.Runs}, hared ${kennel.Haring}`} />
        )}
      </section>

      {/* Next runs with my RSVP — the app's "Next N runs". */}
      <section>
        <h2 className="mb-2 rounded-md py-1.5 text-center text-[17px] font-bold text-white" style={{ backgroundColor: APP_BAR }}>
          {runs.length === 0 ? "No upcoming runs" : runs.length === 1 ? "Next run" : `Next ${runs.length} runs`}
        </h2>
        <ul className="space-y-2">
          {runs.map((run) => (
            <li key={run.PublicEventId} className={`${card} overflow-hidden`}>
              <div className="flex items-center gap-2 px-2 pt-2 pb-1.5">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={`/images/icons/${stateIcon(run)}.png`} alt="" className="h-6 w-6 shrink-0" />
                <Link href={`/${run.KennelSlug}/${run.EventNumber}?back=/me/kennels/${slug}`} className={`${titleText} min-w-0 flex-1 truncate hover:underline`}>{run.EventName}</Link>
              </div>
              <div className={cardDivider} />
              <div className="px-3 py-2 leading-snug">
                <p className="text-[15px] font-bold text-zinc-900" suppressHydrationWarning>
                  {run.IsCountedRun ? `Run #${run.EventNumber}, ` : "Run / Event "}{relativeTime(run.EventStartDatetimeGmt ?? run.EventStartDatetime)}
                </p>
                <p className="text-[15px] text-zinc-800" suppressHydrationWarning>{appDate(run.EventStartDatetime, run.EventStartDatetimeGmt, run.KennelIANATimezone)}</p>
                {run.Hares && <p className="text-[15px] text-zinc-800">Hares: {run.Hares}</p>}
                <p className="text-[15px] text-zinc-800">{run.LocationOneLineDesc || "No location provided"}</p>
              </div>
              {following && (
                <div className={`flex items-center gap-5 px-3 pb-2 pt-2 ${cardDivider}`}>
                  <RsvpIcon icon="checkbox_yes" label="Going" active={run.MyRsvpState === RSVP_YES || run.MyAttendenceState >= AT_HASH} busy={busy === run.PublicEventId} onClick={() => rsvp(run, "yes")} />
                  <RsvpIcon icon="checkbox_maybe" label="Maybe" active={run.MyRsvpState === RSVP_MAYBE} busy={busy === run.PublicEventId} onClick={() => rsvp(run, "maybe")} />
                  <RsvpIcon icon="checkbox_no" label="Not going" active={run.MyRsvpState === RSVP_NO} busy={busy === run.PublicEventId} onClick={() => rsvp(run, "no")} />
                </div>
              )}
            </li>
          ))}
        </ul>
      </section>

      {/* Mismanagement — role and name per line, as the app. */}
      {mm.length > 0 && (
        <section className={`${card} p-3`}>
          <h3 className="mb-1 text-[15px] font-bold text-zinc-900">Mismanagement</h3>
          {mm.map((m, i) => <Row key={i} label={m.role} value={m.name} />)}
        </section>
      )}

      {/* Buttons — the app's, in its order. */}
      <section className="flex flex-col items-center gap-2">
        <a href={website} target={website.startsWith("/") ? undefined : "_blank"} rel="noopener noreferrer" className="w-full max-w-sm rounded-full py-2.5 text-center text-base font-semibold text-white" style={{ backgroundColor: HC_RED }}>Open website</a>
        {kennel?.MessagingGroupInviteUrl?.toLowerCase().startsWith("http") && (
          <a href={kennel.MessagingGroupInviteUrl} target="_blank" rel="noopener noreferrer" className="w-full max-w-sm rounded-full py-2.5 text-center text-base font-semibold text-white" style={{ backgroundColor: HC_RED }}>
            Join the {landing.KennelShortName} {PLATFORM[kennel.DefaultMessagingPlatform] ?? "WhatsApp"} group
          </a>
        )}
        <Link href={`/${slug}/stats`} className="w-full max-w-sm rounded-full py-2.5 text-center text-base font-semibold text-white" style={{ backgroundColor: HC_RED }}>Leaderboards</Link>
        <Link href={`/${slug}/songs`} className="w-full max-w-sm rounded-full py-2.5 text-center text-base font-semibold text-white" style={{ backgroundColor: HC_RED }}>Songs</Link>
        <p className="mt-2 text-center text-xs text-white/70">Kennel chat and the run art gallery are in the Harrier Central app.</p>
      </section>
    </div>
  );
}

function Row({ label, value, hydrate }: { label: string; value: string; hydrate?: boolean }) {
  return (
    <div className="flex gap-2 py-0.5 text-[15px]" suppressHydrationWarning={hydrate}>
      <span className="w-24 shrink-0 text-right font-semibold text-zinc-500">{label}</span>
      <span className="min-w-0 flex-1 text-zinc-900">{value}</span>
    </div>
  );
}

function RsvpIcon({ icon, label, active, busy, onClick }: { icon: string; label: string; active: boolean; busy: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} disabled={busy} title={label} aria-label={label} aria-pressed={active} className="flex flex-col items-center gap-0.5 disabled:opacity-50">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={`/images/icons/${active ? icon : "checkbox_empty"}.png`} alt="" className="h-8 w-8" style={active ? undefined : { opacity: 0.55 }} />
      <span className="text-[11px] text-zinc-600">{label}</span>
    </button>
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

/** "London, London, United Kingdom" → "London, United Kingdom". */
function dedupe(parts: (string | null | undefined)[]): string[] {
  const out: string[] = [];
  for (const p of parts) { if (p && out[out.length - 1]?.toLowerCase() !== p.toLowerCase()) out.push(p); }
  return out;
}

/** "GM\tOpee\rVice GM\tOpee…" → rows. "none listed" → nothing, as the app. */
function parseMismanagement(raw: string | null): { role: string; name: string }[] {
  if (!raw || raw.toLowerCase().includes("none listed")) return [];
  // Rows are separated by CR alone in the data (tab between role and name).
  return raw.split(/\r\n|\r|\n/).map((l) => l.trim()).filter(Boolean).map((l) => {
    const [role, ...rest] = l.split(/\t|: /);
    return { role: (role ?? "").trim(), name: rest.join(" ").trim() };
  }).filter((m) => m.role && m.name);
}

/** The app's money format: symbol template with ^ where the amount goes. */
function money(v: number, symbol: string | null, digits: number): string {
  const amount = (Number(v) || 0).toFixed(Math.max(0, Math.min(4, digits)));
  const t = symbol && symbol.includes("^") ? symbol : `${symbol ?? ""}^`;
  return t.replace("^", amount);
}
