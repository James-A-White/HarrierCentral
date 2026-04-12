"use client";

import { useState } from "react";
import { motion, AnimatePresence, useTransform, useMotionValueEvent } from "framer-motion";
import { Menu, X, MapPin, ArrowRight } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import type { KennelContext } from "@/lib/types/kennel";
import type { RunEvent } from "@/lib/api";
import { useWindowScrollMotionValue } from "@/lib/useWindowScrollMotionValue";

interface StickyNavProps {
  kennel: KennelContext;
  nextRun?: RunEvent | null;
  slug: string;
  alwaysVisible?: boolean;
}

function hexToRgba(hex: string | undefined | null, alpha: number): string {
  if (!hex || hex.length < 7) return `rgba(9, 9, 11, ${alpha})`;
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function formatBannerDate(iso: string) {
  const d = new Date(iso);
  const date = d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" });
  const time = d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  return `${date} · ${time}`;
}

function mapsUrl(lat: number, lon: number) {
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`;
}

export function StickyNav({ kennel, nextRun, slug, alwaysVisible = false }: StickyNavProps) {
  const scrollY = useWindowScrollMotionValue();
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useMotionValueEvent(scrollY, "change", (v) => setScrolled(v > 60));

  const navOpacity = useTransform(scrollY, [40, 160], [0, 1]);
  const navY = useTransform(scrollY, [40, 160], [-8, 0]);
  const bannerOpacity = useTransform(scrollY, [0, 100], [1, 0]);
  const headerBlur = useTransform(scrollY, [40, 160], ["blur(0px)", "blur(4px)"]);

  return (
    <motion.header
      data-sticky-nav="true"
      className="fixed inset-x-0 top-0 z-50 border-b"
      style={{
        borderColor: "rgba(255,255,255,0.08)",
        backdropFilter: alwaysVisible ? "blur(4px)" : headerBlur,
        WebkitBackdropFilter: alwaysVisible ? "blur(4px)" : headerBlur,
        backgroundColor: hexToRgba(kennel.menuBackgroundColor, kennel.menuBackgroundOpacity),
        color: kennel.menuTextColor,
      }}
    >

      {/* Fixed-height shell — banner and nav share this space */}
      <div className="relative h-20">

        {/* Next run banner — visible at scroll top, fades out as nav fades in */}
        {nextRun && !alwaysVisible && (
          <motion.div
            className="absolute inset-0"
            style={{ opacity: bannerOpacity, pointerEvents: scrolled ? "none" : "auto" }}
          >
            {/* Gradient scrim — separates banner from hero content below */}
            <div className="absolute inset-0 bg-gradient-to-b dark:from-white/15 dark:to-white/30 from-black/15 to-black/30" />

            {/* Content */}
            <div className="relative h-full flex min-w-0 items-center px-4 md:px-6">
              <div className="mx-auto flex w-full min-w-0 max-w-7xl items-center gap-4">

                {/* "Next Run:" label — two lines, large */}
                <div className="hidden shrink-0 flex-col leading-none drop-shadow-md min-[380px]:flex">
                  <span className="text-xl font-black uppercase tracking-tight">Next</span>
                  <span className="text-xl font-black uppercase tracking-tight">Run:</span>
                </div>

                {/* Divider */}
                <div className="w-px self-stretch my-3 dark:bg-white/20 bg-black/15 shrink-0" />

                {/* Run info */}
                <div className="flex min-w-0 flex-1 flex-col drop-shadow-md">
                  <span className="text-xl font-bold truncate">
                    {nextRun.EventName}
                  </span>
                  <span className="truncate text-base" suppressHydrationWarning>
                    {formatBannerDate(nextRun.EventStartDatetime)}
                  </span>
                </div>

                {/* Action buttons */}
                <div className="flex shrink-0 items-center gap-2">
                  {nextRun.Latitude && nextRun.Longitude && (
                    <a
                      href={mapsUrl(nextRun.Latitude, nextRun.Longitude)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hidden items-center gap-1.5 rounded-full border px-3 py-1.5 text-base font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.12] border-black/10 bg-black/5 hover:bg-black/10 backdrop-blur-md min-[420px]:inline-flex"
                    >
                      <MapPin className="h-3.5 w-3.5 shrink-0" />
                      <span className="hidden sm:inline">Map</span>
                    </a>
                  )}
                  <Link
                    href={`/${slug}/runs/${nextRun.EventNumber}`}
                    className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-base font-semibold"
                    style={{
                      backgroundColor: "var(--kennel-primary)",
                      color: "var(--kennel-primary-fg)",
                    }}
                  >
                    Details
                    <ArrowRight className="h-3.5 w-3.5" />
                  </Link>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {/* Sticky nav — fades in as you scroll */}
        <motion.div
          className="absolute inset-0 flex items-center px-4 md:px-6"
          style={{
            opacity: alwaysVisible ? 1 : navOpacity,
            y: alwaysVisible ? 0 : navY,
            pointerEvents: (alwaysVisible || !nextRun || scrolled) ? "auto" : "none",
          }}
        >
          <div className="mx-auto w-full max-w-7xl flex items-center justify-between">
            {/* Left — logo + kennel name */}
            <div className="flex items-center gap-3">
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/15 shadow-lg overflow-hidden"
                style={{ backgroundColor: kennel.logoUrl ? undefined : "var(--kennel-primary)" }}
              >
                {kennel.logoUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={kennel.logoUrl}
                    alt={kennel.shortName}
                    className="h-full w-full object-contain p-0.5"
                  />
                ) : (
                  <span className="text-base font-black" style={{ color: "var(--kennel-primary-fg)" }}>
                    {kennel.logoLetter}
                  </span>
                )}
              </div>
              <div>
                <div className="text-xl font-bold tracking-[0.15em] uppercase">
                  {kennel.shortName}
                </div>
                <div className="text-base">{kennel.city} Hash House Harriers</div>
              </div>
            </div>

            {/* Right — nav links + login */}
            <div className="flex items-center gap-8">
              <nav className="hidden items-center gap-8 text-xl md:flex">
                {["Home", "Runs", "Events", "Stats", "Songs", "About"].map((item) => (
                  <a
                    key={item}
                    href={
                      item === "Home"   ? `/${slug}`
                      : item === "Runs"   ? `/${slug}/runs`
                      : item === "Events" ? `/${slug}/events`
                      : item === "Songs"  ? `/${slug}/songs`
                      : item === "Stats"  ? `/${slug}/stats`
                      : `#${item.toLowerCase()}`
                    }
                    className="transition-opacity hover:opacity-70"
                  >
                    {item}
                  </a>
                ))}
              </nav>

              {/* Harrier Central — back to the global run calendar */}
              <a
                href="/"
                style={{ opacity: 0.5 }}
                className="hidden md:block text-xl transition-opacity hover:opacity-100"
              >
                Harrier Central
              </a>

              <Button
                size="sm"
                className="hidden rounded-full text-base font-semibold md:flex"
                style={{
                  backgroundColor: "var(--kennel-primary)",
                  color: "var(--kennel-primary-fg)",
                }}
              >
                Member login
              </Button>
              <Button
                size="icon"
                variant="ghost"
                className="md:hidden"
                onClick={() => setMobileMenuOpen((o) => !o)}
                aria-label={mobileMenuOpen ? "Close menu" : "Open menu"}
              >
                {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </Button>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Mobile menu panel — slides down below the nav bar */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            key="mobile-menu"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2, ease: [0.19, 1, 0.22, 1] }}
            className="relative overflow-hidden md:hidden border-t dark:border-white/[0.08] border-zinc-200/50"
            style={{ backgroundColor: hexToRgba(kennel.menuBackgroundColor, kennel.menuBackgroundOpacity) }}
          >
            <nav className="flex flex-col px-4 py-3 gap-1">
              {["Home", "Runs", "Events", "Stats", "Songs", "About"].map((item) => (
                <a
                  key={item}
                  href={
                    item === "Home"   ? `/${slug}`
                    : item === "Runs"   ? `/${slug}/runs`
                    : item === "Events" ? `/${slug}/events`
                    : item === "Songs"  ? `/${slug}/songs`
                    : item === "Stats"  ? `/${slug}/stats`
                    : `#${item.toLowerCase()}`
                  }
                  className="rounded-xl px-3 py-3 text-xl font-medium dark:hover:bg-white/[0.06] hover:bg-zinc-100 transition-colors"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {item}
                </a>
              ))}
              <div className="pt-2 mt-1 border-t dark:border-white/[0.08] border-zinc-200/50">
                <a
                  href="/"
                  style={{ opacity: 0.5 }}
                  className="block rounded-xl px-3 py-3 text-xl font-medium dark:hover:bg-white/[0.06] hover:bg-zinc-100 transition-opacity hover:opacity-100"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Harrier Central
                </a>
              </div>
              <div className="pt-2 mt-1 border-t dark:border-white/[0.08] border-zinc-200/50">
                <button
                  className="w-full rounded-full py-3 text-xl font-semibold"
                  style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
                >
                  Member login
                </button>
              </div>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}
