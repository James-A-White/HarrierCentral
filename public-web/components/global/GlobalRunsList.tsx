"use client";

import { useState, useMemo, useCallback, useEffect, useRef, useTransition } from "react";
import { useRouter } from "next/navigation";
import QRCode from "react-qr-code";
import {
  Search, X, MapPin, Navigation, Tag, Copy, QrCode, ArrowLeft, LayoutList, CalendarDays, Loader2, Map as MapIcon, Info,
} from "lucide-react";
import { useVirtualizer } from "@tanstack/react-virtual";
import dynamic from "next/dynamic";
import type { GlobalRunRow, GetGlobalRunsResult } from "@/lib/api";

const RunLocationMap = dynamic(() => import("./RunLocationMap"), { ssr: false });

// ─── Constants ────────────────────────────────────────────────────────────────

const PAGE_SIZE = 200;
const HASHRUNS_ORIGIN = "https://hashruns.org";
const CURRENT_YEAR = new Date().getFullYear();

// Module-level cache — survives client-side navigation for the lifetime of the
// browser tab. Updated after every bucket so partial progress is preserved on
// back-navigation even if the user leaves before loading completes.
const _pastCache: { runs: GlobalRunRow[]; done: boolean } = { runs: [], done: false };

// ─── Helpers ──────────────────────────────────────────────────────────────────

function relativeTime(iso: string): string {
  const diffDays = Math.round(
    (new Date(iso).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
  );
  if (diffDays === 0) return "TODAY";
  if (diffDays === 1) return "Tomorrow";
  if (diffDays > 1 && diffDays < 14) return `in ${diffDays} days`;
  if (diffDays >= 14 && diffDays < 60)
    return `in ${Math.round(diffDays / 7)} weeks`;
  if (diffDays >= 60) {
    const m = Math.round(diffDays / 30);
    return `in ${m} month${m !== 1 ? "s" : ""}`;
  }
  if (diffDays === -1) return "yesterday";
  if (diffDays > -14) return `${Math.abs(diffDays)} days ago`;
  if (diffDays > -60) return `${Math.round(Math.abs(diffDays) / 7)} weeks ago`;
  if (diffDays > -365) {
    const m = Math.round(Math.abs(diffDays) / 30);
    return `${m} month${m !== 1 ? "s" : ""} ago`;
  }
  const y = Math.round(Math.abs(diffDays) / 365);
  return `${y} year${y !== 1 ? "s" : ""} ago`;
}

function formatDate(iso: string) {
  const d = new Date(iso);
  const showYear = d.getFullYear() !== CURRENT_YEAR;
  return {
    short: d.toLocaleDateString("en-GB", {
      weekday: "short", day: "numeric", month: "short",
      ...(showYear && { year: "numeric" }),
    }),
    long: d.toLocaleDateString("en-GB", {
      weekday: "long", day: "numeric", month: "long",
      ...(showYear && { year: "numeric" }),
    }),
    time: d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }),
  };
}

function mapsUrl(lat: number | null, lon: number | null): string | null {
  if (!lat || !lon) return null;
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`;
}

function formatFee(amount: number | null | undefined, currency: string | null): string {
  if (!amount) return "Free";
  return currency ? `${currency} ${amount.toFixed(2)}` : amount.toFixed(2);
}

function parseW3w(json: string | null): string | null {
  if (!json) return null;
  try {
    const p = JSON.parse(json) as { map?: string; words?: string };
    return p.map ?? (p.words ? `https://what3words.com/${p.words}` : null);
  } catch {
    return null;
  }
}

function normalizeWebsiteUrl(domain: string): string {
  if (domain.startsWith("http://") || domain.startsWith("https://")) return domain;
  return `https://${domain}`;
}

// ─── KennelLogo ───────────────────────────────────────────────────────────────

function KennelLogo({ run, size = "sm" }: { run: GlobalRunRow; size?: "sm" | "md" | "lg" }) {
  const hasImage = run.KennelLogo?.startsWith("https://");
  const bg = run.PrimaryColor ?? "#dc2626";
  const dim = size === "sm" ? "h-12 w-12" : size === "md" ? "h-16 w-16" : "h-20 w-20";
  const text = size === "sm" ? "text-lg" : size === "md" ? "text-xl" : "text-2xl";

  if (hasImage) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={run.KennelLogo!}
        alt={run.KennelName}
        className={`${dim} object-contain rounded-lg shrink-0`}
      />
    );
  }
  return (
    <div
      className={`${dim} rounded-lg flex items-center justify-center ${text} font-bold text-white shrink-0`}
      style={{ backgroundColor: bg }}
    >
      {run.KennelName.charAt(0).toUpperCase()}
    </div>
  );
}

// ─── Run list card ────────────────────────────────────────────────────────────

function GlobalRunCard({
  run,
  isSelected,
  onClick,
}: {
  run: GlobalRunRow;
  isSelected: boolean;
  onClick: () => void;
}) {
  const primaryColor = run.PrimaryColor ?? "#dc2626";
  const rel = relativeTime(run.EventStartDatetime);
  const { short, time } = formatDate(run.EventStartDatetime);
  const location = [run.LocationCity, run.LocationCountry].filter(Boolean).join(", ");

  return (
    <button
      onClick={onClick}
      className={[
        "relative w-full text-left rounded-xl bg-white shadow-sm border transition-colors overflow-hidden",
        isSelected ? "border-zinc-400" : "border-zinc-200 hover:border-zinc-300",
      ].join(" ")}
    >
      {/* Selected indicator — absolutely positioned so it overlays content without shifting it */}
      {isSelected && (
        <div
          className="absolute left-0 top-0 bottom-0 w-1 z-10"
          style={{ backgroundColor: primaryColor }}
        />
      )}

      {/* Run image */}
      {run.EventImage && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={run.EventImage} alt={run.EventName} className="w-full h-auto block" />
      )}

      {/* Bold title */}
      <div className="px-3 pt-2 pb-1">
        <p className="text-sm font-bold text-zinc-900 leading-tight truncate">
          {run.EventName}
        </p>
      </div>

      {/* Hairline divider */}
      <hr className="border-zinc-200 mx-0" />

      {/* Content: logo + details */}
      <div className="flex items-start gap-2.5 px-3 py-1.5">
        <KennelLogo run={run} size="md" />

        <div className="min-w-0 flex-1">
          {/* Kennel name — primary colour, bold */}
          <p
            className="text-sm font-bold leading-tight truncate"
            style={{ color: primaryColor }}
          >
            {run.KennelName}
          </p>

          {/* Run number + relative time — bold black */}
          <p className="text-xs font-bold text-zinc-900 leading-tight truncate" suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ` : ""}{rel}
          </p>

          {/* Date and time */}
          <p className="text-xs text-zinc-700 leading-tight truncate" suppressHydrationWarning>
            {short} at {time}
          </p>

          {/* City, Country */}
          {location && (
            <p className="text-xs text-zinc-700 leading-tight truncate">{location}</p>
          )}

          {/* Venue */}
          {run.LocationOneLineDesc && (
            <p className="text-xs text-zinc-700 leading-tight truncate">
              Location: {run.LocationOneLineDesc}
            </p>
          )}
        </div>
      </div>
    </button>
  );
}

// ─── Section divider ──────────────────────────────────────────────────────────

function SectionDivider() {
  return (
    <div className="flex items-center px-6 py-1">
      <div className="flex-1 h-px bg-white/20" />
      <div className="mx-2 h-2 w-2 rounded-full bg-white/40" />
      <div className="flex-1 h-px bg-white/20" />
    </div>
  );
}

// ─── Field row ────────────────────────────────────────────────────────────────

function FieldRow({
  label,
  value,
  suppressHydration,
}: {
  label: string;
  value: React.ReactNode;
  suppressHydration?: boolean;
}) {
  return (
    <div className="flex gap-3 py-0.5">
      <span className="w-28 shrink-0 text-sm text-amber-400 text-right leading-snug">
        {label}
      </span>
      <span
        className="flex-1 min-w-0 text-sm text-white font-bold leading-snug"
        suppressHydrationWarning={suppressHydration}
      >
        {value}
      </span>
    </div>
  );
}

// ─── QR section ───────────────────────────────────────────────────────────────

function QRSection({ run }: { run: GlobalRunRow }) {
  const bg = run.PrimaryColor ?? "#dc2626";
  const runUrl     = `${HASHRUNS_ORIGIN}/${run.KennelSlug}/${run.EventNumber}`;
  const nextRunUrl = `${HASHRUNS_ORIGIN}/${run.KennelSlug}/next-run`;
  const listUrl    = `${HASHRUNS_ORIGIN}/${run.KennelSlug}`;
  const siteUrl    = run.KennelWebsiteDomain
    ? normalizeWebsiteUrl(run.KennelWebsiteDomain)
    : null;

  const qrProps = { size: 140, bgColor: "#ffffff", fgColor: "#000000", level: "M" as const };

  return (
    <div className="px-5 pb-6 border-t border-white/[0.08]">
      <div className={`grid gap-4 pt-5 ${siteUrl ? "grid-cols-4" : "grid-cols-3"}`}>
        {[
          { label: "This Run", url: runUrl },
          { label: `Next Run`, url: nextRunUrl },
          { label: "Run list", url: listUrl },
          ...(siteUrl ? [{ label: "Website", url: siteUrl }] : []),
        ].map(({ label, url }) => (
          <div key={label} className="flex flex-col items-center gap-2">
            <p className="text-2xl font-semibold text-center text-white/80">{label}</p>
            <div className="p-2 bg-white rounded-lg">
              <QRCode value={url} {...qrProps} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Run detail panel ─────────────────────────────────────────────────────────

function GlobalRunDetail({ run }: { run: GlobalRunRow }) {
  const [showQr, setShowQr] = useState(false);
  const [copied, setCopied] = useState(false);

  const { long: longDate, time } = formatDate(run.EventStartDatetime);
  const mapsLink = mapsUrl(run.Latitude, run.Longitude);
  const w3wLink  = parseW3w(run.w3wJson);
  const siteUrl  = run.KennelWebsiteDomain ? normalizeWebsiteUrl(run.KennelWebsiteDomain) : null;
  const runUrl   = `${HASHRUNS_ORIGIN}/${run.KennelSlug}/${run.EventNumber}`;

  useEffect(() => { setShowQr(false); setCopied(false); }, [run.PublicEventId]);

  const handleCopy = () => {
    navigator.clipboard.writeText(runUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  const btnCls = "inline-flex items-center gap-2 rounded-full bg-red-600 hover:bg-red-700 px-5 py-2.5 text-sm font-semibold text-white transition-colors";

  return (
    <div className="flex flex-col overflow-y-auto h-full">

      {/* ── Run image ── */}
      {run.EventImage && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={run.EventImage}
          alt={run.EventName}
          className="w-full h-auto block shrink-0"
        />
      )}

      {/* ── Kennel logo + event name ── */}
      <div className="flex items-center justify-center gap-4 px-6 py-5 shrink-0">
        <KennelLogo run={run} size="lg" />
        <h2 className="text-lg font-bold text-white leading-snug">{run.EventName}</h2>
      </div>

      <SectionDivider />

      {/* ── Event details ── */}
      <div className="px-6 py-4">
        <p className="text-center text-amber-400 text-2xl font-semibold mb-3">Event details</p>
        <div className="flex flex-col gap-1">
          <FieldRow label="Kennel:" value={run.KennelName} />
          {run.IsCountedRun && <FieldRow label="Run #:" value={String(run.EventNumber)} />}
          <FieldRow label="Date:" value={longDate} suppressHydration />
          <FieldRow label="Time:" value={time} suppressHydration />
          {run.LocationOneLineDesc && <FieldRow label="Place:" value={run.LocationOneLineDesc} />}
          {(run.EventPriceForMembers !== null || run.EventPriceForNonMembers !== null) && (
            <FieldRow
              label="Run fees:"
              value={
                <span>
                  {run.EventPriceForMembers !== null && (
                    <span className="block">{formatFee(run.EventPriceForMembers, run.EventCurrencyType)} (members)</span>
                  )}
                  {run.EventPriceForNonMembers !== null && (
                    <span className="block">{formatFee(run.EventPriceForNonMembers, run.EventCurrencyType)} (non-members)</span>
                  )}
                </span>
              }
            />
          )}
          {run.LocationStreet && <FieldRow label="Street:" value={run.LocationStreet} />}
          {run.LocationPostCode && <FieldRow label="Post code:" value={run.LocationPostCode} />}
          {run.LocationCity && <FieldRow label="City:" value={run.LocationCity} />}
          {run.LocationRegion && <FieldRow label="Region:" value={run.LocationRegion} />}
          {run.LocationCountry && <FieldRow label="Country:" value={run.LocationCountry} />}
          {run.EventTypeName && <FieldRow label="Event type:" value={run.EventTypeName} />}
          {run.Hares && <FieldRow label="Hares:" value={run.Hares} />}
        </div>
      </div>

      <SectionDivider />

      {/* ── Action buttons ── */}
      <div className="px-6 py-4 flex flex-wrap gap-3 justify-center">
        {mapsLink && (
          <a href={mapsLink} target="_blank" rel="noopener noreferrer" className={btnCls}>
            <Navigation className="h-3.5 w-3.5" />Open Map
          </a>
        )}
        {w3wLink && (
          <a href={w3wLink} target="_blank" rel="noopener noreferrer" className={btnCls}>
            <MapPin className="h-3.5 w-3.5" />W3W
          </a>
        )}
        <button onClick={handleCopy} className={btnCls}>
          <Copy className="h-3.5 w-3.5" />{copied ? "Copied!" : "Copy link to run"}
        </button>
        <button onClick={() => setShowQr((v) => !v)} className={btnCls}>
          <QrCode className="h-3.5 w-3.5" />{showQr ? "Hide QR codes" : "Show QR codes"}
        </button>
        {siteUrl && (
          <a href={siteUrl} target="_blank" rel="noopener noreferrer" className={btnCls}>
            Open {run.KennelName} website
          </a>
        )}
      </div>

      {/* ── QR section ── */}
      {showQr && <QRSection run={run} />}

      {/* ── Tags ── */}
      {run.tags.length > 0 && (
        <>
          <SectionDivider />
          <div className="px-6 py-4">
            <p className="text-center text-amber-400 text-2xl font-semibold mb-3">Event tags</p>
            <div className="flex flex-wrap gap-2 justify-center">
              {run.tags.map((tag) => (
                <span key={tag} className="rounded-full border border-white/15 bg-white/[0.08] px-3 py-1 text-lg font-semibold text-white">
                  {tag}
                </span>
              ))}
            </div>
          </div>
        </>
      )}

      {/* ── Description ── */}
      {run.EventDescription && (
        <>
          <SectionDivider />
          <div className="px-6 py-4">
            <p className="text-center text-amber-400 text-2xl font-semibold mb-3">Event description</p>
            <p className="text-lg leading-7 font-medium text-white/90 whitespace-pre-wrap px-6">{run.EventDescription}</p>
          </div>
        </>
      )}

    </div>
  );
}

// ─── Calendar view ────────────────────────────────────────────────────────────

function CalendarView({
  runs,
  selectedRun,
  onSelect,
  sortDesc = false,
}: {
  runs: GlobalRunRow[];
  selectedRun: GlobalRunRow | null;
  onSelect: (run: GlobalRunRow) => void;
  sortDesc?: boolean;
}) {
  const parentRef = useRef<HTMLDivElement>(null);

  const todayStr = useMemo(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  }, []);

  const groups = useMemo(() => {
    const map = new Map<string, GlobalRunRow[]>();
    for (const run of runs) {
      const key = run.EventStartDatetime.slice(0, 10);
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(run);
    }
    return Array.from(map.entries()).sort(([a], [b]) =>
      sortDesc ? b.localeCompare(a) : a.localeCompare(b)
    );
  }, [runs, sortDesc]);

  const virtualizer = useVirtualizer({
    count: groups.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 72,
    overscan: 5,
  });

  if (groups.length === 0) {
    return <div className="flex-1 py-16 text-center text-sm text-zinc-400">No runs found</div>;
  }

  return (
    <div ref={parentRef} className="flex-1 overflow-y-auto bg-transparent">
      <div style={{ height: virtualizer.getTotalSize(), position: "relative" }}>
        {virtualizer.getVirtualItems().map((vItem) => {
          const [date, dayRuns] = groups[vItem.index];
          const isToday = date === todayStr;
          const d = new Date(date + "T12:00:00Z");
          const showYear = d.getUTCFullYear() !== CURRENT_YEAR;
          const dayOfWeek = d.toLocaleDateString("en-GB", { weekday: "short", timeZone: "UTC" });
          const shortDate = d.toLocaleDateString("en-GB", {
            day: "numeric", month: "short", timeZone: "UTC",
            ...(showYear && { year: "numeric" }),
          });
          return (
            <div
              key={vItem.key}
              data-index={vItem.index}
              ref={virtualizer.measureElement}
              style={{ position: "absolute", top: 0, left: 0, right: 0, transform: `translateY(${vItem.start}px)` }}
              className={`flex items-center border-b border-white/[0.08] transition-colors ${isToday ? "bg-white/[0.06]" : "hover:bg-white/[0.03]"}`}
            >
              {/* Date column */}
              <div className="w-20 shrink-0 px-4 py-4">
                <div className="flex flex-col leading-none">
                  <span className="flex items-center gap-2">
                    <span className={`text-base font-semibold ${isToday ? "text-white" : "text-zinc-300"}`}>
                      {dayOfWeek}
                    </span>
                    {isToday && (
                      <span className="rounded-full bg-red-600 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-white">
                        Today
                      </span>
                    )}
                  </span>
                  <span className={`mt-1 text-xs ${isToday ? "text-white" : "text-zinc-300"}`}>{shortDate}</span>
                </div>
              </div>

              {/* Logos column */}
              <div className="flex-1 min-w-0 px-4 py-3">
                <div className="flex min-w-0 flex-wrap gap-2">
                  {dayRuns.map((run) => {
                    const hasImage = run.KennelLogo?.startsWith("https://");
                    const bg = run.PrimaryColor ?? "#dc2626";
                    const isSelected = selectedRun?.PublicEventId === run.PublicEventId;
                    return (
                      <button
                        key={run.PublicEventId}
                        onClick={() => onSelect(run)}
                        title={run.KennelName}
                        className={`flex-shrink-0 transition-all duration-150 hover:scale-105 ${isSelected ? "opacity-100" : "opacity-80 hover:opacity-100"}`}
                      >
                        {hasImage ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={run.KennelLogo!} alt={run.KennelName} className="h-12 w-12 object-contain" />
                        ) : (
                          <span
                            className="flex h-12 w-12 items-center justify-center rounded-lg text-lg font-bold text-white"
                            style={{ backgroundColor: bg }}
                          >
                            {run.KennelName.charAt(0).toUpperCase()}
                          </span>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Quarter bucket utilities ─────────────────────────────────────────────────

interface PastRunBucket {
  minEventDate: string;
  maxEventDate: string;
}

// Returns fixed calendar-quarter buckets back to 1990, most-recent first.
// Boundaries are stable — "Q1 2026" is always Jan 1–Apr 1 2026 regardless of
// when it is requested, so the Next.js fetch cache key never shifts.
// The loading loop stops early after 4 consecutive empty buckets so we don't
// walk all the way to 1990 if the club's records only go back a few years.
function getPastRunBuckets(): PastRunBucket[] {
  const now        = new Date();
  const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  let year    = now.getUTCFullYear();
  let quarter = Math.floor(now.getUTCMonth() / 3); // 0–3

  const buckets: PastRunBucket[] = [];

  while (year >= 1990) {
    const minDate = new Date(Date.UTC(year, quarter * 3, 1));

    let nextQ = quarter + 1;
    let nextY = year;
    if (nextQ > 3) { nextQ = 0; nextY++; }
    // Current quarter ends at today (partial); completed quarters end at next-quarter start.
    const maxDate = buckets.length === 0 ? todayStart : new Date(Date.UTC(nextY, nextQ * 3, 1));

    if (minDate < maxDate) {
      buckets.push({ minEventDate: minDate.toISOString(), maxEventDate: maxDate.toISOString() });
    }

    quarter--;
    if (quarter < 0) { quarter = 3; year--; }
  }

  return buckets;
}

// ─── Main component ───────────────────────────────────────────────────────────

interface GlobalRunsListProps {
  initialRuns: GlobalRunRow[];
  initialTotal: number;
}

export function GlobalRunsList({ initialRuns, initialTotal }: GlobalRunsListProps) {
  const router = useRouter();

  const [tab, setTab]                   = useState<"future" | "past">("future");
  const [view, setView]                 = useState<"list" | "calendar">("list");
  const [isPending, startTransition]    = useTransition();

  // Future runs — persisted across tab switches (pre-loaded from SSR).
  // Never reset on switch; switching back is instantaneous.
  const [futureRuns, setFutureRuns]       = useState<GlobalRunRow[]>(initialRuns);
  const [futureTotal, setFutureTotal]     = useState(initialTotal);
  const [futureOffset, setFutureOffset]   = useState(initialRuns.length);
  const [futureHasMore, setFutureHasMore] = useState(initialTotal > initialRuns.length);
  const [futureLoading, setFutureLoading] = useState(false);

  // Past runs — persisted across tab switches, loaded progressively on first visit.
  const [pastRuns, setPastRuns] = useState<GlobalRunRow[]>([]);
  const [pastDone, setPastDone] = useState(false);

  const [inputValue, setInputValue]   = useState("");
  const [query, setQuery]             = useState("");
  useEffect(() => {
    const t = setTimeout(() => startTransition(() => setQuery(inputValue)), 1000);
    return () => clearTimeout(t);
  }, [inputValue]); // startTransition is stable, intentionally omitted
  const [selectedRun, setSelectedRun] = useState<GlobalRunRow | null>(initialRuns[0] ?? null);
  const [detailView, setDetailView]   = useState<"detail" | "map">("detail");

  const listContainerRef = useRef<HTMLDivElement>(null);
  const cancelRef      = useRef(false);  // stops bucket loop on unmount
  const pastStartedRef = useRef(false);  // ensures bucket loading starts only once
  const tabRef         = useRef(tab);
  useEffect(() => { tabRef.current = tab; }, [tab]);
  useEffect(() => () => { cancelRef.current = true; }, []);

  // On mount: restore past runs from the module-level cache and restore tab from URL.
  // The cache holds whatever was loaded last — full or partial — so back-navigation
  // always shows something immediately even if the previous load was interrupted.
  useEffect(() => {
    if (_pastCache.runs.length > 0) {
      setPastRuns(_pastCache.runs);
      if (_pastCache.done) {
        setPastDone(true);
        pastStartedRef.current = true; // already complete — skip bucket loading
      }
      // If not done, pastStartedRef stays false so the [tab] effect restarts loading.
    }
    const urlTab = new URLSearchParams(window.location.search).get("tab");
    if (urlTab === "past") {
      setTab("past");
      setSelectedRun(_pastCache.runs[0] ?? null);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Derived — no shared mutable "runs" state to reset on switch.
  const runs = tab === "future" ? futureRuns : pastRuns;

  // ── Future runs: infinite scroll ──────────────────────────────────────────

  const loadMore = useCallback(async () => {
    if (tab !== "future" || futureLoading || !futureHasMore) return;
    setFutureLoading(true);
    const controller = new AbortController();
    const timeout    = setTimeout(() => controller.abort(), 15_000);
    try {
      const res = await fetch(
        `/api/global-runs?isFuture=1&pageSize=${PAGE_SIZE}&offset=${futureOffset}`,
        { signal: controller.signal }
      );
      if (!res.ok) throw new Error("Failed");
      const data: GetGlobalRunsResult = await res.json();
      setFutureRuns((prev) => [...prev, ...data.runs]);
      const newOffset = futureOffset + data.runs.length;
      setFutureOffset(newOffset);
      setFutureHasMore(newOffset < data.totalMatchingEvents);
    } catch {
      setFutureHasMore(false);
    } finally {
      clearTimeout(timeout);
      setFutureLoading(false);
    }
  }, [tab, futureLoading, futureHasMore, futureOffset]);


  // ── Tab switching ─────────────────────────────────────────────────────────
  // No data is fetched or reset here — both tab's runs live in persistent state.
  // Switching is immediate in both directions.

  const switchTab = useCallback((newTab: "future" | "past") => {
    if (newTab === tab) return;
    setTab(newTab);
    setInputValue("");
    setQuery("");
    setSelectedRun(newTab === "future" ? (futureRuns[0] ?? null) : (pastRuns[0] ?? null));

    // Keep URL in sync so the back button restores the correct tab.
    const params = new URLSearchParams(window.location.search);
    if (newTab === "future") params.delete("tab");
    else params.set("tab", newTab);
    const search = params.toString();
    window.history.replaceState(null, "", search ? `/?${search}` : "/");
  }, [tab, futureRuns, pastRuns]);

  // Bucket loading — starts whenever tab becomes "past" and hasn't started yet.
  // Lives here (not inside switchTab) so it also fires when the mount effect
  // restores tab="past" from the URL with no cached data.
  useEffect(() => {
    if (tab !== "past" || pastStartedRef.current) return;
    pastStartedRef.current = true;
    (async () => {
      const buckets = getPastRunBuckets();
      let allPastRuns: GlobalRunRow[] = [];
      try {
        const { minEventDate, maxEventDate } = buckets[0];
        const res = await fetch(
          `/api/global-runs?isFuture=0&minEventDate=${minEventDate}&maxEventDate=${maxEventDate}`
        );
        if (res.ok) {
          const data: GetGlobalRunsResult = await res.json();
          allPastRuns = data.runs;
          _pastCache.runs = allPastRuns;
          setPastRuns(data.runs);
          // Auto-select first run only if the user is still on the past tab
          // and hasn't manually selected anything.
          if (tabRef.current === "past" && data.runs.length > 0) {
            setSelectedRun((prev) => prev ?? data.runs[0]);
          }
        }
      } catch { /* degrade gracefully */ }

      let consecutiveEmpty = 0;
      for (let i = 1; i < buckets.length; i++) {
        if (cancelRef.current) return;
        const { minEventDate, maxEventDate } = buckets[i];
        try {
          const res = await fetch(
            `/api/global-runs?isFuture=0&minEventDate=${minEventDate}&maxEventDate=${maxEventDate}`
          );
          if (!res.ok || cancelRef.current) break;
          const data: GetGlobalRunsResult = await res.json();
          if (data.runs.length === 0) {
            // Stop after 4 consecutive empty quarters (1 year) — we've reached
            // the beginning of this club's recorded history.
            if (++consecutiveEmpty >= 4) break;
          } else {
            consecutiveEmpty = 0;
            allPastRuns = [...allPastRuns, ...data.runs];
            _pastCache.runs = allPastRuns;
            if (!cancelRef.current) setPastRuns(allPastRuns);
          }
        } catch { /* skip failed bucket, continue */ }
      }
      if (!cancelRef.current) {
        _pastCache.done = true;
        setPastDone(true);
      }
    })();
  }, [tab]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleViewChange = (newView: "list" | "calendar") => {
    setView(newView);
  };

  // ── Search filter ─────────────────────────────────────────────────────────

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) return runs;
    return runs.filter(
      (r) =>
        r.KennelName.toLowerCase().includes(q) ||
        r.KennelShortName.toLowerCase().includes(q) ||
        r.KennelSlug.toLowerCase().includes(q) ||
        r.EventName.toLowerCase().includes(q) ||
        String(r.EventNumber).includes(q) ||
        (r.LocationCity?.toLowerCase().includes(q) ?? false) ||
        (r.LocationCountry?.toLowerCase().includes(q) ?? false) ||
        (r.LocationRegion?.toLowerCase().includes(q) ?? false) ||
        (r.LocationOneLineDesc?.toLowerCase().includes(q) ?? false) ||
        (r.Hares?.toLowerCase().includes(q) ?? false) ||
        (r.EventDescription?.toLowerCase().includes(q) ?? false) ||
        (r.KennelContinent?.toLowerCase().includes(q) ?? false)
    );
  }, [runs, query]);

  // ── Virtual list ──────────────────────────────────────────────────────────
  // futureLoading adds a spinner row as the last virtual item so the user
  // sees feedback while the next page arrives.

  const virtualizerCount = filtered.length + (tab === "future" && futureLoading ? 1 : 0);

  const virtualizer = useVirtualizer({
    count: virtualizerCount,
    getScrollElement: () => listContainerRef.current,
    estimateSize: (i) => (i === filtered.length ? 52 : 108),
    overscan: 5,
  });

  // Trigger future-runs infinite scroll when the last rendered item is visible.
  const virtualItems       = virtualizer.getVirtualItems();
  const lastVirtualItem    = virtualItems[virtualItems.length - 1];
  useEffect(() => {
    if (!lastVirtualItem) return;
    if (lastVirtualItem.index >= filtered.length - 1 && tab === "future" && futureHasMore && !futureLoading) {
      loadMore();
    }
  }, [lastVirtualItem?.index, filtered.length, tab, futureHasMore, futureLoading, loadMore]);

  // ── Filter pending indicator ──────────────────────────────────────────────
  // True while the debounce is counting down OR while React is computing the
  // filtered list after the debounce fires (startTransition isPending).

  const isFiltering = inputValue !== query || isPending;

  // ── Run selection ─────────────────────────────────────────────────────────

  const handleSelect = (run: GlobalRunRow) => {
    if (typeof window !== "undefined" && window.innerWidth < 1024) {
      const backUrl = window.location.pathname + window.location.search;
      router.push(`/${run.KennelSlug}/${run.EventNumber}?back=${encodeURIComponent(backUrl)}`);
    } else {
      setSelectedRun(run);
    }
  };

  // ─────────────────────────────────────────────────────────────────────────

  const pastLoading  = tab === "past" && !pastDone;
  // Don't show "No runs found" while the first past bucket is still in flight.
  const pastStarting = tab === "past" && pastRuns.length === 0 && !pastDone;

  return (
    <div
      className="flex flex-col w-full min-w-0"
      style={{ height: "100svh" }}
    >
      {/* ── Panels row ────────────────────────────────────────────────────── */}
      <div className="flex flex-1 min-h-0 overflow-hidden">

      {/* ── Left panel ────────────────────────────────────────────────────── */}
      <div className="flex w-full shrink-0 flex-col overflow-hidden lg:w-[468px] lg:pb-3 bg-transparent">

        {/* Future / Past segmented control + view toggle */}
        <div className="px-3 pt-3 pb-2 shrink-0 flex items-center gap-2">
          <div className="flex flex-[2] rounded-full bg-zinc-300/75 p-1">
            {(["future", "past"] as const).map((t) => (
              <button
                key={t}
                onClick={() => switchTab(t)}
                className={[
                  "flex-1 py-1 rounded-full text-sm font-semibold transition-colors",
                  tab === t
                    ? "bg-red-600 text-white shadow-sm"
                    : "text-zinc-800 hover:text-zinc-950",
                ].join(" ")}
              >
                {t === "future" ? "Future" : "Past"}
              </button>
            ))}
          </div>
          <div className="flex flex-[3] rounded-full bg-zinc-300/75 p-1">
            <button
              onClick={() => handleViewChange("list")}
              className={`flex flex-1 items-center justify-center gap-1 py-1 rounded-full text-sm font-semibold transition-colors ${view === "list" ? "bg-red-600 text-white shadow-sm" : "text-zinc-800 hover:text-zinc-950"}`}
              aria-label="List view"
            >
              <LayoutList className="h-3.5 w-3.5" />
              List
            </button>
            <button
              onClick={() => handleViewChange("calendar")}
              className={`flex flex-1 items-center justify-center gap-1 py-1 rounded-full text-sm font-semibold transition-colors ${view === "calendar" ? "bg-red-600 text-white shadow-sm" : "text-zinc-800 hover:text-zinc-950"}`}
              aria-label="Calendar view"
            >
              <CalendarDays className="h-3.5 w-3.5" />
              <span>Cal<span className="hidden sm:inline">endar</span></span>
            </button>
          </div>
        </div>

        {/* Search */}
        <div className="px-3 pb-2.5 shrink-0">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-400 pointer-events-none" />
            <input
              type="search"
              placeholder="Search..."
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              className="w-full h-9 rounded-full border border-zinc-200 pl-9 pr-9 text-base sm:text-sm outline-none bg-white text-zinc-900 placeholder:text-zinc-400 focus:ring-1 focus:ring-zinc-300"
            />
            {inputValue && (
              <button
                onClick={() => { setInputValue(""); setQuery(""); }}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 flex h-5 w-5 items-center justify-center rounded-full bg-red-500"
                aria-label="Clear search"
              >
                <X className="h-3 w-3 text-white" />
              </button>
            )}
          </div>
          <div className="mt-2 flex items-center justify-center gap-2 px-1">
            <p className="text-sm font-medium text-white text-center">
              {filtered.length.toLocaleString()} {filtered.length === 1 ? "run" : "runs"}
              {query ? " found" : ""}
            </p>
            {(isFiltering || (pastLoading && pastRuns.length > 0)) && (
              <Loader2 className="h-3.5 w-3.5 animate-spin text-white/70 shrink-0" />
            )}
          </div>
        </div>

        {/* Calendar view — owns its own scroll container and virtualizer */}
        {view === "calendar" && (
          <CalendarView runs={filtered} selectedRun={selectedRun} onSelect={handleSelect} sortDesc={tab === "past"} />
        )}

        {/* List view */}
        {view === "list" && (
        <div ref={listContainerRef} className="flex-1 overflow-y-auto bg-transparent">
          {pastStarting ? (
            <div className="flex h-full items-center justify-center">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-zinc-300 border-t-zinc-600" />
            </div>
          ) : filtered.length === 0 && !futureLoading ? (
            <div className="py-16 text-center text-sm text-zinc-400">
              {query ? `No runs match "${query}"` : "No runs found"}
            </div>
          ) : (
            <div
              className="pt-3"
              style={{ height: virtualizer.getTotalSize(), position: "relative" }}
            >
              {virtualizer.getVirtualItems().map((vItem) => {
                // Spinner row appended while the next future-runs page is loading.
                if (vItem.index === filtered.length) {
                  return (
                    <div
                      key="loading"
                      style={{ position: "absolute", top: 0, left: 0, right: 0, transform: `translateY(${vItem.start}px)` }}
                      className="flex justify-center py-4"
                    >
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-zinc-300 border-t-zinc-600" />
                    </div>
                  );
                }
                const run = filtered[vItem.index];
                return (
                  <div
                    key={vItem.key}
                    data-index={vItem.index}
                    ref={virtualizer.measureElement}
                    style={{ position: "absolute", top: 0, left: 0, right: 0, transform: `translateY(${vItem.start}px)`, paddingLeft: "12px", paddingRight: "12px", paddingBottom: "8px" }}
                  >
                    <GlobalRunCard
                      run={run}
                      isSelected={selectedRun?.PublicEventId === run.PublicEventId}
                      onClick={() => handleSelect(run)}
                    />
                  </div>
                );
              })}
            </div>
          )}
        </div>
        )}

      </div>

      {/* ── Right panel: detail (desktop only) ───────────────────────────── */}
      <div className="max-lg:hidden min-w-0 flex-1 overflow-hidden pl-2 pr-4 py-3 flex flex-col gap-2">
        <div className="shrink-0">
          <div className="flex w-60 rounded-full bg-zinc-300/75 p-1">
            <button
              onClick={() => setDetailView("detail")}
              className={`flex flex-1 items-center justify-center gap-1 py-1 rounded-full text-sm font-semibold transition-colors ${detailView === "detail" ? "bg-red-600 text-white shadow-sm" : "text-zinc-800 hover:text-zinc-950"}`}
            >
              <Info className="h-3.5 w-3.5" />
              Detail
            </button>
            <button
              onClick={() => setDetailView("map")}
              className={`flex flex-1 items-center justify-center gap-1 py-1 rounded-full text-sm font-semibold transition-colors ${detailView === "map" ? "bg-red-600 text-white shadow-sm" : "text-zinc-800 hover:text-zinc-950"}`}
            >
              <MapIcon className="h-3.5 w-3.5" />
              Map
            </button>
          </div>
        </div>
        <div className="flex-1 min-h-0 rounded-xl border-[3px] border-white bg-white/[0.04] overflow-hidden flex flex-col">
          <div className="flex-1 overflow-hidden min-h-0">
            {selectedRun ? (
              detailView === "map"
                ? <RunLocationMap key={selectedRun.PublicEventId} run={selectedRun} />
                : <GlobalRunDetail key={selectedRun.PublicEventId} run={selectedRun} />
            ) : (
              <div className="h-full flex items-center justify-center">
                <div className="text-center">
                  <ArrowLeft className="h-16 w-16 text-white/30 mx-auto mb-4" />
                  <p className="text-2xl font-semibold text-white/50">
                    Select a run from the list to the left to see details
                  </p>
                </div>
              </div>
            )}
          </div>
          {/* Pinned scroll hint */}
          <div className="shrink-0 px-4 py-2 text-center border-t border-white/10">
            <p className="text-xs italic text-white/40">
              NOTE: To scroll the web page, move your cursor out of this scrollable box
            </p>
          </div>
        </div>
      </div>

      </div>{/* end panels row */}

      {/* ── Footer ────────────────────────────────────────────────────────── */}
      <div className="shrink-0 py-3 w-screen text-center">
        <p className="text-sm sm:text-lg md:text-2xl text-white/70">
          Powered by Harrier Central. Sign your Kennel up today at{" "}
          <a
            href="https://www.harriercentral.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="text-orange-400 hover:underline"
          >
            www.harriercentral.com
          </a>
        </p>
        <p className="text-sm italic text-white/40 mt-0.5">Version: 0.9.0</p>
      </div>
    </div>
  );
}
