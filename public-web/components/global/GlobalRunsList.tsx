"use client";

import { useState, useMemo, useCallback, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import QRCode from "react-qr-code";
import {
  Search, X, MapPin, Navigation, Tag, Copy, QrCode, ArrowLeft,
} from "lucide-react";
import type { GlobalRunRow, GetGlobalRunsResult } from "@/lib/api";

// ─── Constants ────────────────────────────────────────────────────────────────

const PAGE_SIZE = 50;
const HASHRUNS_ORIGIN = "https://hashruns.org";

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
  return {
    short: d.toLocaleDateString("en-GB", {
      weekday: "short",
      day: "numeric",
      month: "short",
      year: "numeric",
    }),
    long: d.toLocaleDateString("en-GB", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
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

function KennelLogo({ run, size = "sm" }: { run: GlobalRunRow; size?: "sm" | "md" }) {
  const hasImage = run.KennelLogo?.startsWith("https://");
  const bg = run.PrimaryColor ?? "#dc2626";
  const dim = size === "sm" ? "h-12 w-12" : "h-28 w-28";
  const text = size === "sm" ? "text-lg" : "text-3xl";

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
          className="absolute left-0 top-0 bottom-0 w-[9px] z-10"
          style={{ backgroundColor: primaryColor }}
        />
      )}

      {/* Bold title */}
      <div className="px-5 pt-2 pb-1.5">
        <p className="text-2xl font-bold text-zinc-900 leading-tight truncate">
          {run.EventName}
        </p>
      </div>

      {/* Hairline divider */}
      <hr className="border-zinc-200 mx-0" />

      {/* Content: logo + details */}
      <div className="flex items-start gap-4 px-5 py-2">
        <KennelLogo run={run} size="md" />

        <div className="min-w-0 flex-1">
          {/* Kennel name — primary colour, bold */}
          <p
            className="text-2xl font-bold leading-tight truncate"
            style={{ color: primaryColor }}
          >
            {run.KennelName}
          </p>

          {/* Run number + relative time — bold black */}
          <p className="text-xl font-bold text-zinc-900 leading-tight truncate" suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ` : ""}{rel}
          </p>

          {/* Date and time */}
          <p className="text-xl text-zinc-700 leading-tight truncate" suppressHydrationWarning>
            {short} at {time}
          </p>

          {/* City, Country */}
          {location && (
            <p className="text-xl text-zinc-700 leading-tight truncate">{location}</p>
          )}

          {/* Venue */}
          {run.LocationOneLineDesc && (
            <p className="text-xl text-zinc-700 leading-tight truncate">
              Location: {run.LocationOneLineDesc}
            </p>
          )}
        </div>
      </div>
    </button>
  );
}

// ─── Detail row ───────────────────────────────────────────────────────────────

function DetailRow({
  label,
  value,
  suppressHydration,
}: {
  label: string;
  value: React.ReactNode;
  suppressHydration?: boolean;
}) {
  return (
    <div className="flex gap-4 py-2 border-b border-white/[0.08] last:border-0">
      <span className="w-24 shrink-0 text-sm text-white/60 text-right leading-snug pt-0.5">
        {label}
      </span>
      <span
        className="flex-1 min-w-0 text-sm text-white font-medium leading-snug"
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
            <p className="text-xs font-semibold text-center text-white/80">{label}</p>
            <div className="p-2 bg-white rounded-lg">
              <QRCode value={url} {...qrProps} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Action button ────────────────────────────────────────────────────────────

function ActionBtn({
  onClick,
  href,
  children,
  active,
}: {
  onClick?: () => void;
  href?: string;
  children: React.ReactNode;
  active?: boolean;
}) {
  const cls = [
    "inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-semibold transition-colors",
    active
      ? "border-white/30 bg-white/20 text-white"
      : "border-white/15 bg-white/[0.08] text-white hover:bg-white/[0.14]",
  ].join(" ");

  if (href)
    return <a href={href} target="_blank" rel="noopener noreferrer" className={cls}>{children}</a>;
  return <button onClick={onClick} className={cls}>{children}</button>;
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
  const bg       = run.PrimaryColor ?? "#dc2626";

  useEffect(() => { setShowQr(false); setCopied(false); }, [run.PublicEventId]);

  const handleCopy = () => {
    navigator.clipboard.writeText(runUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className="flex flex-col overflow-y-auto h-full">
      {/* Header: kennel logo + name + event name */}
      <div
        className="flex items-center gap-3 px-5 py-4 border-b border-white/[0.08] shrink-0"
        style={{ borderLeftColor: bg, borderLeftWidth: 4 }}
      >
        <KennelLogo run={run} size="md" />
        <div className="min-w-0">
          <h2 className="text-base font-bold text-white leading-tight truncate">
            {run.KennelName}
          </h2>
          <p className="text-sm text-white/60 truncate">{run.EventName}</p>
        </div>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto">
        {/* Event details */}
        <div className="px-5 py-4">
          {run.IsCountedRun && (
            <DetailRow label="Run #" value={String(run.EventNumber)} />
          )}
          <DetailRow label="Date" value={longDate} suppressHydration />
          <DetailRow label="Time" value={time} suppressHydration />
          {run.LocationOneLineDesc && (
            <DetailRow label="Place" value={run.LocationOneLineDesc} />
          )}
          {run.LocationStreet && (
            <DetailRow label="Street" value={run.LocationStreet} />
          )}
          {run.LocationCity && (
            <DetailRow label="City" value={run.LocationCity} />
          )}
          {run.LocationRegion && (
            <DetailRow label="Region" value={run.LocationRegion} />
          )}
          {run.LocationCountry && (
            <DetailRow label="Country" value={run.LocationCountry} />
          )}
          {run.EventTypeName && (
            <DetailRow label="Event type" value={run.EventTypeName} />
          )}
          {(run.EventPriceForMembers !== null || run.EventPriceForNonMembers !== null) && (
            <DetailRow
              label="Fees"
              value={
                <span>
                  {formatFee(run.EventPriceForMembers, run.EventCurrencyType)}{" "}
                  <span className="text-white/60">members</span>
                  {run.EventPriceForNonMembers !== null && (
                    <>
                      {" · "}
                      {formatFee(run.EventPriceForNonMembers, run.EventCurrencyType)}{" "}
                      <span className="text-white/60">non-members</span>
                    </>
                  )}
                </span>
              }
            />
          )}
          {run.Hares && <DetailRow label="Hares" value={run.Hares} />}
        </div>

        {/* Action buttons */}
        <div className="px-5 pb-4 flex flex-wrap gap-2 border-t border-white/[0.08] pt-4">
          {mapsLink && (
            <ActionBtn href={mapsLink}>
              <Navigation className="h-3.5 w-3.5" />
              Map
            </ActionBtn>
          )}
          {w3wLink && (
            <ActionBtn href={w3wLink}>
              <MapPin className="h-3.5 w-3.5" />
              W3W
            </ActionBtn>
          )}
          <ActionBtn onClick={handleCopy}>
            <Copy className="h-3.5 w-3.5" />
            {copied ? "Copied!" : "Copy link"}
          </ActionBtn>
          <ActionBtn onClick={() => setShowQr((v) => !v)} active={showQr}>
            <QrCode className="h-3.5 w-3.5" />
            {showQr ? "Hide QR" : "Show QR"}
          </ActionBtn>
          {siteUrl && (
            <ActionBtn href={siteUrl}>
              {run.KennelName} website
            </ActionBtn>
          )}
        </div>

        {/* QR section */}
        {showQr && <QRSection run={run} />}

        {/* Tags */}
        {run.tags.length > 0 && (
          <div className="px-5 pb-4 border-t border-white/[0.08] pt-4">
            <div className="flex items-center gap-1.5 text-xs uppercase tracking-widest text-white/60 mb-2">
              <Tag className="h-3 w-3" /> Tags
            </div>
            <div className="flex flex-wrap gap-2">
              {run.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full border border-white/15 bg-white/[0.08] px-3 py-1 text-xs text-white"
                >
                  {tag}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Description */}
        {run.EventDescription && (
          <div className="px-5 pb-6 border-t border-white/[0.08] pt-4">
            <p className="text-sm leading-6 text-white/80 whitespace-pre-wrap">
              {run.EventDescription}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

interface GlobalRunsListProps {
  initialRuns: GlobalRunRow[];
  initialTotal: number;
}

export function GlobalRunsList({ initialRuns, initialTotal }: GlobalRunsListProps) {
  const router = useRouter();

  const [tab, setTab]           = useState<"future" | "past">("future");
  const [runs, setRuns]         = useState<GlobalRunRow[]>(initialRuns);
  const [total, setTotal]       = useState(initialTotal);
  const [offset, setOffset]     = useState(initialRuns.length);
  const [hasMore, setHasMore]   = useState(initialTotal > initialRuns.length);
  const [loading, setLoading]   = useState(false);
  const [query, setQuery]       = useState("");
  const [selectedRun, setSelectedRun] = useState<GlobalRunRow | null>(
    initialRuns[0] ?? null
  );

  const sentinelRef = useRef<HTMLDivElement>(null);

  // ── Pagination ───────────────────────────────────────────────────────────────

  const loadMore = useCallback(async () => {
    if (loading || !hasMore) return;
    setLoading(true);
    try {
      const res = await fetch(
        `/api/global-runs?isFuture=${tab === "future" ? "1" : "0"}&pageSize=${PAGE_SIZE}&offset=${offset}`
      );
      if (!res.ok) throw new Error("Failed");
      const data: GetGlobalRunsResult = await res.json();
      setRuns((prev) => [...prev, ...data.runs]);
      setOffset((prev) => prev + data.runs.length);
      setHasMore(offset + data.runs.length < data.totalMatchingEvents);
    } catch { /* silently retry on next scroll */ }
    finally { setLoading(false); }
  }, [loading, hasMore, tab, offset]);

  useEffect(() => {
    const sentinel = sentinelRef.current;
    if (!sentinel || !hasMore) return;
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) loadMore(); },
      { rootMargin: "400px" }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [loadMore, hasMore]);

  // ── Tab switching ────────────────────────────────────────────────────────────

  const switchTab = useCallback(async (newTab: "future" | "past") => {
    if (newTab === tab) return;
    setTab(newTab);
    setQuery("");
    setSelectedRun(null);
    setRuns([]);
    setOffset(0);
    setHasMore(true);
    setTotal(0);
    setLoading(true);
    try {
      const res = await fetch(
        `/api/global-runs?isFuture=${newTab === "future" ? "1" : "0"}&pageSize=${PAGE_SIZE}&offset=0`
      );
      if (!res.ok) throw new Error("Failed");
      const data: GetGlobalRunsResult = await res.json();
      setRuns(data.runs);
      setTotal(data.totalMatchingEvents);
      setOffset(data.runs.length);
      setHasMore(data.totalMatchingEvents > data.runs.length);
      setSelectedRun(data.runs[0] ?? null);
    } catch { /* leave list empty */ }
    finally { setLoading(false); }
  }, [tab]);

  // ── Search filter ────────────────────────────────────────────────────────────

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) return runs;
    return runs.filter(
      (r) =>
        r.KennelName.toLowerCase().includes(q) ||
        r.EventName.toLowerCase().includes(q) ||
        String(r.EventNumber).includes(q) ||
        (r.LocationCity?.toLowerCase().includes(q) ?? false) ||
        (r.LocationCountry?.toLowerCase().includes(q) ?? false) ||
        (r.LocationOneLineDesc?.toLowerCase().includes(q) ?? false)
    );
  }, [runs, query]);

  // ── Run selection ────────────────────────────────────────────────────────────

  const handleSelect = (run: GlobalRunRow) => {
    if (typeof window !== "undefined" && window.innerWidth < 1024) {
      router.push(`/${run.KennelSlug}/${run.EventNumber}`);
    } else {
      setSelectedRun(run);
    }
  };

  // ─────────────────────────────────────────────────────────────────────────────

  return (
    <div
      className="flex w-full min-w-0 overflow-hidden"
      style={{ height: "calc(100svh - 56px)" }}
    >
      {/* ── Left panel ────────────────────────────────────────────────────── */}
      <div className="flex w-full shrink-0 flex-col overflow-hidden lg:w-[560px]">

        {/* Search */}
        <div className="px-3 py-2.5 shrink-0">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-400 pointer-events-none" />
            <input
              type="search"
              placeholder="Search..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full h-9 rounded-full border border-zinc-200 pl-9 pr-9 text-sm outline-none bg-white text-zinc-900 placeholder:text-zinc-400 focus:ring-1 focus:ring-zinc-300"
            />
            {query && (
              <button
                onClick={() => setQuery("")}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 flex h-5 w-5 items-center justify-center rounded-full bg-red-500"
                aria-label="Clear search"
              >
                <X className="h-3 w-3 text-white" />
              </button>
            )}
          </div>
        </div>

        {/* Future / Past segmented control */}
        <div className="px-3 py-3 shrink-0">
          <div className="flex rounded-full bg-zinc-300/75 p-1.5">
            {(["future", "past"] as const).map((t) => (
              <button
                key={t}
                onClick={() => switchTab(t)}
                className={[
                  "flex-1 py-4 rounded-full text-2xl font-semibold transition-colors",
                  tab === t
                    ? "bg-red-600 text-white shadow-sm"
                    : "text-zinc-800 hover:text-zinc-950",
                ].join(" ")}
              >
                {t === "future" ? "Future Runs" : "Past Runs"}
              </button>
            ))}
          </div>
        </div>

        {/* Run list */}
        <div className="flex-1 overflow-y-auto">
          {filtered.length === 0 && !loading ? (
            <div className="py-16 text-center text-sm text-zinc-400">
              {query ? `No runs match "${query}"` : "No runs found"}
            </div>
          ) : (
            <>
              {/* Padding here (not on cards) gives each card a proper w-full within a constrained container */}
              <div className="px-1 pt-3 pb-3 flex flex-col gap-4">
                {filtered.map((run) => (
                  <GlobalRunCard
                    key={run.PublicEventId}
                    run={run}
                    isSelected={selectedRun?.PublicEventId === run.PublicEventId}
                    onClick={() => handleSelect(run)}
                  />
                ))}
              </div>

              {/* Infinite scroll sentinel — outside the flex col so gap doesn't affect it */}
              <div ref={sentinelRef} className="flex justify-center py-4">
                {loading && (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-zinc-300 border-t-zinc-600" />
                )}
                {!hasMore && runs.length > 0 && (
                  <p className="text-xs text-zinc-400">{total.toLocaleString()} runs</p>
                )}
              </div>
            </>
          )}
        </div>
      </div>

      {/* ── Right panel: detail (desktop only) ───────────────────────────── */}
      <div className="max-lg:hidden min-w-0 flex-1 flex flex-col overflow-hidden">
        {selectedRun ? (
          <GlobalRunDetail key={selectedRun.PublicEventId} run={selectedRun} />
        ) : (
          <div className="h-full flex items-center justify-center">
            <div className="text-center">
              <ArrowLeft className="h-8 w-8 text-white/30 mx-auto mb-3" />
              <p className="text-lg text-white/50">
                Select a run from the list to the left to see details
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
