"use client";

import { useEffect } from "react";
import Link from "next/link";
import { X, MapPin, Clock, Users, Tag, Navigation, ExternalLink } from "lucide-react";
import { motion } from "framer-motion";
import type { RunEvent } from "@/lib/api";
import type { KennelContext } from "@/lib/types/kennel";

interface RunDetailModalProps {
  run: RunEvent;
  kennel: KennelContext;
  slug: string;
  onClose: () => void;
}

function fmt(iso: string) {
  const d = new Date(iso);
  return {
    date: d.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
    time: d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }),
  };
}

function mapsUrl(lat: number | null, lon: number | null, label: string): string | null {
  if (!lat || !lon) return null;
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}&query_place_id=${encodeURIComponent(label)}`;
}

function parseW3w(json: string | null): string | null {
  if (!json) return null;
  try {
    const parsed = JSON.parse(json) as { map?: string; words?: string };
    return parsed.map ?? (parsed.words ? `https://what3words.com/${parsed.words}` : null);
  } catch { return null; }
}

export function RunDetailModal({ run, kennel, slug, onClose }: RunDetailModalProps) {
  // Close on Escape
  useEffect(() => {
    const handler = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    document.addEventListener("keydown", handler);
    return () => document.removeEventListener("keydown", handler);
  }, [onClose]);

  // Lock body scroll while open
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = prev; };
  }, []);

  const { date, time } = fmt(run.EventStartDatetime);
  const mapsLink = mapsUrl(run.Latitude, run.Longitude, run.LocationOneLineDesc ?? run.EventName);
  const w3wLink = parseW3w(run.w3wJson);

  const locationOneLine = [run.LocationOneLineDesc, run.LocationCity].filter(Boolean)[0];
  const locationStreetLine = [
    run.LocationStreet,
    run.LocationPostCode,
  ].filter(Boolean).join(", ");

  return (
    <>
      {/* Backdrop */}
      <motion.div
        className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      {/* Scroll container */}
      <div className="fixed inset-0 z-50 overflow-y-auto">
        <div className="flex min-h-full items-start justify-center p-4 pt-16 pb-10">
          <motion.div
            className="relative w-full max-w-2xl rounded-[2rem] overflow-hidden dark:bg-zinc-900 bg-white shadow-2xl"
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ duration: 0.25, ease: [0.19, 1, 0.22, 1] }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Close button */}
            <button
              onClick={onClose}
              aria-label="Close"
              className="absolute top-4 right-4 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-black/50 backdrop-blur-md text-white hover:bg-black/70 transition-colors"
            >
              <X className="h-4 w-4" />
            </button>

            {/* Hero image */}
            {run.EventImage && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={run.EventImage} alt={run.EventName} className="w-full h-auto block" />
            )}

            {/* Title bar */}
            <div
              className="flex items-start justify-between gap-3 px-5 py-4"
              style={{ backgroundColor: "var(--kennel-primary)" }}
            >
              <div className="min-w-0">
                <div className="text-white text-xl font-medium mb-0.5">{kennel.shortName}</div>
                <h2 className="text-2xl font-bold text-white leading-snug">{run.EventName}</h2>
              </div>
              <div className="flex flex-col items-end gap-1.5 shrink-0 pt-0.5">
                <span className="rounded-full border border-white/30 bg-white/20 px-3 py-1 text-xl font-bold text-white whitespace-nowrap">
                  #{run.EventNumber}
                </span>
                {run.EventTypeName && (
                  <span className="rounded-full border border-white/20 bg-black/20 px-3 py-0.5 text-base font-semibold text-white whitespace-nowrap">
                    {run.EventTypeName}
                  </span>
                )}
              </div>
            </div>

            {/* Content */}
            <div className="p-5 md:p-6 space-y-4">

              {/* When / Where */}
              <div className="grid grid-cols-2 gap-3">
                <div className="rounded-2xl border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-100 bg-zinc-50 p-4">
                  <div className="text-base uppercase tracking-[0.12em] dark:text-white text-zinc-900 mb-2 flex items-center gap-1.5">
                    <Clock className="h-3.5 w-3.5" /> When
                  </div>
                  <div className="text-xl font-semibold dark:text-white text-zinc-900" suppressHydrationWarning>{date}</div>
                  <div className="text-xl dark:text-white text-zinc-900 mt-0.5" suppressHydrationWarning>{time}</div>
                </div>
                <div className="rounded-2xl border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-100 bg-zinc-50 p-4">
                  <div className="text-base uppercase tracking-[0.12em] dark:text-white text-zinc-900 mb-2 flex items-center gap-1.5">
                    <MapPin className="h-3.5 w-3.5" /> Where
                  </div>
                  {locationOneLine ? (
                    <>
                      <div className="text-xl font-semibold dark:text-white text-zinc-900">{locationOneLine}</div>
                      {locationStreetLine && (
                        <div className="text-xl dark:text-white text-zinc-900 mt-0.5">{locationStreetLine}</div>
                      )}
                    </>
                  ) : (
                    <div className="text-xl dark:text-white text-zinc-900 italic">TBC</div>
                  )}
                </div>
              </div>

              {/* Hares */}
              {run.Hares && (
                <div className="flex items-start gap-3 rounded-2xl border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-100 bg-zinc-50 px-4 py-3">
                  <Users className="h-4 w-4 shrink-0 dark:text-white/40 text-zinc-400 mt-0.5" />
                  <div>
                    <div className="text-base uppercase tracking-[0.12em] dark:text-white text-zinc-900 mb-1">Hares</div>
                    <div className="text-xl font-medium dark:text-white text-zinc-900">{run.Hares}</div>
                  </div>
                </div>
              )}

              {/* Tags */}
              {run.tags.length > 0 && (
                <div>
                  <div className="text-base uppercase tracking-[0.12em] dark:text-white text-zinc-900 mb-2 flex items-center gap-1.5">
                    <Tag className="h-3.5 w-3.5" /> Event tags
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {run.tags.map((tag) => (
                      <span
                        key={tag}
                        className="inline-flex rounded-full border px-3 py-1 text-xl font-medium dark:border-white/10 dark:bg-white/5 dark:text-white border-zinc-200 bg-zinc-50 text-zinc-900"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Description */}
              {run.EventDescription && (
                <p className="text-xl leading-8 dark:text-white text-zinc-900 whitespace-pre-wrap line-clamp-6">
                  {run.EventDescription}
                </p>
              )}

              {/* Actions */}
              <div className="flex flex-wrap gap-3 pt-1">
                {mapsLink && (
                  <a
                    href={mapsLink}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-full border px-4 py-2 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-zinc-50 hover:bg-zinc-100 text-zinc-900"
                  >
                    <Navigation className="h-4 w-4" /> Open in Maps
                  </a>
                )}
                {w3wLink && (
                  <a
                    href={w3wLink}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-full border px-4 py-2 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-zinc-50 hover:bg-zinc-100 text-zinc-900"
                  >
                    /// What3Words
                  </a>
                )}
                {run.EventUrl && (
                  <a
                    href={run.EventUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-full border px-4 py-2 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-zinc-50 hover:bg-zinc-100 text-zinc-900"
                  >
                    <ExternalLink className="h-4 w-4" /> Event page
                  </a>
                )}
                <Link
                  href={`/${slug}/${run.EventNumber}?back=${encodeURIComponent(`/${slug}/runs`)}`}
                  onClick={onClose}
                  className="inline-flex items-center gap-1.5 rounded-full px-4 py-2 text-xl font-semibold transition-opacity hover:opacity-90"
                  style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
                >
                  Full details →
                </Link>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </>
  );
}
