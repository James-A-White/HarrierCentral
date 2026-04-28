"use client";

import { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  Search, X, Navigation, ExternalLink,
  ChevronRight, CalendarDays, Tag,
} from "lucide-react";
import { motion } from "framer-motion";
import type { RunEvent } from "@/lib/api";
import type { KennelContext } from "@/lib/types/kennel";

// ─── Helpers ──────────────────────────────────────────────────────────────────


function formatDate(iso: string) {
  const d = new Date(iso);
  return {
    short: d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", year: "numeric" }),
    long: d.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
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
  } catch { return null; }
}

function relativeTime(iso: string): string {
  const diffDays = Math.round((new Date(iso).getTime() - Date.now()) / 86_400_000);
  if (diffDays === 0) return "today";
  if (diffDays === 1) return "tomorrow";
  if (diffDays === -1) return "yesterday";
  if (diffDays > 0) return `in ${diffDays} days`;
  return `${Math.abs(diffDays)} days ago`;
}

// ─── Detail row ───────────────────────────────────────────────────────────────

function DetailRow({
  label, value, suppressHydration,
}: {
  label: string;
  value: React.ReactNode;
  suppressHydration?: boolean;
}) {
  return (
    <div className="flex gap-4 py-2.5 border-b dark:border-white/[0.06] border-zinc-100 last:border-0">
      <span className="w-28 shrink-0 text-xl dark:text-white/60 text-zinc-500 text-right leading-snug pt-0.5">
        {label}
      </span>
      <span
        className="flex-1 min-w-0 text-xl dark:text-white text-zinc-900 font-medium leading-snug"
        suppressHydrationWarning={suppressHydration}
      >
        {value}
      </span>
    </div>
  );
}

// ─── Run list item ────────────────────────────────────────────────────────────

function RunListItem({
  run, kennel, isSelected, onClick, index, isRestoring, showKennelBranding = true,
}: {
  run: RunEvent;
  kennel: KennelContext;
  isSelected: boolean;
  onClick: () => void;
  index: number;
  isRestoring: boolean;
  showKennelBranding?: boolean;
}) {
  const d = new Date(run.EventStartDatetime);
  const cardDate = d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
  const cardTime = d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  const rel = relativeTime(run.EventStartDatetime);

  const addressParts = [run.LocationStreet, run.LocationCity].filter(Boolean).join(", ");

  return (
    <motion.button
      className={`w-full text-left rounded-xl overflow-hidden border transition-all dark:bg-black/30 bg-white/30 ${
        isSelected
          ? "border-[var(--kennel-primary)] shadow-md"
          : "dark:border-white/60 border-zinc-600 dark:hover:border-white/80 hover:border-zinc-800"
      }`}
      onClick={onClick}
      initial={isRestoring ? false : { opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={isRestoring ? undefined : { duration: 0.25, delay: Math.min(index * 0.025, 0.4) }}
    >
      {/* Title row */}
      <div
        className="px-3 py-2"
        style={isSelected ? { backgroundColor: "color-mix(in srgb, var(--kennel-primary) 18%, transparent)" } : undefined}
      >
        <span className="text-sm font-semibold dark:text-white text-zinc-900 leading-snug">
          {run.EventName}
        </span>
      </div>

      {/* Hairline */}
      <div className="border-b dark:border-white/30 border-zinc-400" />

      {/* Run image — full width, natural aspect ratio */}
      {run.EventImage && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={run.EventImage} alt={run.EventName} className="w-full h-auto block" />
      )}

      {/* Body: logo + text column */}
      <div className="flex gap-3 px-3 py-2.5">
        {showKennelBranding && kennel.logoUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={kennel.logoUrl}
            alt={kennel.shortName}
            className="h-14 w-14 rounded-full object-contain shrink-0 self-center"
          />
        )}
        <div className="flex flex-col gap-0.5 min-w-0">
          {showKennelBranding && (
            <span className="text-sm font-bold leading-snug" style={{ color: "var(--kennel-primary)" }}>
              {kennel.name}
            </span>
          )}
          <span className="text-sm font-semibold dark:text-white text-zinc-900 leading-snug" suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ${rel}` : rel}
          </span>
          <span className="text-sm dark:text-white/60 text-zinc-500 leading-snug" suppressHydrationWarning>
            {cardDate} at {cardTime}
          </span>
          {addressParts && (
            <span className="text-sm dark:text-white/60 text-zinc-500 leading-snug">
              {addressParts}
            </span>
          )}
          {run.LocationOneLineDesc && (
            <span className="text-sm dark:text-white/60 text-zinc-500 leading-snug">
              Location: {run.LocationOneLineDesc}
            </span>
          )}
          {run.EventTypeName && (
            <span className="text-sm font-bold leading-snug" style={{ color: "var(--kennel-primary)" }}>
              {run.EventTypeName}
            </span>
          )}
        </div>
      </div>
    </motion.button>
  );
}

// ─── Run detail panel ─────────────────────────────────────────────────────────

function RunDetail({
  run, kennel, slug, backHref,
}: {
  run: RunEvent;
  kennel: KennelContext;
  slug: string;
  backHref: string;
}) {
  const { long: longDate, time } = formatDate(run.EventStartDatetime);
  const mapsLink = mapsUrl(run.Latitude, run.Longitude);
  const w3wLink = parseW3w(run.w3wJson);

  const locationParts = [
    run.LocationOneLineDesc,
    run.LocationStreet,
    run.LocationCity,
    run.LocationPostCode,
  ].filter(Boolean).join(", ");

  return (
    <motion.div
      key={run.PublicEventId}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.25 }}
      className="flex flex-col min-h-full"
    >
      {/* Hero image */}
      {run.EventImage && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={run.EventImage}
          alt={run.EventName}
          className="w-full h-auto block"
        />
      )}

      {/* Run title */}
      <div className="px-6 py-5 border-b dark:border-white/[0.08] border-zinc-200/50">
        <div className="flex items-start gap-4">
          {kennel.logoUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={kennel.logoUrl}
              alt={kennel.shortName}
              className="h-14 w-14 rounded-xl object-contain shrink-0 border dark:border-white/10 border-zinc-200 dark:bg-white/5 bg-white p-0.5"
            />
          )}
          <div className="min-w-0">
            <h2 className="text-3xl font-black dark:text-white text-zinc-900 leading-tight">
              {run.EventName}
            </h2>
            {run.IsCountedRun ? (
              <p className="mt-1 text-xl dark:text-white text-zinc-700">
                Run #{run.EventNumber}
              </p>
            ) : null}
          </div>
        </div>
      </div>

      {/* Details */}
      <div className="px-6 py-5 flex-1">
        <h3 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-3">
          Event details
        </h3>

        <div>
          <DetailRow label="Date" value={longDate} suppressHydration />
          <DetailRow label="Time" value={time} suppressHydration />
          {locationParts && <DetailRow label="Location" value={locationParts} />}
          {run.Hares && <DetailRow label="Hares" value={run.Hares} />}
          {run.EventTypeName && <DetailRow label="Event type" value={run.EventTypeName} />}
          {(run.EventPriceForMembers !== null || run.EventPriceForNonMembers !== null) && (
            <DetailRow
              label="Fees"
              value={
                <span>
                  {formatFee(run.EventPriceForMembers, run.EventCurrencyType)}{" "}
                  <span className="dark:text-white/60 text-zinc-500">members</span>
                  {run.EventPriceForNonMembers !== null && (
                    <>
                      {" · "}
                      {formatFee(run.EventPriceForNonMembers, run.EventCurrencyType)}{" "}
                      <span className="dark:text-white/60 text-zinc-500">non-members</span>
                    </>
                  )}
                </span>
              }
            />
          )}
        </div>

        {/* Tags */}
        {run.tags.length > 0 && (
          <div className="mt-4">
            <div className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-2 flex items-center gap-1.5">
              <Tag className="h-4 w-4" /> Tags
            </div>
            <div className="flex flex-wrap gap-2">
              {run.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full border px-3 py-1 text-xl dark:border-white/10 dark:bg-white/5 dark:text-white border-zinc-200 bg-zinc-50 text-zinc-900"
                >
                  {tag}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Description */}
        {run.EventDescription && (
          <p className="mt-4 text-xl leading-8 dark:text-white text-zinc-900 whitespace-pre-wrap">
            {run.EventDescription}
          </p>
        )}
      </div>

      {/* Action buttons */}
      <div className="px-6 pb-6 pt-2 flex flex-wrap gap-3 border-t dark:border-white/[0.08] border-zinc-200/50">
        {mapsLink && (
          <a
            href={mapsLink}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <Navigation className="h-4 w-4" />
            Open in Maps
          </a>
        )}
        {w3wLink && (
          <a
            href={w3wLink}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            What3Words
          </a>
        )}
        {run.EventUrl && (
          <a
            href={run.EventUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ExternalLink className="h-4 w-4" />
            Event page
          </a>
        )}
        <Link
          href={`/${slug}/${run.EventNumber}?back=${encodeURIComponent(backHref)}`}
          className="inline-flex items-center gap-2 rounded-full px-5 py-2.5 text-xl font-semibold transition-opacity hover:opacity-90"
          style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
        >
          Full details
          <ChevronRight className="h-4 w-4" />
        </Link>
      </div>
    </motion.div>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

interface RunsPageClientProps {
  futureRuns: RunEvent[];
  pastRuns: RunEvent[];
  kennel: KennelContext;
  slug: string;
}

const sessionKey = (slug: string) => `hc:runs:restore:${slug}`;

function getInitialRunsViewState(futureRuns: RunEvent[], pastRuns: RunEvent[], slug: string) {
  if (typeof window === "undefined") {
    return { tab: "future" as const, query: "", selectedRun: futureRuns[0] ?? pastRuns[0] ?? null, isRestoring: false };
  }

  // Back-navigation restore — written by handleSelect before navigating to the detail page.
  // sessionStorage survives Next.js's router which ignores window.history.replaceState calls.
  try {
    const raw = sessionStorage.getItem(sessionKey(slug));
    if (raw) {
      sessionStorage.removeItem(sessionKey(slug));
      const { run: runNum, tab: t, query: q } = JSON.parse(raw) as { run: number; tab: "future" | "past"; query: string };
      const sourceRuns = t === "past" ? pastRuns : futureRuns;
      const run = sourceRuns.find((r) => r.EventNumber === runNum) ?? null;
      if (run) return { tab: t, query: q ?? "", selectedRun: run, isRestoring: true };
    }
  } catch {}

  // URL-based state for deep links / shared URLs
  const params = new URLSearchParams(window.location.search);
  const tab: "future" | "past" = params.get("tab") === "past" ? "past" : "future";
  const query = params.get("q") ?? "";
  const sourceRuns = tab === "past" ? pastRuns : futureRuns;
  const runFromUrl = Number.parseInt(params.get("run") ?? "", 10);
  const isRestoring = !Number.isNaN(runFromUrl);
  const selectedRun = isRestoring
    ? sourceRuns.find((r) => r.EventNumber === runFromUrl) ?? sourceRuns[0] ?? null
    : sourceRuns[0] ?? null;

  return { tab, query, selectedRun, isRestoring };
}

export function RunsPageClient({ futureRuns, pastRuns, kennel, slug }: RunsPageClientProps) {
  const initialState = getInitialRunsViewState(futureRuns, pastRuns, slug);
  const router = useRouter();
  const [tab, setTab] = useState<"future" | "past">(initialState.tab);
  const [query, setQuery] = useState(initialState.query);
  const [isRestoring] = useState(initialState.isRestoring);
  const navTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [isEmbedded] = useState(
    () => typeof window !== "undefined" && window.self !== window.top
  );
  const [selectedRun, setSelectedRun] = useState<RunEvent | null>(initialState.selectedRun);
  const [panelHeight, setPanelHeight] = useState<string>("calc(100dvh - 80px)");

  useEffect(() => {
    if (!isEmbedded) return;
    document.documentElement.style.overflow = "hidden";
    document.body.style.overflow = "hidden";
    const update = () => setPanelHeight(`${window.innerHeight - 80}px`);
    update();
    window.addEventListener("resize", update);
    return () => {
      window.removeEventListener("resize", update);
      document.documentElement.style.overflow = "";
      document.body.style.overflow = "";
    };
  }, [isEmbedded]);

  const writeUrlState = (nextTab: "future" | "past", nextQuery: string, nextRun: RunEvent | null) => {
    const params = new URLSearchParams(window.location.search);

    if (nextTab === "past") params.set("tab", "past");
    else params.delete("tab");

    const q = nextQuery.trim();
    if (q) params.set("q", q);
    else params.delete("q");

    if (nextRun) params.set("run", String(nextRun.EventNumber));
    else params.delete("run");

    const search = params.toString();
    window.history.replaceState(null, "", `${window.location.pathname}${search ? `?${search}` : ""}`);
  };

  useEffect(() => {
    if (typeof window === "undefined") return;
    writeUrlState(tab, query, selectedRun);
  }, [tab, query, selectedRun]);

  const activeRuns = tab === "future" ? futureRuns : pastRuns;

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) return activeRuns;
    return activeRuns.filter(
      (r) =>
        r.EventName.toLowerCase().includes(q) ||
        String(r.EventNumber).includes(q) ||
        (r.LocationCity?.toLowerCase().includes(q) ?? false) ||
        (r.LocationOneLineDesc?.toLowerCase().includes(q) ?? false) ||
        (r.Hares?.toLowerCase().includes(q) ?? false)
    );
  }, [activeRuns, query]);

  const handleSelect = (run: RunEvent) => {
    setSelectedRun(run);
    if (typeof window !== "undefined" && window.innerWidth < 1024) {
      try {
        sessionStorage.setItem(sessionKey(slug), JSON.stringify({ run: run.EventNumber, tab, query }));
      } catch {}
      if (navTimeoutRef.current) clearTimeout(navTimeoutRef.current);
      navTimeoutRef.current = setTimeout(() => {
        router.push(`/${slug}/${run.EventNumber}?back=${encodeURIComponent(`/${slug}/runs`)}`);
      }, 250);
    }
  };

  const switchTab = (t: "future" | "past") => {
    setTab(t);
    setQuery("");
    setSelectedRun(t === "future" ? (futureRuns[0] ?? null) : (pastRuns[0] ?? null));
  };

  const backHref = useMemo(() => {
    const params = new URLSearchParams();
    if (tab === "past") params.set("tab", "past");
    const q = query.trim();
    if (q) params.set("q", q);
    if (selectedRun) params.set("run", String(selectedRun.EventNumber));
    const search = params.toString();
    return `/${slug}/runs${search ? `?${search}` : ""}`;
  }, [query, selectedRun, slug, tab]);

  return (
    <div
      className={`flex w-full min-w-0 min-h-0${isEmbedded ? " px-6 overflow-hidden" : ""}`}
      style={{ height: isEmbedded ? panelHeight : "calc(100dvh - 80px)" }}
    >

      {/* ── Left panel: list ────────────────────────────────────────────────── */}
      <div className="relative z-20 flex w-full min-w-0 min-h-0 shrink-0 flex-col lg:w-[420px] lg:border-r dark:border-white/[0.08] border-zinc-200/50">

        {/* Search */}
        <div className="px-4 py-3 border-b dark:border-white/[0.08] border-zinc-200/50 shrink-0">
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 dark:text-white/40 text-zinc-400 pointer-events-none" />
            <input
              type="search"
              placeholder="Search runs…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="w-full h-11 rounded-full border pl-10 pr-10 text-xl outline-none transition-colors dark:border-white/10 dark:bg-white/[0.06] dark:text-white dark:placeholder:text-white/50 focus:dark:ring-2 focus:dark:ring-white/20 border-zinc-200 bg-white/60 text-zinc-900 placeholder:text-zinc-400 focus:ring-2 focus:ring-zinc-300"
            />
            {query && (
              <button
                onClick={() => setQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 flex h-5 w-5 items-center justify-center rounded-full dark:bg-white/20 bg-zinc-200"
                aria-label="Clear search"
              >
                <X className="h-3 w-3 dark:text-white text-zinc-700" />
              </button>
            )}
          </div>
        </div>

        {/* Tabs */}
        <div className="flex shrink-0 border-b dark:border-white/[0.08] border-zinc-200/50">
          {(["future", "past"] as const).map((t) => (
            <button
              key={t}
              onClick={() => switchTab(t)}
              className={`flex-1 py-3 text-xl font-semibold transition-colors ${
                tab === t
                  ? "dark:text-white text-zinc-900"
                  : "dark:text-white/50 text-zinc-500 dark:hover:text-white/80 hover:text-zinc-700"
              }`}
            >
              <span>{t === "future" ? "Future" : "Past"}</span>
              <span
                className={`ml-2 text-base rounded-full px-2 py-0.5 ${
                  tab === t
                    ? "dark:bg-white/15 bg-zinc-200"
                    : "dark:bg-white/[0.06] bg-zinc-100"
                }`}
              >
                {(t === "future" ? futureRuns : pastRuns).length}
              </span>
              {tab === t && (
                <div
                  className="mt-1 mx-auto h-0.5 w-8 rounded-full"
                  style={{ backgroundColor: "var(--kennel-primary)" }}
                />
              )}
            </button>
          ))}
        </div>

        {/* Version — visible below tabs when embedded */}
        {isEmbedded && (
          <div className="shrink-0 pb-1 flex items-center justify-center">
            <span className="text-[10px] tabular-nums text-white/30">
              v{process.env.NEXT_PUBLIC_APP_VERSION}
            </span>
          </div>
        )}

        {/* Run list */}
        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
          {filtered.length === 0 ? (
            <div className="py-16 text-center text-xl dark:text-white/50 text-zinc-400">
              {query ? `No runs match "${query}"` : "No runs found"}
            </div>
          ) : (
            <div className="p-3 space-y-3">
              {filtered.map((run, i) => (
                <RunListItem
                  key={run.PublicEventId}
                  run={run}
                  kennel={kennel}
                  isSelected={selectedRun?.PublicEventId === run.PublicEventId}
                  onClick={() => handleSelect(run)}
                  index={i}
                  isRestoring={isRestoring}
                  showKennelBranding={false}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Right panel: detail (desktop only) ─────────────────────────────── */}
      <div className="relative z-10 hidden min-w-0 flex-1 overflow-y-auto lg:block">
        {selectedRun ? (
          <RunDetail run={selectedRun} kennel={kennel} slug={slug} backHref={backHref} />
        ) : (
          <div className="h-full flex items-center justify-center">
            <div className="text-center">
              <CalendarDays className="h-12 w-12 dark:text-white/20 text-zinc-300 mx-auto mb-3" />
              <p className="text-2xl dark:text-white/50 text-zinc-400">Select a run to see details</p>
            </div>
          </div>
        )}
      </div>

      {/* ── Version strip ───────────────────────────────────────────────────── */}
      {!isEmbedded && (
        <div className="fixed bottom-0 inset-x-0 h-5 flex items-center justify-center pointer-events-none z-50">
          <span className="text-[10px] tabular-nums text-white/30">
            v{process.env.NEXT_PUBLIC_APP_VERSION}
          </span>
        </div>
      )}
    </div>
  );
}
