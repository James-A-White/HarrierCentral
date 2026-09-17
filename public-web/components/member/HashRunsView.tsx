"use client";

/**
 * The app's Runs tab, on the web (future_run_list_page.dart +
 * run_list_item.dart): search bar, "Showing N future runs, M past runs",
 * the filter bar (My · Events · title · map · calendar), past runs inline
 * above a "↑ Past Runs ↑" divider (tinted), then the four sections —
 * My upcoming runs · Runs within N km · Runs from Kennels I follow · All
 * other upcoming runs — each card laid out as the app lays it out, with
 * the app's own icons. The list opens scrolled to the divider, as the app
 * does. Distances need the browser's location, asked for once.
 */
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { MyRun } from "@/lib/member-api";
import { HC_BLUE, HC_RED, appDate, bellIcon, envelopeIcon, formatDistance, haversine, isMetric } from "@/components/member/app-look";
import { ChoicePopup, runBellChoices, runEnvelopeChoices, type Choice } from "@/components/member/ChoicePopup";

/**
 * run_list_item._showRsvpOptionsPopup — the app's wording and its checkbox
 * art. The app also folds a notification/email toggle into this same list;
 * the web has those as their own buttons on the card, so this stays RSVP.
 */
export const rsvpChoices: Choice<Answer>[] = [
  { title: "I'll be there!", icon: "checkbox_yes", value: "yes" },
  { title: "I might be there", icon: "checkbox_maybe", value: "maybe" },
  { title: "I won't make it", icon: "checkbox_no", value: "no" },
];
import { ChatBubble, indexThreads, type ThreadIndex } from "@/components/member/ChatBubble";
import type { ChatThreadRow } from "@/lib/member-api";
import { relativeTime } from "@/lib/member-format";
import { Search, X, PartyPopper, MapPinned, CalendarSearch, MoreVertical, Map as MapIcon, Images, MessagesSquare, Beer, Info, Settings } from "lucide-react";

const RSVP_YES = 3, RSVP_MAYBE = 2, RSVP_NO = 1, AT_HASH = 20, ON_IN = 30;
/** themeButtonColors: the app's section banner colour. */
const BANNER = "#6C0243";
/** A past card: themeButtonColors at 20% over white. */
const PAST_TINT = "#E2CCD9";
/**
 * The app's ladder (kennel_list_item.getDistanceString), in the hasher's OWN
 * unit: 50 means 50 km to someone on kilometres and 50 miles to someone on
 * miles. 0 is kept so the section can be switched off, but is never the
 * default — the hasher preference bitfield is 0 until somebody touches it,
 * and reading that as "within 0 km" is what left this showing nothing
 * (James, 2026-09-17).
 */
const RADII = [0, 10, 25, 50, 75, 100, 150, 200];
const DEFAULT_RADIUS = 50;
const MILE_IN_METRES = 1609.344;

/** Preferences & 0x03 — 2 means kilometres, anything else miles. */
function prefIsMetric(prefs: number): boolean { return (prefs & 0x03) === 2; }

/** Preferences & 0x3C >> 2 indexes the ladder; rung 0 means "never set". */
function prefRadius(prefs: number): number {
  const rung = (prefs & 0x3c) >> 2;
  return RADII[rung] && rung > 0 ? RADII[rung] : DEFAULT_RADIUS;
}

export type Answer = "yes" | "maybe" | "no";
export type PrefKind = "bell" | "envelope";

// ── The app's helpers, ported ────────────────────────────────────────────────

function scopeText(scope: number | null): string | null {
  switch (scope) {
    case 2: return "Special local event";
    case 3: return "Special regional / state event";
    case 4: return "Nash Hash / national event";
    case 5: return "Interhash / continent-wide event";
    case 6: return "World Interhash / global event";
    case 7: return "Other special event";
    default: return null;
  }
}

/** kennelTzSuffix: the kennel's zone abbreviation when the viewer is elsewhere. */
function tzSuffix(run: MyRun): string {
  if (!run.EventStartDatetimeGmt || !run.KennelIANATimezone) return "";
  try {
    const viewer = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (viewer === run.KennelIANATimezone) return "";
    const parts = new Intl.DateTimeFormat("en-US", { timeZone: run.KennelIANATimezone, timeZoneName: "short" }).formatToParts(new Date(run.EventStartDatetimeGmt));
    const abbr = parts.find((p) => p.type === "timeZoneName")?.value ?? "";
    return abbr ? ` ${abbr}` : "";
  } catch { return ""; }
}

/** _getRsvpWidget: the state checkbox in the card header. */
function stateIcon(run: MyRun): string {
  if (run.MyRsvpState === RSVP_YES && run.MyIsHare === 1) return run.MyAttendenceState >= AT_HASH ? "checkbox_on_in_hare" : "checkbox_hare";
  if (run.MyAttendenceState >= ON_IN) return "checkbox_on_in";
  if (run.MyAttendenceState >= AT_HASH) return "checkbox_on_trail";
  switch (run.MyRsvpState) {
    case RSVP_NO: return "checkbox_no";
    case RSVP_MAYBE: return "checkbox_maybe";
    case RSVP_YES: return run.MyIsHare === 1 ? "checkbox_hare" : "checkbox_yes";
    default: return "checkbox_empty";
  }
}

function isMyRun(r: MyRun): boolean { return r.MyRsvpState >= RSVP_YES || r.MyAttendenceState >= AT_HASH; }
function isEvent(r: MyRun): boolean { return (r.EventGeographicScope ?? 1) >= 2; }

// ── The view ─────────────────────────────────────────────────────────────────

export function HashRunsView({ initialRuns }: { initialRuns: MyRun[] }) {
  const router = useRouter();
  const [runs, setRuns] = useState<MyRun[]>(initialRuns);
  const [query, setQuery] = useState("");
  const [filterMy, setFilterMy] = useState(false);
  const [filterEvents, setFilterEvents] = useState(false);
  const [me, setMe] = useState<{ lat: number; lon: number } | null | "denied">(null);
  const [radius, setRadius] = useState(DEFAULT_RADIUS);
  const [showRadius, setShowRadius] = useState(false);
  const [menuFor, setMenuFor] = useState<string | null>(null);
  const [pref, setPref] = useState<{ kind: PrefKind; run: MyRun } | null>(null);
  const [rsvpFor, setRsvpFor] = useState<MyRun | null>(null);
  const [threads, setThreads] = useState<ThreadIndex | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const prefs = runs[0]?.HasherPreferences ?? 0;
  const metric = prefIsMetric(prefs);
  const prefsRef = useRef(prefs);
  prefsRef.current = prefs;
  const radiusMetres = radius * (metric ? 1000 : MILE_IN_METRES);
  const dividerRef = useRef<HTMLLIElement>(null);
  const anchored = useRef(false);

  // Past runs are revealed lazily, newest first: the last PAST_PAGE sit
  // above the divider, and scrolling up to the top uncovers the next page
  // of older ones. Prepending above the viewport would jump the page on
  // Safari (no scroll anchoring), so the height added is scrolled back.
  const PAST_PAGE = 20;
  const [pastShown, setPastShown] = useState(PAST_PAGE);
  const topSentinel = useRef<HTMLLIElement>(null);
  const pendingHeight = useRef<number | null>(null);

  // Where am I — once, for "Runs within N km" and "X km from here".
  useEffect(() => {
    if (!navigator.geolocation) { setMe("denied"); return; }
    navigator.geolocation.getCurrentPosition(
      (p) => setMe({ lat: p.coords.latitude, lon: p.coords.longitude }),
      () => setMe("denied"),
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300_000 },
    );
  }, []);

  // The app's radius preference lives in Hasher.Preferences; on the web it is remembered per browser.
  // A stored choice wins; otherwise take the hasher's own rung, else 50.
  // getItem returns null when unset and Number(null) is 0, which used to be
  // accepted straight into the radius and silenced the section.
  useEffect(() => {
    try {
      const raw = localStorage.getItem("hc_radius");
      const v = raw === null ? NaN : Number(raw);
      if (Number.isFinite(v) && RADII.includes(v)) { setRadius(v); return; }
    } catch { /* private window */ }
    setRadius(prefRadius(prefsRef.current));
  }, []);
  const chooseRadius = (v: number) => { setRadius(v); setShowRadius(false); try { localStorage.setItem("hc_radius", String(v)); } catch {} };

  const distanceOf = useCallback((r: MyRun): number | null => {
    if (!me || me === "denied" || r.Latitude == null || r.Longitude == null) return null;
    return haversine(me.lat, me.lon, Number(r.Latitude), Number(r.Longitude));
  }, [me]);

  // _applyChipFilters + doRunsSearchTextFilter
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return runs.filter((r) => {
      if (filterEvents && !isEvent(r)) return false;
      if (filterMy && !isMyRun(r)) return false;
      if (!q) return true;
      const hay = `${r.EventName} ${r.EventNumber} ${r.KennelName} ${r.KennelShortName} ${r.Hares ?? ""} ${r.LocationOneLineDesc ?? ""} ${r.LocationCity ?? ""} ${r.LocationCountry ?? ""}`.toLowerCase();
      return q.startsWith("not ") ? !hay.includes(q.slice(4).trim()) : hay.includes(q);
    });
  }, [runs, query, filterMy, filterEvents]);

  const past = useMemo(() => filtered.filter((r) => r.IsPast === 1).sort((a, b) => (a.EventStartDatetimeGmt ?? a.EventStartDatetime).localeCompare(b.EventStartDatetimeGmt ?? b.EventStartDatetime)), [filtered]);
  const future = useMemo(() => filtered.filter((r) => r.IsPast !== 1).sort((a, b) => (a.EventStartDatetimeGmt ?? a.EventStartDatetime).localeCompare(b.EventStartDatetimeGmt ?? b.EventStartDatetime)), [filtered]);

  // runClassification: 1 mine · 2 within the radius · 3 a kennel I follow · 4 everything else
  const sections = useMemo(() => {
    const s: Record<1 | 2 | 3 | 4, MyRun[]> = { 1: [], 2: [], 3: [], 4: [] };
    for (const r of future) {
      const d = distanceOf(r);
      if (isMyRun(r)) s[1].push(r);
      else if (d != null && radius > 0 && d <= radiusMetres) s[2].push(r);
      else if (r.Following === 1) s[3].push(r);
      else s[4].push(r);
    }
    return s;
  }, [future, distanceOf, radius, radiusMetres]);

  // Open on the divider, past runs above — the app's initial anchor.
  useEffect(() => {
    if (anchored.current || past.length === 0) return;
    anchored.current = true;
    requestAnimationFrame(() => dividerRef.current?.scrollIntoView({ block: "start" }));
  }, [past.length]);

  // Reset the window when the list itself changes (search, chips).
  useEffect(() => { setPastShown(PAST_PAGE); }, [query, filterMy, filterEvents]);

  const visiblePast = useMemo(() => past.slice(Math.max(0, past.length - pastShown)), [past, pastShown]);
  const morePast = past.length > pastShown;

  useEffect(() => {
    const el = topSentinel.current;
    if (!el || !morePast) return;
    const io = new IntersectionObserver((entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      pendingHeight.current = document.documentElement.scrollHeight;
      setPastShown((n) => n + PAST_PAGE);
    }, { rootMargin: "400px 0px 0px 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, [morePast, pastShown]);

  useLayoutEffect(() => {
    if (pendingHeight.current == null) return;
    const delta = document.documentElement.scrollHeight - pendingHeight.current;
    pendingHeight.current = null;
    if (delta > 0) window.scrollBy(0, delta);
  }, [visiblePast.length]);

  async function rsvp(run: MyRun, answer: Answer) {
    setBusy(run.PublicEventId); setError(null); setMenuFor(null);
    try {
      const r = await fetch("/api/member/rsvp", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ publicEventId: run.PublicEventId.toLowerCase(), rsvp: answer }) });
      const j = (await r.json()) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't save your RSVP."); return; }
      const state = answer === "yes" ? RSVP_YES : answer === "maybe" ? RSVP_MAYBE : RSVP_NO;
      setRuns((rs) => rs.map((x) => x.PublicEventId === run.PublicEventId
        ? { ...x, MyRsvpState: state, GoingCount: x.GoingCount + (state === RSVP_YES && x.MyRsvpState !== RSVP_YES ? 1 : 0) - (state !== RSVP_YES && x.MyRsvpState === RSVP_YES ? 1 : 0) }
        : x));
    } finally { setBusy(null); }
  }

  const noun = filterEvents ? "Events" : "Runs";
  const barTitle = `${filterMy ? "My" : "All"} ${noun}`;
  // The three-state chat bubbles: the app's badge list, fetched once.
  useEffect(() => {
    fetch("/api/member/chat?threads=1", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : null))
      .then((j: { threads?: ChatThreadRow[] } | null) => { if (j?.threads) setThreads(indexThreads(j.threads)); })
      .catch(() => undefined);
  }, []);

  // The bell and the envelope (E9.F7.S14): the app's own preference SP.
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

  const radiusLabel = `${radius} ${metric ? "km" : "miles"}`;

  return (
    <div className="-mx-3 -mt-[12px] sm:-mt-[16px] md:-mx-6">
      {/* The app pins the search, the count strip and the filter bar; the
          list scrolls under them. Fixed under the purple title bar (48px);
          the list is padded by their height (48 + 1 + 24 + 1 + 55). */}
      <div className="fixed inset-x-0 top-12 z-40">
      {/* Search — the app's white bar with the magnifier and X */}
      <div className="flex items-center gap-3 bg-white px-4 py-2.5">
        <Search className="h-6 w-6 shrink-0 text-zinc-900" />
        <input
          value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search..."
          className="min-w-0 flex-1 bg-transparent text-[22px] text-zinc-900 placeholder:text-zinc-500 focus:outline-none"
        />
        <button type="button" aria-label="Clear" onClick={() => setQuery("")} className="text-zinc-600"><X className="h-6 w-6" /></button>
      </div>
      <div className="h-px bg-zinc-400" />
      {/* resultCountLabel */}
      <div className="flex h-6 items-center justify-center bg-zinc-200 text-[13px] font-semibold text-zinc-900" suppressHydrationWarning>
        Showing {future.length} future runs, {past.length} past runs
      </div>
      <div className="h-px bg-zinc-400" />

      {/* Filter bar — black38 over the jungle, 55px */}
      <div className="flex h-[55px] items-center gap-2 px-2" style={{ backgroundColor: "rgba(0,0,0,0.38)" }}>
        <Chip on={filterMy} onClick={() => setFilterMy((v) => !v)} label="My" />
        <Chip on={filterEvents} onClick={() => setFilterEvents((v) => !v)} icon={<PartyPopper className="h-5 w-5" />} title="Events only" />
        <div className="min-w-0 flex-1 text-center text-[26px] font-semibold leading-none text-white">{barTitle}</div>
        <Chip on={false} onClick={() => router.push("/me/map")} icon={<MapPinned className="h-5 w-5" />} title="Runs on the map" />
        <Chip on={false} onClick={() => router.push("/calendar")} icon={<CalendarSearch className="h-5 w-5" />} title="Calendar" />
      </div>
      </div>

      {error && <p className="mx-3 mt-2 rounded-lg bg-white px-3 py-2 text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}

      <ul className="space-y-2 px-2.5 pb-12 pt-[134px]">
        {morePast && (
          <li ref={topSentinel} className="py-3 text-center text-sm text-white/80" aria-live="polite">
            Loading older runs… ({past.length - pastShown} more)
          </li>
        )}
        {visiblePast.map((r) => <RunCard key={r.PublicEventId} run={r} past distance={distanceOf(r)} menuOpen={menuFor === r.PublicEventId} onMenu={() => setMenuFor(menuFor === r.PublicEventId ? null : r.PublicEventId)} onRsvp={rsvp} onPref={(run, kind) => setPref({ kind, run })} onState={setRsvpFor} threads={threads} busy={busy === r.PublicEventId} />)}

        {past.length > 0 && (
          <li ref={dividerRef} className="scroll-mt-[186px]">
            <Banner>↑ Past Runs ↑</Banner>
          </li>
        )}

        {future.length === 0 && (
          <li className="py-8 text-center text-[22px] text-yellow-300">[No {filterMy ? "runs of yours" : "runs"} to show]</li>
        )}

        {([1, 2, 3, 4] as const).map((n) => {
          const rows = sections[n];
          if (n !== 1 && n !== 2 && rows.length === 0) return null;
          return (
            <li key={n} className="space-y-2">
              <Banner
                left={n === 2 ? <span className="w-9" /> : n === 1 && rows.length === 0 ? <span className="w-9" /> : undefined}
                right={
                  n === 2 ? <button type="button" aria-label="Distance" onClick={() => setShowRadius((v) => !v)} className="w-9 text-white"><Settings className="mx-auto h-6 w-6" /></button>
                  : n === 1 && rows.length === 0 ? <span title="Not only does it help the hares to plan for how much beer to buy, but it helps you keep track of which trails you plan to attend. It also lets your friends know if you'll be there." className="w-9 text-white"><Info className="mx-auto h-6 w-6" /></span>
                  : undefined
                }
              >
                {n === 1 ? (rows.length === 0 ? "Learn about RSVPs →" : "My upcoming runs")
                  : n === 2 ? `Runs within ${radiusLabel}`
                  : n === 3 ? "Runs from Kennels I follow"
                  : "All other upcoming runs"}
              </Banner>
              {n === 2 && showRadius && (
                <div className="flex flex-wrap justify-center gap-2 py-1">
                  {RADII.map((km) => (
                    <button key={km} type="button" onClick={() => chooseRadius(km)}
                      className="rounded-full px-3 py-1 text-sm font-semibold"
                      style={km === radius ? { backgroundColor: HC_RED, color: "#fff" } : { backgroundColor: "#fff", color: "#18181b" }}>
                      {km === 0 ? "Off" : `${km} ${metric ? "km" : "miles"}`}
                    </button>
                  ))}
                </div>
              )}
              {n === 2 && rows.length === 0 && (
                <p className="py-2 text-center text-[20px] text-yellow-300" suppressHydrationWarning>
                  {me === "denied" ? "[Enable location to see runs near you]" : me === null ? "[Finding where you are…]" : `[No runs found within ${radiusLabel}]`}
                </p>
              )}
              <ul className="space-y-2">
                {rows.map((r) => <RunCard key={r.PublicEventId} run={r} distance={distanceOf(r)} menuOpen={menuFor === r.PublicEventId} onMenu={() => setMenuFor(menuFor === r.PublicEventId ? null : r.PublicEventId)} onRsvp={rsvp} onPref={(run, kind) => setPref({ kind, run })} onState={setRsvpFor} threads={threads} busy={busy === r.PublicEventId} />)}
              </ul>
            </li>
          );
        })}
      </ul>
      {pref && (
        <ChoicePopup title={pref.run.EventName} choices={pref.kind === "bell" ? runBellChoices : runEnvelopeChoices}
          onPick={(v) => notify(pref.run, pref.kind, v)} onClose={() => setPref(null)} busy={!!busy} />
      )}

      {/* Tapping the state box answers the run, as in the app — it does not
          navigate anywhere (James, 2026-09-17). */}
      {rsvpFor && (
        <ChoicePopup title={rsvpFor.EventName} choices={rsvpChoices}
          onPick={(a) => rsvp(rsvpFor, a)} onClose={() => setRsvpFor(null)} busy={!!busy} />
      )}
    </div>
  );
}

function Chip({ on, onClick, label, icon, title }: { on: boolean; onClick: () => void; label?: string; icon?: React.ReactNode; title?: string }) {
  return (
    <button type="button" onClick={onClick} title={title} aria-pressed={on}
      className="flex h-[42px] min-w-[46px] items-center justify-center rounded-lg border px-2 text-[24px] font-semibold text-white"
      style={{ backgroundColor: on ? BANNER : "rgba(0,0,0,0.35)", borderColor: "rgba(255,255,255,0.6)" }}>
      {label ?? icon}
    </button>
  );
}

/** The app's section banner: themeButtonColors, 40px, white title, optional icons at the ends. */
function Banner({ children, left, right }: { children: React.ReactNode; left?: React.ReactNode; right?: React.ReactNode }) {
  return (
    <div className="mt-2 flex h-10 items-center justify-between px-1 text-[22px] font-bold text-white" style={{ backgroundColor: BANNER }}>
      {left ?? <span className="w-9" />}
      <span className="min-w-0 flex-1 truncate text-center">{children}</span>
      {right ?? <span className="w-9" />}
    </div>
  );
}

export function RunCard({ run, past, distance, menuOpen, onMenu, onRsvp, onPref, onState, busy, back = "/me/runs", threads = null }: {
  run: MyRun; past?: boolean; distance: number | null; menuOpen: boolean; onMenu: () => void; onRsvp: (r: MyRun, a: Answer) => void;
  onPref?: (r: MyRun, kind: PrefKind) => void; onState?: (r: MyRun) => void; busy: boolean; back?: string; threads?: ThreadIndex | null;
}) {
  const href = `/${run.KennelSlug}/${run.EventNumber}?back=${encodeURIComponent(back)}`;
  const when = run.EventStartDatetimeGmt ?? run.EventStartDatetime;
  const scope = scopeText(run.EventGeographicScope);
  const metric = isMetric(run.DistanceUnitsPref ?? 0);
  const runners = run.TrackRunnerCount ?? 0, photos = run.PhotoCount ?? 0, messages = run.MessageCount ?? 0, downDowns = run.DownDownCount ?? 0;
  const hasCounts = runners > 0 || photos > 0 || messages > 0 || downDowns > 0;

  return (
    <li className="relative overflow-hidden rounded-md shadow" style={{ backgroundColor: past ? PAST_TINT : "#fff" }}>
      {/* Header: state · title · envelope · bell */}
      <div className="flex items-center gap-1 px-1.5 pt-1.5 pb-1">
        {/* The app hangs an invisible 56x56 hit target over this box and
            opens the RSVP list from it, and only when the run is still to
            come. Same here: answer the run in place, never navigate. */}
        <button
          type="button"
          onClick={() => onState?.(run)}
          disabled={past || busy || !onState}
          aria-label={past ? "This run has been" : `Answer ${run.EventName}`}
          className="-m-1.5 flex h-11 w-11 shrink-0 items-center justify-center p-1.5 disabled:cursor-default"
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${stateIcon(run)}.png`} alt="" className="h-6 w-6" />
        </button>
        <Link href={href} className="min-w-0 flex-1 truncate text-[20px] font-bold leading-tight text-zinc-900">{run.EventName}</Link>
        <button type="button" onClick={() => onPref?.(run, "envelope")} disabled={busy || !onPref} aria-label="Email alert" className="shrink-0 disabled:opacity-60">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${envelopeIcon(run.MyEmailAlertPref)}.png`} alt="" className="h-7 w-7" />
        </button>
        <button type="button" onClick={() => onPref?.(run, "bell")} disabled={busy || !onPref} aria-label="Notifications" className="ml-1 shrink-0 disabled:opacity-60">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${bellIcon(run.MyNotificationPref)}.png`} alt="" className="h-7 w-7" />
        </button>
      </div>
      <div className="mx-1.5 h-px bg-zinc-300" />

      {/* Body: logo · lines · right column */}
      <div className="flex items-center gap-2 px-1.5 py-2">
        <Link href={`/me/kennels/${run.KennelSlug}`} className="shrink-0">
          {run.KennelLogo?.startsWith("https://") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={run.KennelLogo} alt={run.KennelName} className="h-[84px] w-[84px] object-contain" />
          ) : (
            <div className="flex h-[84px] w-[84px] items-center justify-center rounded-full text-3xl font-bold text-white" style={{ backgroundColor: run.PrimaryColor ?? HC_RED }}>{run.KennelName.charAt(0)}</div>
          )}
        </Link>
        <div className="min-w-0 flex-1 text-[19px] leading-[1.25] text-zinc-900">
          <Link href={`/me/kennels/${run.KennelSlug}`} className="block truncate font-semibold hover:underline" style={{ color: HC_BLUE }}>{run.KennelName}</Link>
          <div className="font-bold" suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ` : "Run / Event "}{relativeTime(when)}
          </div>
          <div suppressHydrationWarning>{appDate(run.EventStartDatetime, run.EventStartDatetimeGmt, run.KennelIANATimezone)}{tzSuffix(run)}</div>
          {run.Hares && <div className="truncate">Hares: {run.Hares}</div>}
          <div className="truncate">{run.LocationOneLineDesc || "No location provided"}</div>
          {distance != null && <div className="truncate">{formatDistance(distance, metric)} from here</div>}
          {scope && <div className="truncate">{scope}</div>}
          {hasCounts && (
            <div className="mt-1.5 flex flex-wrap items-center gap-3.5 text-[15px] text-zinc-500">
              {runners > 0 && <span className="flex items-center gap-1" title={`PackTrack: ${runners} runner${runners === 1 ? "" : "s"}`}><MapIcon className="h-5 w-5" />{runners}</span>}
              {photos > 0 && <span className="flex items-center gap-1" title="Photos"><Images className="h-5 w-5" />{photos}</span>}
              {messages > 0 && <span className="flex items-center gap-1" title="Trail chat"><MessagesSquare className="h-5 w-5" />{messages}</span>}
              {downDowns > 0 && <span className="flex items-center gap-1" title="Down-downs"><Beer className="h-5 w-5" />{downDowns}</span>}
            </div>
          )}
        </div>
        <div className="flex shrink-0 flex-col items-center gap-3 pt-4 text-zinc-500">
          <ChatBubble kind="run" id={run.PublicEventId} title={run.EventName} back={back} threads={threads} />
          <button type="button" aria-label="More" onClick={onMenu} disabled={busy}><MoreVertical className="h-8 w-8" /></button>
        </div>
      </div>

      {/* The ⋮ popup: the app's RSVP choices */}
      {menuOpen && (
        <div className="absolute right-2 top-14 z-10 w-56 overflow-hidden rounded-xl bg-white text-[17px] text-zinc-900 shadow-2xl ring-1 ring-black/10">
          {!past && (
            <>
              <MenuItem icon="checkbox_yes" label="I'll be there!" onClick={() => onRsvp(run, "yes")} />
              <MenuItem icon="checkbox_maybe" label="I might be there" onClick={() => onRsvp(run, "maybe")} />
              <MenuItem icon="checkbox_no" label="I won't make it" onClick={() => onRsvp(run, "no")} />
            </>
          )}
          <Link href={href} className={`block px-4 py-2.5 hover:bg-zinc-100 ${past ? "" : "border-t border-zinc-200"}`}>Run details</Link>
          <Link href={`/${run.KennelSlug}/${run.EventNumber}/photos`} className="block border-t border-zinc-200 px-4 py-2.5 hover:bg-zinc-100">Photos</Link>
        </div>
      )}

      {run.EventImage?.startsWith("http") && (
        <Link href={href}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={run.EventImage} alt="" className="w-full object-cover" style={{ maxHeight: 260 }} />
        </Link>
      )}
    </li>
  );
}

function MenuItem({ icon, label, onClick }: { icon: string; label: string; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} className="flex w-full items-center gap-3 px-4 py-2.5 text-left hover:bg-zinc-100">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={`/images/icons/${icon}.png`} alt="" className="h-6 w-6" />
      {label}
    </button>
  );
}

