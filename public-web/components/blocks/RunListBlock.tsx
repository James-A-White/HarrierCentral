"use client";

import { useEffect, useState } from "react";
import { useKennelData } from "@/components/puck/KennelDataContext";
import { toKennelContext } from "@/lib/kennel-utils";
import type { RunEvent, MultiKennelRunEvent } from "@/lib/api";
import { RunCardView } from "./RunCardView";
import { RunCalendarView } from "./RunCalendarView";

// ── Shared types (exported for view components) ───────────────────────────────

export interface KennelMeta {
  slug: string;
  name: string;
  shortName: string;
  logo: string | null;
  primaryColor: string | null;
  accentColor: string | null;
  ianaTimezone: string | null;
}

export interface EnrichedRun {
  event: RunEvent;
  kennel: KennelMeta;
}

/** Resolved display flags passed to each view component. */
export interface DisplayOptions {
  showRunNumber: boolean;
  showRunName: boolean;
  showDate: boolean;
  showTime: boolean;
  showLocation: boolean;
  showHares: boolean;
  showImage: boolean;
  showKennelLogo: boolean;
  kennelLogoSize: string;
  showKennelName: boolean;
  nameColor: string;
  detailColor: string;
  showDivider: boolean;
  dividerColor: string;
  dividerWidth: number;
  isCustomDomain: boolean;
}

// ── Block props ───────────────────────────────────────────────────────────────

interface RunListBlockProps {
  viewType?: string;
  isFuture?: boolean;
  skipNextRun?: boolean;
  eventsOnly?: boolean;
  showEmptyDays?: boolean;
  count?: number;
  days?: number;
  otherKennelSlugs?: string;
  // Display toggles
  showRunNumber?: boolean;
  showRunName?: boolean;
  showDate?: boolean;
  showTime?: boolean;
  showLocation?: boolean;
  showHares?: boolean;
  showImage?: boolean;
  // Tri-state: "always" | "multi" | "never"
  kennelLogoDisplay?: string;
  kennelLogoSize?: string;
  kennelNameDisplay?: string;
  nameColor?: string;
  detailColor?: string;
  showDivider?: boolean;
  dividerColor?: string;
  dividerWidth?: number;
  scrollContainer?: boolean;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function getEventDatetimeMs(event: RunEvent): number {
  const gmt = event.EventStartDatetimeGmt;
  return gmt ? new Date(gmt).getTime() : new Date(event.EventStartDatetime).getTime();
}

function isWithinDays(event: RunEvent, days: number, isFuture: boolean): boolean {
  if (days <= 0) return true;
  const nowMs    = Date.now();
  const eventMs  = getEventDatetimeMs(event);
  const windowMs = days * 24 * 60 * 60 * 1000;
  return isFuture
    ? eventMs <= nowMs + windowMs
    : eventMs >= nowMs - windowMs;
}

function buildKennelMeta(
  slug: string, name: string, shortName: string,
  logo: string | null, primaryColor: string | null,
  accentColor: string | null, ianaTimezone: string | null
): KennelMeta {
  return { slug, name, shortName, logo, primaryColor, accentColor, ianaTimezone };
}

function resolveTriState(setting: string, isMultiKennel: boolean): boolean {
  if (setting === "always") return true;
  if (setting === "never")  return false;
  return isMultiKennel; // "multi"
}

// ── Component ─────────────────────────────────────────────────────────────────

export function RunListBlock({
  viewType          = "card",
  isFuture          = true,
  skipNextRun       = true,
  eventsOnly        = false,
  showEmptyDays     = false,
  count             = 0,
  days              = 0,
  otherKennelSlugs  = "",
  showRunNumber     = true,
  showRunName       = true,
  showDate          = true,
  showTime          = true,
  showLocation      = true,
  showHares         = true,
  showImage         = false,
  kennelLogoDisplay = "multi",
  kennelLogoSize    = "md",
  kennelNameDisplay = "multi",
  nameColor         = "",
  detailColor       = "",
  showDivider       = false,
  dividerColor      = "",
  dividerWidth      = 1,
  scrollContainer   = false,
}: RunListBlockProps) {
  const { futureRuns, pastRuns, kennelData, slug, isCustomDomain = false } = useKennelData();
  const kennel = toKennelContext(kennelData);

  const [otherRuns, setOtherRuns] = useState<MultiKennelRunEvent[]>([]);
  const [loadingOther, setLoadingOther] = useState(false);

  const slugsTrimmed = otherKennelSlugs.trim();

  useEffect(() => {
    if (!slugsTrimmed) {
      setOtherRuns([]);
      return;
    }

    setLoadingOther(true);
    const params = new URLSearchParams({
      slugs:    slugsTrimmed,
      isFuture: isFuture ? "1" : "0",
    });
    if (days > 0) params.set("daysOffset", String(days));

    fetch(`/api/runs/multi-kennel?${params}`)
      .then((r) => r.json())
      .then((data: { events?: MultiKennelRunEvent[] }) => setOtherRuns(data.events ?? []))
      .catch(() => setOtherRuns([]))
      .finally(() => setLoadingOther(false));
  }, [slugsTrimmed, isFuture, days]);

  // ── Primary kennel runs ───────────────────────────────────────────────────

  const primaryMeta = buildKennelMeta(
    slug, kennel.name, kennel.shortName ?? kennel.name,
    kennel.logoUrl ?? null, kennel.primaryColor, kennel.accentColor ?? null, null
  );

  let baseRuns = isFuture ? futureRuns : pastRuns;
  if (isFuture && skipNextRun) baseRuns = baseRuns.slice(1);

  const filteredPrimary = days > 0
    ? baseRuns.filter((r) => isWithinDays(r, days, isFuture))
    : baseRuns;

  const primaryEnriched: EnrichedRun[] = filteredPrimary.map((r) => ({
    event: r, kennel: primaryMeta,
  }));

  // ── Other kennel runs ─────────────────────────────────────────────────────

  const otherEnriched: EnrichedRun[] = otherRuns.map((r) => ({
    event: r,
    kennel: buildKennelMeta(
      r.KennelSlug, r.KennelName, r.KennelShortName,
      r.KennelLogo, r.KennelPrimaryColor, r.KennelAccentColor, r.KennelIANATimezone ?? null
    ),
  }));

  // ── Merge, deduplicate, sort ──────────────────────────────────────────────

  const seen = new Set<string>();
  const merged: EnrichedRun[] = [];
  for (const entry of [...primaryEnriched, ...otherEnriched]) {
    if (!seen.has(entry.event.PublicEventId)) {
      seen.add(entry.event.PublicEventId);
      merged.push(entry);
    }
  }

  merged.sort((a, b) => {
    const aMs = getEventDatetimeMs(a.event);
    const bMs = getEventDatetimeMs(b.event);
    return isFuture ? aMs - bMs : bMs - aMs;
  });

  const sliced = count > 0 ? merged.slice(0, count) : merged;
  const runs = eventsOnly ? sliced.filter((r) => r.event.IsPromotedEvent === 1) : sliced;

  // ── Resolve display options ───────────────────────────────────────────────

  const isMultiKennel = new Set(runs.map((r) => r.kennel.slug)).size > 1;

  const display: DisplayOptions = {
    showRunNumber,
    showRunName,
    showDate,
    showTime,
    showLocation,
    showHares,
    showImage,
    showKennelLogo: resolveTriState(kennelLogoDisplay, isMultiKennel),
    kennelLogoSize,
    showKennelName: resolveTriState(kennelNameDisplay, isMultiKennel),
    nameColor:    nameColor    || "var(--kennel-text-title)",
    detailColor:  detailColor  || "var(--kennel-text-body)",
    showDivider,
    dividerColor: dividerColor || "color-mix(in srgb, var(--kennel-text-muted) 30%, transparent)",
    dividerWidth,
    isCustomDomain,
  };

  // ── Render ────────────────────────────────────────────────────────────────

  if (loadingOther) {
    return (
      <div className="py-8 text-center text-sm" style={{ color: "var(--kennel-text-muted)" }}>
        Loading runs…
      </div>
    );
  }

  const view = viewType === "calendar"
    ? (
      <RunCalendarView
        runs={runs}
        slug={slug}
        isFuture={isFuture}
        showEmptyDays={showEmptyDays}
        days={days}
        display={display}
      />
    ) : (
      <RunCardView flat={viewType === "flat"} runs={runs} slug={slug} display={display} />
    );

  if (!scrollContainer) return view;

  return (
    <div className="md:overflow-y-auto md:max-h-[calc(100svh-200px)] md:pr-1">
      {view}
    </div>
  );
}
