"use client";

import { useState, useMemo, useEffect } from "react";
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
  run, isSelected, onClick, index,
}: {
  run: RunEvent;
  isSelected: boolean;
  onClick: () => void;
  index: number;
}) {
  const { short, time } = formatDate(run.EventStartDatetime);

  return (
    <motion.button
      className={`w-full text-left rounded-2xl overflow-hidden border transition-all dark:bg-white/25 bg-black/25 ${
        isSelected
          ? "border-transparent shadow-lg"
          : "dark:border-white/[0.08] border-zinc-200 dark:hover:border-white/[0.14] hover:border-zinc-300"
      }`}
      onClick={onClick}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.25, delay: Math.min(index * 0.025, 0.4) }}
    >
      {/* Image — full natural aspect ratio */}
      {run.EventImage && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={run.EventImage}
          alt={run.EventName}
          className="w-full h-auto block"
        />
      )}

      {/* Caption: title + date/time on one line */}
      <div
        className="flex min-w-0 items-center gap-2 px-3 py-2"
        style={isSelected ? { backgroundColor: "var(--kennel-primary)" } : undefined}
      >
        <span
          className={`min-w-0 flex-1 text-sm font-semibold truncate ${
            isSelected ? "text-white" : "dark:text-white text-zinc-900"
          }`}
        >
          {run.EventName}
          {run.IsCountedRun ? (
            <span className={`ml-1.5 font-normal ${isSelected ? "text-white/70" : "dark:text-white/50 text-zinc-500"}`}>
              #{run.EventNumber}
            </span>
          ) : null}
        </span>
        <span
          className={`shrink-0 text-xs whitespace-nowrap ${
            isSelected ? "text-white/80" : "dark:text-white/60 text-zinc-500"
          }`}
          suppressHydrationWarning
        >
          {short} · {time}
        </span>
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
            /// What3Words
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

export function RunsPageClient({ futureRuns, pastRuns, kennel, slug }: RunsPageClientProps) {
  const router = useRouter();
  const [tab, setTab] = useState<"future" | "past">("future");
  const [query, setQuery] = useState("");
  const [selectedRun, setSelectedRun] = useState<RunEvent | null>(
    futureRuns[0] ?? pastRuns[0] ?? null
  );

  // Restore tab from URL on mount so the back button returns to the correct tab.
  useEffect(() => {
    const urlTab = new URLSearchParams(window.location.search).get("tab");
    if (urlTab === "past") {
      setTab("past");
      setSelectedRun(pastRuns[0] ?? null);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

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
    if (typeof window !== "undefined" && window.innerWidth < 1024) {
      const backUrl = window.location.pathname + window.location.search;
      router.push(`/${slug}/${run.EventNumber}?back=${encodeURIComponent(backUrl)}`);
    } else {
      setSelectedRun(run);
    }
  };

  const switchTab = (t: "future" | "past") => {
    setTab(t);
    setQuery("");
    setSelectedRun(t === "future" ? (futureRuns[0] ?? null) : (pastRuns[0] ?? null));
    const params = new URLSearchParams(window.location.search);
    if (t === "future") params.delete("tab");
    else params.set("tab", t);
    const search = params.toString();
    window.history.replaceState(null, "", window.location.pathname + (search ? `?${search}` : ""));
  };

  return (
    <div className="flex w-full min-w-0 overflow-hidden" style={{ height: "calc(100svh - 80px)" }}>

      {/* ── Left panel: list ────────────────────────────────────────────────── */}
      <div className="flex w-full min-w-0 shrink-0 flex-col overflow-hidden lg:w-[420px] lg:border-r dark:border-white/[0.08] border-zinc-200/50">

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

        {/* Run list */}
        <div className="flex-1 overflow-y-auto">
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
                  isSelected={selectedRun?.PublicEventId === run.PublicEventId}
                  onClick={() => handleSelect(run)}
                  index={i}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── Right panel: detail (desktop only) ─────────────────────────────── */}
      <div className="hidden min-w-0 flex-1 overflow-y-auto lg:block">
        {selectedRun ? (
          <RunDetail run={selectedRun} kennel={kennel} slug={slug} backHref={`/${slug}/runs${tab === "past" ? "?tab=past" : ""}`} />
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
      <div className="fixed bottom-0 inset-x-0 h-5 flex items-center justify-center pointer-events-none z-50">
        <span className="text-[10px] tabular-nums text-white/30">
          v{process.env.NEXT_PUBLIC_APP_VERSION}
        </span>
      </div>
    </div>
  );
}
