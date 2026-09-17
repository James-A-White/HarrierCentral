"use client";

/**
 * The app's Kennels tab (kennel_list_page.dart + kennel_list_item.dart),
 * screen for screen: the white search bar, every eligible kennel as a
 * white card — the follow checkbox, the red home icon, the name in the
 * condensed face, the envelope and the bell in the header; the logo, the
 * location, "N km from here", "Runs: N, Times hared: M", "Last run" and
 * the credit line in the body, the chat bubble on the right — and the red
 * speed dial for the app's five sorts. Search is the app's: comma = and,
 * plus = or, "not " negates, each term matched at a word start.
 */
import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Search, X, Menu, Heart, ArrowDownWideNarrow, ArrowDownAZ, Building2, Globe, MessageCircle } from "lucide-react";
import type { MyKennel } from "@/lib/member-api";
import { HC_BLUE, HC_GREEN, HC_RED, bellIcon, envelopeIcon, formatDistance, haversine, isMetric, money } from "@/components/member/app-look";
import { ChoicePopup, followChoices, kennelBellChoices, kennelEnvelopeChoices } from "@/components/member/ChoicePopup";

type SortBy = "following" | "distance" | "name" | "city" | "country";
type Popup = { kind: "follow" | "bell" | "envelope"; k: MyKennel } | null;
type Me = { lat: number; lon: number } | null;

/** QueryKennels.doFilter — the app's search grammar over SearchText. */
export function filterKennels(query: string, list: MyKennel[]): MyKennel[] {
  const terms = query.trim().toLowerCase().split(",").map((t) => t.trim()).filter(Boolean);
  let out = list;
  for (let term of terms) {
    let negate = false;
    if (term.startsWith("not ")) { negate = true; term = term.slice(4); }
    const ors = term.split("+").map((o) => o.trim()).filter(Boolean);
    if (ors.length === 0) continue;
    out = out.filter((k) => {
      const text = k.SearchText ?? "";
      const plain = text.normalize("NFD").replace(/[̀-ͯ]/g, "");
      for (const o of ors) {
        const needle = ` ${o}`;
        if (text.includes(needle) || plain.includes(needle)) return !negate;
      }
      return negate;
    });
  }
  return out;
}

export function MyKennels({ initialKennels }: { initialKennels: MyKennel[] }) {
  const [kennels, setKennels] = useState<MyKennel[]>(initialKennels);
  const [query, setQuery] = useState("");
  const [sortBy, setSortBy] = useState<SortBy>("following");
  const [me, setMe] = useState<Me>(null);
  const [dialOpen, setDialOpen] = useState(false);
  const [popup, setPopup] = useState<Popup>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // The app has the phone's location; the browser asks once. Without it
  // there is no distance line and no "Sort by distance", as in the app.
  useEffect(() => {
    if (!("geolocation" in navigator)) return;
    navigator.geolocation.getCurrentPosition(
      (p) => setMe({ lat: p.coords.latitude, lon: p.coords.longitude }),
      () => setMe(null),
      { maximumAge: 300000, timeout: 8000 },
    );
  }, []);

  const distanceOf = (k: MyKennel): number | null =>
    me && k.CityLat != null && k.CityLon != null ? haversine(me.lat, me.lon, Number(k.CityLat), Number(k.CityLon)) : null;

  const visible = useMemo(() => {
    const list = filterKennels(query, kennels);
    const dist = (k: MyKennel) => distanceOf(k) ?? 0;
    const name = (k: MyKennel) => k.KennelName.trim().toLowerCase();
    const sorted = [...list];
    // Every sort keeps the home kennel first, as the app.
    const home = (a: MyKennel, b: MyKennel) => (a.IsHomeKennel === 1 ? -1 : b.IsHomeKennel === 1 ? 1 : 0);
    switch (sortBy) {
      case "distance": sorted.sort((a, b) => home(a, b) || dist(a) - dist(b)); break;
      case "name": sorted.sort((a, b) => home(a, b) || name(a).localeCompare(name(b))); break;
      case "city": sorted.sort((a, b) => home(a, b) || (a.City ?? "").localeCompare(b.City ?? "")); break;
      case "country": sorted.sort((a, b) => home(a, b) || (a.Country ?? "").localeCompare(b.Country ?? "") || (a.Region ?? "").localeCompare(b.Region ?? "") || (a.City ?? "").localeCompare(b.City ?? "")); break;
      default: {
        // following: home, then always (1) · auto (0) · never (2), then distance or name
        const rank = (k: MyKennel) => (k.Following === 1 ? 0 : k.Following === 2 ? 2 : 1);
        sorted.sort((a, b) => home(a, b) || rank(a) - rank(b) || (me ? dist(a) - dist(b) : name(a).localeCompare(name(b))));
      }
    }
    return sorted;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [kennels, query, sortBy, me]);

  function patch(id: string, fn: (k: MyKennel) => MyKennel) {
    setKennels((ks) => ks.map((k) => (k.PublicKennelId === id ? fn(k) : k)));
  }

  async function post(url: string, body: object): Promise<boolean> {
    const r = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
    if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't update."); return false; }
    return true;
  }

  async function follow(k: MyKennel, v: { following?: 0 | 1 | 2; isHomeKennel?: 0 | 1 }) {
    setPopup(null); setBusy(k.PublicKennelId); setError(null);
    try {
      if (!(await post("/api/member/follow", { publicKennelId: k.PublicKennelId.toLowerCase(), ...v }))) return;
      if (v.isHomeKennel === 1) {
        // Setting a home kennel implies following it and clears any other.
        setKennels((ks) => ks.map((x) => x.PublicKennelId === k.PublicKennelId ? { ...x, IsHomeKennel: 1, Following: 1, HasHkm: 1 } : { ...x, IsHomeKennel: 0 }));
      } else if (v.isHomeKennel === 0) {
        patch(k.PublicKennelId, (x) => ({ ...x, IsHomeKennel: 0 }));
      } else {
        patch(k.PublicKennelId, (x) => ({ ...x, Following: v.following ?? x.Following, HasHkm: 1 }));
      }
    } finally { setBusy(null); }
  }

  async function notify(k: MyKennel, field: "notification" | "email", value: number) {
    setPopup(null); setBusy(k.PublicKennelId); setError(null);
    try {
      if (!(await post("/api/member/notify", { publicKennelId: k.PublicKennelId.toLowerCase(), [field]: value }))) return;
      patch(k.PublicKennelId, (x) => field === "notification" ? { ...x, KennelNotificationPref: value, HasHkm: 1 } : { ...x, KennelEmailAlertPref: value, HasHkm: 1 });
    } finally { setBusy(null); }
  }

  const radiusText = (() => {
    const km = Number(typeof window !== "undefined" ? localStorage.getItem("hc_radius_km") : null) || 50;
    const metric = isMetric(visible[0]?.DistanceUnitsPref ?? 0);
    return formatDistance(km * 1000, metric);
  })();

  return (
    <div className="-mx-3 -mt-3 sm:-mt-4">
      {/* The app's search bar, pinned under the title bar */}
      <div className="fixed inset-x-0 top-12 z-40 bg-white shadow">
        <div className="mx-auto flex h-12 max-w-3xl items-center gap-3 px-3">
          <Search className="h-6 w-6 shrink-0 text-black" />
          <input
            value={query} onChange={(e) => setQuery(e.target.value)}
            placeholder="Search..." aria-label="Search kennels"
            className="min-w-0 flex-1 bg-transparent text-[18px] text-zinc-900 placeholder:text-zinc-500 focus:outline-none"
          />
          {query ? (
            <button type="button" onClick={() => setQuery("")} aria-label="Clear search"><X className="h-6 w-6 text-zinc-700" /></button>
          ) : (
            <span className="text-[18px] text-zinc-600">{visible.length}</span>
          )}
        </div>
      </div>

      {error && <p className="mx-3 mt-14 rounded-lg bg-white px-3 py-2 text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}

      <ul className={`px-2 pb-24 ${error ? "" : "pt-12"}`}>
        {visible.map((k) => (
          <KennelCard
            key={k.PublicKennelId} k={k} distance={distanceOf(k)} busy={busy === k.PublicKennelId}
            onFollow={() => setPopup({ kind: "follow", k })}
            onBell={() => setPopup({ kind: "bell", k })}
            onEnvelope={() => setPopup({ kind: "envelope", k })}
          />
        ))}
        {visible.length === 0 && <li className="py-8 text-center text-white/90">No kennels match.</li>}
      </ul>

      {/* The app's red speed dial: Sort by following · distance · name · city · country */}
      <div className="fixed bottom-20 right-4 z-40 flex flex-col items-end gap-3">
        {dialOpen && (
          <>
            <Dial label="Sort by following status" color={HC_RED} active={sortBy === "following"} onClick={() => { setSortBy("following"); setDialOpen(false); }}><Heart className="h-6 w-6" /></Dial>
            {me && <Dial label="Sort by distance" color="#03A9F4" active={sortBy === "distance"} onClick={() => { setSortBy("distance"); setDialOpen(false); }}><ArrowDownWideNarrow className="h-6 w-6" /></Dial>}
            <Dial label="Sort by Kennel name" color="#F48FB1" active={sortBy === "name"} onClick={() => { setSortBy("name"); setDialOpen(false); }}><ArrowDownAZ className="h-6 w-6" /></Dial>
            <Dial label="Sort by city name" color="#8BC34A" active={sortBy === "city"} onClick={() => { setSortBy("city"); setDialOpen(false); }}><Building2 className="h-6 w-6" /></Dial>
            <Dial label="Sort by country/region name" color="#8BC34A" active={sortBy === "country"} onClick={() => { setSortBy("country"); setDialOpen(false); }}><Globe className="h-6 w-6" /></Dial>
          </>
        )}
        <button type="button" aria-label="Sort" onClick={() => setDialOpen((o) => !o)}
          className="flex h-14 w-14 items-center justify-center rounded-full text-white shadow-xl" style={{ backgroundColor: HC_RED }}>
          {dialOpen ? <X className="h-7 w-7" /> : <Menu className="h-7 w-7" />}
        </button>
      </div>
      {dialOpen && <div className="fixed inset-0 z-30 bg-black/40" onClick={() => setDialOpen(false)} />}

      {popup?.kind === "follow" && (
        <ChoicePopup title={popup.k.KennelShortName} choices={followChoices(radiusText, popup.k.IsHomeKennel === 1)} onPick={(v) => follow(popup.k, v)} onClose={() => setPopup(null)} busy={!!busy} />
      )}
      {popup?.kind === "bell" && (
        <ChoicePopup title={`${popup.k.KennelShortName} notifications`} choices={kennelBellChoices} onPick={(v) => notify(popup.k, "notification", v)} onClose={() => setPopup(null)} busy={!!busy} />
      )}
      {popup?.kind === "envelope" && (
        <ChoicePopup title={`${popup.k.KennelShortName} email alerts`} choices={kennelEnvelopeChoices} onPick={(v) => notify(popup.k, "email", v)} onClose={() => setPopup(null)} busy={!!busy} />
      )}
    </div>
  );
}

function Dial({ label, color, active, onClick, children }: { label: string; color: string; active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick} className="flex items-center gap-3">
      <span className={`rounded-md bg-white px-3 py-1.5 text-[18px] text-zinc-900 shadow ${active ? "font-bold" : ""}`}>{label}</span>
      <span className="flex h-12 w-12 items-center justify-center rounded-full text-white shadow-lg" style={{ backgroundColor: color }}>{children}</span>
    </button>
  );
}

/** kennel_list_item.dart — the card. */
function KennelCard({ k, distance, busy, onFollow, onBell, onEnvelope }: {
  k: MyKennel; distance: number | null; busy: boolean; onFollow: () => void; onBell: () => void; onEnvelope: () => void;
}) {
  const href = `/me/kennels/${k.KennelSlug}`;
  const followIcon = k.Following === 1 ? "checkbox_yes" : k.Following === 2 ? "checkbox_no" : "checkbox_empty";
  const credit = Number(k.KennelCredit) || 0;
  const lastRun = k.DateOfLastRun ? appDay(k.DateOfLastRun) : null;

  return (
    <li className="mt-2.5 overflow-hidden rounded-md bg-white text-zinc-900 shadow">
      {/* Header: follow checkbox · home · name · envelope · bell */}
      <div className="flex items-center gap-1 pr-2">
        <button type="button" onClick={onFollow} disabled={busy} aria-label="Following" className="flex h-12 w-12 shrink-0 items-center justify-center disabled:opacity-50">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${followIcon}.png`} alt="" className="h-6 w-6" />
        </button>
        {k.IsHomeKennel === 1 && (
          <svg viewBox="0 0 24 24" className="h-[35px] w-[35px] shrink-0" fill={HC_RED} aria-label="Home kennel"><path d="M12 3 2 12h3v8h5v-6h4v6h5v-8h3L12 3z" /></svg>
        )}
        <Link href={href} className="font-condensed min-w-0 flex-1 truncate text-[20px] font-semibold leading-none text-zinc-900" style={{ fontWeight: 600 }}>{k.KennelName}</Link>
        <button type="button" onClick={onEnvelope} disabled={busy} aria-label="Email alerts" className="flex h-10 w-10 shrink-0 items-center justify-center disabled:opacity-50">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${envelopeIcon(k.KennelEmailAlertPref)}.png`} alt="" className="h-6 w-6" />
        </button>
        <button type="button" onClick={onBell} disabled={busy} aria-label="Notifications" className="flex h-10 w-10 shrink-0 items-center justify-center disabled:opacity-50">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={`/images/icons/${bellIcon(k.KennelNotificationPref)}.png`} alt="" className="h-6 w-6" />
        </button>
      </div>
      <div className="h-px bg-zinc-300" />

      {/* Body: logo · lines · chat */}
      <div className="flex items-center gap-2.5 py-2 pl-1.5 pr-2">
        <Link href={href} className="shrink-0">
          {k.KennelLogo?.startsWith("https://") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={k.KennelLogo} alt={k.KennelName} className="h-[85px] w-[85px] object-contain" />
          ) : (
            <div className="flex h-[85px] w-[85px] items-center justify-center rounded-full text-3xl font-bold text-white" style={{ backgroundColor: HC_RED }}>{k.KennelName.charAt(0)}</div>
          )}
        </Link>
        <div className="min-w-0 flex-1 text-[16px] leading-snug">
          <div className="truncate">{k.Location}</div>
          {distance != null && <div className="truncate">{formatDistance(distance, isMetric(k.DistanceUnitsPref))} from here</div>}
          {k.HasHkm === 1 && (
            <div className="font-semibold" style={{ color: HC_BLUE }}>Runs: {k.IsEstimate ? "~" : ""}{k.Runs}, Times hared: {k.Haring}</div>
          )}
          {k.HasHkm === 1 && lastRun && <div className="font-semibold" style={{ color: HC_BLUE }} suppressHydrationWarning>Last run: {lastRun}</div>}
          {k.HasHkm === 1 && k.AllowSelfPayment === 1 && credit !== 0 && (
            <div className="font-semibold" style={{ color: credit >= 0 ? HC_GREEN : HC_RED }}>
              {credit >= 0 ? "Credit available: " : "Funds owed: "}{money(Math.abs(credit), k.CurrencySymbol, k.DigitsAfterDecimal)}
            </div>
          )}
        </div>
        {k.HasHkm === 1 && (
          <Link href={href} className="shrink-0 text-zinc-500" aria-label="Kennel chat (in the app)" title="Kennel chat is in the Harrier Central app"><MessageCircle className="h-8 w-8" /></Link>
        )}
      </div>
    </li>
  );
}

/** DateFormat('E, MMM d') this year, 'E, MMM d, yyyy' otherwise — the app's last-run line. */
function appDay(iso: string): string {
  const d = new Date(iso);
  const showYear = d.getFullYear() !== new Date().getFullYear();
  return d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", ...(showYear && { year: "numeric" }) });
}
