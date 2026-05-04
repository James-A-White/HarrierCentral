"use client";

import { useState, useMemo, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  Search, X, ChevronRight, CalendarDays,
} from "lucide-react";
import { motion } from "framer-motion";
import type { RunEvent } from "@/lib/api";
import type { KennelContext } from "@/lib/types/kennel";
import { RunDetail } from "./RunDetail";

// ─── Helpers ──────────────────────────────────────────────────────────────────

function relativeTime(iso: string): string {
  const diffDays = Math.round((new Date(iso).getTime() - Date.now()) / 86_400_000);
  if (diffDays === 0) return "today";
  if (diffDays === 1) return "tomorrow";
  if (diffDays === -1) return "yesterday";
  if (diffDays > 0) return `in ${diffDays} days`;
  return `${Math.abs(diffDays)} days ago`;
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
  const gmt = run.EventStartDatetimeGmt;
  const tz  = run.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  const cardDate = src.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", timeZone: displayTz });
  const cardTime = src.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", timeZone: displayTz });
  const rel = relativeTime(gmt ?? run.EventStartDatetime);

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
        <span className="text-sm font-semibold leading-snug" style={{ color: "var(--kennel-text-body)" }}>
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
          <span className="text-sm font-semibold leading-snug" style={{ color: "var(--kennel-text-body)" }} suppressHydrationWarning>
            {run.IsCountedRun ? `Run #${run.EventNumber}, ${rel}` : rel}
          </span>
          <span className="text-sm leading-snug" style={{ color: "var(--kennel-text-muted)" }} suppressHydrationWarning>
            {cardDate} at {cardTime}
          </span>
          {addressParts && (
            <span className="text-sm leading-snug" style={{ color: "var(--kennel-text-muted)" }}>
              {addressParts}
            </span>
          )}
          {run.LocationOneLineDesc && (
            <span className="text-sm leading-snug" style={{ color: "var(--kennel-text-muted)" }}>
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
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-5 w-5 pointer-events-none" style={{ color: "var(--kennel-text-muted)" }} />
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
                <X className="h-3 w-3" style={{ color: "var(--kennel-text-body)" }} />
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
              className="flex-1 py-3 text-xl font-semibold transition-colors"
              style={{ color: tab === t ? "var(--kennel-text-body)" : "var(--kennel-text-muted)" }}
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
            <div className="py-16 text-center text-xl" style={{ color: "var(--kennel-text-muted)" }}>
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
          <motion.div
            key={selectedRun.PublicEventId}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.25 }}
          >
            {selectedRun.EventImage && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={selectedRun.EventImage} alt={selectedRun.EventName} className="w-full h-auto block" />
            )}
            <div className="p-5">
              <RunDetail run={selectedRun} kennel={kennel} canonicalPath={`/${slug}/${selectedRun.EventNumber}`} />
            </div>
            <div className="px-5 pb-5 flex justify-end border-t border-white/[0.08]">
              <Link
                href={`/${slug}/${selectedRun.EventNumber}?back=${encodeURIComponent(backHref)}`}
                className="inline-flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-semibold transition-opacity hover:opacity-90"
                style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
              >
                Full details
                <ChevronRight className="h-3.5 w-3.5" />
              </Link>
            </div>
          </motion.div>
        ) : (
          <div className="h-full flex items-center justify-center">
            <div className="text-center">
              <CalendarDays className="h-12 w-12 mx-auto mb-3" style={{ color: "var(--kennel-text-muted)" }} />
              <p className="text-2xl" style={{ color: "var(--kennel-text-muted)" }}>Select a run to see details</p>
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
