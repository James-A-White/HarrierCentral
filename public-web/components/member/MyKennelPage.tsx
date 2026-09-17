"use client";

/**
 * The app's kennel screen (kennel_admin_main.dart) on the web, in the
 * app's order, on the jungle: the sub-page bar with the kennel's short
 * name; the logo and cover photo; the description with its links; the
 * map on the kennel's city; the yellow-labelled rows — Location, Last run,
 * Next run, Hash cash (members / non-members); the mismanagement; "Next N
 * runs" with the same cards as the Runs tab (RSVP, bell, envelope); "Show
 * <kennel> Links" opening the three QR groups; then the buttons — Join the
 * group, Open website, Run art gallery, Leaderboards. The admin functions
 * and "Share my photos" stay in the app.
 */
import { useState } from "react";
import Link from "next/link";
import { UserPlus, QrCode } from "lucide-react";
import type { MyKennel, MyRun } from "@/lib/member-api";
import { HC_BLUE, HC_RED, money } from "@/components/member/app-look";
import { splitLinks } from "@/lib/link-text";
import { RunCard, rsvpChoices, type Answer, type PrefKind } from "@/components/member/HashRunsView";
import { ChoicePopup, runBellChoices, runEnvelopeChoices } from "@/components/member/ChoicePopup";
import { KennelMap } from "@/components/member/KennelMap";
import { QrGroup } from "@/components/member/QrGroup";

const RSVP = { no: 1, maybe: 2, yes: 3 } as const;
const PLATFORM: Record<number, string> = { 1: "WhatsApp", 2: "Telegram", 3: "Signal", 4: "Messenger", 5: "WeChat" };
const BASE_URL = "https://www.hashruns.org/";

export function MyKennelPage({ kennel, nextRuns, back }: { kennel: MyKennel; nextRuns: MyRun[]; back: string }) {
  const [runs, setRuns] = useState(nextRuns);
  const [menuFor, setMenuFor] = useState<string | null>(null);
  const [pref, setPref] = useState<{ kind: PrefKind; run: MyRun } | null>(null);
  const [rsvpFor, setRsvpFor] = useState<MyRun | null>(null);
  const [showLinks, setShowLinks] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const here = `/me/kennels/${kennel.KennelSlug}`;
  const short = kennel.KennelShortName;

  async function rsvp(run: MyRun, answer: Answer) {
    setMenuFor(null); setRsvpFor(null); setBusy(run.PublicEventId); setError(null);
    try {
      const r = await fetch("/api/member/rsvp", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicEventId: run.PublicEventId.toLowerCase(), rsvp: answer }),
      });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't save your RSVP."); return; }
      setRuns((rs) => rs.map((x) => x.PublicEventId === run.PublicEventId ? { ...x, MyRsvpState: RSVP[answer] } : x));
    } finally { setBusy(null); }
  }

  async function notify(run: MyRun, kind: PrefKind, value: number) {
    setPref(null); setBusy(run.PublicEventId); setError(null);
    try {
      const r = await fetch("/api/member/notify", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicEventId: run.PublicEventId.toLowerCase(), [kind === "bell" ? "notification" : "email"]: value }),
      });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't update."); return; }
      setRuns((rs) => rs.map((x) => x.PublicEventId === run.PublicEventId ? (kind === "bell" ? { ...x, MyNotificationPref: value } : { ...x, MyEmailAlertPref: value }) : x));
    } finally { setBusy(null); }
  }

  const desc = (kennel.KennelDescription ?? "").trim();
  const mm = parseMismanagement(kennel.KennelMismanagementTeam);
  const website = (kennel.KennelWebsiteUrl ?? "").trim();
  const hasWebsite = website.toLowerCase().startsWith("http");
  const invite = (kennel.MessagingGroupInviteUrl ?? "").trim();
  const hasInvite = invite.toLowerCase().startsWith("http");
  const priceMembers = Number(kennel.DefaultPriceMembers) || 0;
  const priceNonMembers = Number(kennel.DefaultPriceNonMembers) || 0;
  const hasMap = kennel.CityLat != null && kennel.CityLon != null;

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      {/* The app's sub-page bar: back + kennel short name */}
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href={back} aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">{short}</h2>
        <span className="w-4" />
      </div>

      {error && <p className="mx-3 mt-3 rounded-lg bg-white px-3 py-2 text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}

      {/* Logo and cover photo */}
      <div className="flex flex-col items-center gap-3 px-3 pt-4">
        {kennel.KennelLogo?.startsWith("https://") ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={kennel.KennelLogo} alt={kennel.KennelName} className="h-[120px] w-[120px] object-contain" />
        ) : (
          <div className="flex h-[120px] w-[120px] items-center justify-center rounded-full text-5xl font-bold text-white" style={{ backgroundColor: HC_RED }}>{kennel.KennelName.charAt(0)}</div>
        )}
        <h1 className="text-center text-[24px] font-semibold text-white">{kennel.KennelName}</h1>
        {kennel.KennelCoverPhoto?.startsWith("https://") && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={kennel.KennelCoverPhoto} alt="" className="w-full rounded-md object-cover" style={{ maxHeight: 320 }} />
        )}
      </div>

      {desc && (
        <>
          <FancyDivider />
          <p className="whitespace-pre-line px-4 text-[20px] leading-snug text-white">
            {splitLinks(desc).map((run, i) => run.url
              ? <a key={i} href={run.url} target="_blank" rel="noopener noreferrer" className="underline underline-offset-2" style={{ color: "#facc15" }}>{run.text}</a>
              : <span key={i}>{run.text}</span>)}
          </p>
        </>
      )}

      <FancyDivider />
      {hasMap && <KennelMap lat={Number(kennel.CityLat)} lon={Number(kennel.CityLon)} name={kennel.KennelName} />}

      {/* The info rows: yellow label right-aligned, white value */}
      <div className="mt-3 px-3">
        <Row label="Location:" value={kennel.Location} />
        <Row label="Last run:" value={kennel.LastRunLocal ? appDateTime(kennel.LastRunLocal) : "<no run found>"} hydrate />
        <Row label="Next run:" value={kennel.NextRunLocal ? appDateTime(kennel.NextRunLocal) : "<no run found>"} hydrate />
        <Row label="Hash cash:" value={priceMembers > 0 ? `${money(priceMembers, kennel.CurrencySymbol, kennel.DigitsAfterDecimal)}    (members)` : ""} />
        {priceNonMembers > 0 && <Row label="" value={`${money(priceNonMembers, kennel.CurrencySymbol, kennel.DigitsAfterDecimal)}    (non-members)`} />}
      </div>

      {mm.length > 0 && (
        <>
          <FancyDivider />
          <div className="px-3">
            {mm.map((m, i) => <Row key={i} label={`${m.role}:`} value={m.name} />)}
          </div>
        </>
      )}

      {runs.length > 0 && (
        <>
          <FancyDivider />
          <h3 className="px-3 text-center text-[24px] font-semibold text-white">{runs.length === 1 ? "Next run" : `Next ${runs.length} runs`}</h3>
          <ul className="space-y-2.5 px-2 pt-2">
            {runs.map((r) => (
              <RunCard key={r.PublicEventId} run={r} distance={null} back={here}
                menuOpen={menuFor === r.PublicEventId} onMenu={() => setMenuFor(menuFor === r.PublicEventId ? null : r.PublicEventId)}
                onRsvp={rsvp} onPref={(run, kind) => setPref({ kind, run })} onState={setRsvpFor} busy={busy === r.PublicEventId} />
            ))}
          </ul>
        </>
      )}

      {/* Show <kennel> Links → the QR groups */}
      <FancyDivider />
      <div className="flex flex-col items-center px-3">
        <button type="button" onClick={() => setShowLinks((v) => !v)}
          className="flex h-14 w-[300px] max-w-full items-center rounded-md text-white shadow" style={{ backgroundColor: HC_BLUE }}>
          <span className="flex w-[45px] shrink-0 items-center justify-center"><QrCode className="h-7 w-7" /></span>
          <span className="flex-1 pr-3 text-center text-[20px] font-semibold">{showLinks ? "Hide Links" : `Show ${short} Links`}</span>
        </button>
        {showLinks && (
          <div className="w-full">
            <QrGroup title={`Next ${short} Run`} description={`next ${short} run`} url={`${BASE_URL}${kennel.KennelSlug}/nextrun`}
              helpTitle="URL for Next Hash"
              helpText={`Want to know what's next for ${short}?\n\nThis link always points to the next ${short} Hash run — perfect for bookmarking or sharing with friends!`} />
            <QrGroup title={`${short} upcoming Runs`} description={`${kennel.KennelName} upcoming runs`} url={`${BASE_URL}${kennel.KennelSlug}`}
              helpTitle={`URL for upcoming ${short} runs`}
              helpText={`This link opens a page with all upcoming ${short} runs.\n\nNavigate to this page and scroll down to see everything that's planned!`} />
            {hasWebsite && (
              <QrGroup title={`${short} Website`} description={`${short} Website`} url={website}
                helpTitle={`${short} Website`} helpText={`The ${short} website: ${website}`} />
            )}
            <div className="h-10" />
          </div>
        )}
      </div>

      {/* The buttons, in the app's order */}
      <div className="mt-6 flex flex-col items-center gap-4 px-3">
        {hasInvite && (
          <BigButton href={invite} external>
            <span className="flex w-[45px] shrink-0 items-center justify-center"><UserPlus className="h-7 w-7" /></span>
            <span className="flex-1 pr-3 text-left">Join the {short} {PLATFORM[kennel.DefaultMessagingPlatform] ?? "chat"} group</span>
          </BigButton>
        )}
        {hasWebsite && (
          <BigButton href={website} external>
            <span className="flex w-[45px] shrink-0 items-center justify-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/images/icons/visit_run_on_web.png" alt="" className="h-[30px] w-[30px]" />
            </span>
            <span className="flex-1 pr-3 text-left">Open website</span>
          </BigButton>
        )}
        <BigButton href={`${here}/gallery`}>
          <span className="flex w-[45px] shrink-0 items-center justify-center">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/images/icons/painter_palette.png" alt="" className="h-[35px] w-[35px]" />
          </span>
          <span className="flex-1 pr-3 text-left">Run art gallery</span>
        </BigButton>
        <BigButton href={`${here}/leaderboard`}>
          <span className="flex w-[45px] shrink-0 items-center justify-center">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/images/icons/leaderboard_icon.png" alt="" className="h-[35px] w-[35px]" />
          </span>
          <span className="flex-1 pr-3 text-left">Leaderboards</span>
        </BigButton>
      </div>

      {pref && (
        <ChoicePopup title={pref.run.EventName} choices={pref.kind === "bell" ? runBellChoices : runEnvelopeChoices}
          onPick={(v) => notify(pref.run, pref.kind, v)} onClose={() => setPref(null)} busy={!!busy} />
      )}

      {rsvpFor && (
        <ChoicePopup title={rsvpFor.EventName} choices={rsvpChoices}
          onPick={(a) => rsvp(rsvpFor, a)} onClose={() => setRsvpFor(null)} busy={!!busy} />
      )}
    </div>
  );
}

/** ive_flutter_core's FancyDivider: a white rule with a notch in the middle. */
export function FancyDivider() {
  return (
    <div className="my-5 flex items-center px-6" aria-hidden="true">
      <span className="h-px flex-1 bg-white" />
      <span className="mx-2 h-2.5 w-2.5 rotate-45 border border-white" />
      <span className="h-px flex-1 bg-white" />
    </div>
  );
}

/** kennel_admin_main._infoRow: flex 3 label (yellow, right) · flex 7 value (white, demi). */
function Row({ label, value, hydrate }: { label: string; value: string; hydrate?: boolean }) {
  return (
    <div className="grid grid-cols-10 gap-x-3 py-0.5 text-[16px] leading-snug">
      <div className="col-span-3 text-right text-yellow-300">{label}</div>
      <div className="col-span-7 whitespace-pre font-semibold text-white" suppressHydrationWarning={hydrate}>{value}</div>
    </div>
  );
}

function BigButton({ href, external, children }: { href: string; external?: boolean; children: React.ReactNode }) {
  const cls = "flex h-14 w-[300px] max-w-full items-center rounded-md text-[20px] font-semibold text-white shadow";
  return external
    ? <a href={href} target="_blank" rel="noopener noreferrer" className={cls} style={{ backgroundColor: HC_RED }}>{children}</a>
    : <Link href={href} className={cls} style={{ backgroundColor: HC_RED }}>{children}</Link>;
}

/** DateFormat('E, MMM d,  h:mm a') on the kennel's local wall-clock. */
function appDateTime(local: string): string {
  const d = new Date(/Z$|[+-]\d\d:\d\d$/.test(local) ? local : `${local}Z`);
  const day = d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", timeZone: "UTC" });
  const time = d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", timeZone: "UTC" });
  return `${day},  ${time}`;
}

export function parseMismanagement(raw: string | null): { role: string; name: string }[] {
  if (!raw || raw.toLowerCase().includes("none listed")) return [];
  // Rows are separated by CR alone in the data (tab between role and name).
  return raw.split(/\r\n|\r|\n/).map((l) => l.trim()).filter(Boolean).map((l) => {
    const [role, ...rest] = l.split(/\t|: /);
    return { role: (role ?? "").trim(), name: rest.join(" ").trim() };
  }).filter((m) => m.role && m.name);
}
