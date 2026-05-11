"use client";

import { useState } from "react";
import { motion, AnimatePresence, useTransform, useMotionValueEvent } from "framer-motion";
import { Menu, X, MapPin, ArrowRight, Globe } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import type { KennelContext, KennelPageFeatures } from "@/lib/types/kennel";
import type { RunEvent } from "@/lib/api";
import { useWindowScrollMotionValue } from "@/lib/useWindowScrollMotionValue";

interface StickyNavProps {
  kennel: KennelContext;
  nextRun?: RunEvent | null;
  slug: string;
  alwaysVisible?: boolean;
  navItems?: { label: string; href: string }[];
}

function hexToRgba(hex: string | undefined | null, alpha: number): string {
  if (!hex || hex.length < 7) return `rgba(9, 9, 11, ${alpha})`;
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function formatBannerDate(nextRun: RunEvent) {
  const gmt = nextRun.EventStartDatetimeGmt;
  const tz  = nextRun.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(nextRun.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  const date = src.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: displayTz });
  const time = src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz });
  return `${date} · ${time}`;
}

function mapsUrl(lat: number, lon: number) {
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}`;
}

const NAV_ITEMS: { label: string; featureKey?: keyof KennelPageFeatures; href: (slug: string) => string }[] = [
  { label: "Home",   href: (s) => `/${s}` },
  { label: "Runs",   featureKey: "showRuns",   href: (s) => `/${s}/runs` },
  { label: "Events", featureKey: "showEvents", href: (s) => `/${s}/events` },
  { label: "Stats",  featureKey: "showStats",  href: (s) => `/${s}/stats` },
  { label: "Songs",  featureKey: "showSongs",  href: (s) => `/${s}/songs` },
  { label: "About",  featureKey: "showAbout",  href: (s) => `#about` },
];

export function StickyNav({ kennel, nextRun, slug, alwaysVisible = false, navItems }: StickyNavProps) {
  const scrollY = useWindowScrollMotionValue();
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const visibleNavItems: { label: string; href: string }[] = navItems
    ?? NAV_ITEMS
        .filter(item => !item.featureKey || kennel.pageFeatures[item.featureKey])
        .map(item => ({ label: item.label, href: item.href(slug) }));

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
                    {formatBannerDate(nextRun)}
                  </span>
                </div>

                {/* Action buttons */}
                <div className="flex shrink-0 items-center gap-2">
                  {nextRun.Latitude && nextRun.Longitude && (
                    <a
                      href={mapsUrl(nextRun.Latitude, nextRun.Longitude)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hidden items-center gap-1.5 rounded-full border border-white/15 px-3 py-1.5 text-base font-semibold transition-opacity hover:opacity-90 min-[420px]:inline-flex"
                      style={{
                        backgroundColor: "var(--kennel-btn-secondary, rgba(255,255,255,0.08))",
                        color: "var(--kennel-primary-fg)",
                      }}
                    >
                      <MapPin className="h-3.5 w-3.5 shrink-0" />
                      <span className="hidden sm:inline">Map</span>
                    </a>
                  )}
                  <Link
                    href={`/${slug}/${nextRun.EventNumber}`}
                    className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-base font-semibold transition-opacity hover:opacity-90"
                    style={{
                      backgroundColor: "var(--kennel-btn-primary, var(--kennel-primary))",
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

        {/* Sticky nav — fades in as you scroll (or immediately when there's no banner) */}
        <motion.div
          className="absolute inset-0 flex items-center px-4 md:px-6"
          style={{
            opacity: (alwaysVisible || !nextRun) ? 1 : navOpacity,
            y: (alwaysVisible || !nextRun) ? 0 : navY,
            pointerEvents: (alwaysVisible || !nextRun || scrolled) ? "auto" : "none",
          }}
        >
          <div className="mx-auto w-full max-w-7xl flex items-center justify-between">
            {/* Left — logo + kennel name */}
            <div className="flex items-center gap-3">
              <div
                className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/15 shadow-lg"
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
              <nav className="hidden items-center gap-8 text-xl lg:flex">
                {visibleNavItems.map((item) => (
                  <a
                    key={item.label}
                    href={item.href}
                    className="transition-opacity hover:opacity-70"
                  >
                    {item.label}
                  </a>
                ))}
              </nav>

              {/* <Button
                size="sm"
                className="hidden rounded-full text-base font-semibold lg:flex"
                style={{
                  backgroundColor: "var(--kennel-primary)",
                  color: "var(--kennel-primary-fg)",
                }}
              >
                Member login
              </Button> */}

              {/* Globe — desktop: far-right item; mobile: left of hamburger */}
              <Link
                href="/"
                className="hidden lg:flex items-center justify-center h-10 w-10 rounded-md transition-opacity opacity-60 hover:opacity-100"
                aria-label="Global runs"
              >
                <Globe className="h-6 w-6" />
              </Link>

              <div className="lg:hidden flex items-center gap-3">
                <Link
                  href="/"
                  className="flex items-center justify-center h-10 w-10 rounded-md transition-opacity opacity-60 hover:opacity-100"
                  aria-label="Global runs"
                >
                  <Globe className="h-6 w-6" />
                </Link>
                <button
                  onClick={() => setMobileMenuOpen((o) => !o)}
                  aria-label={mobileMenuOpen ? "Close menu" : "Open menu"}
                  className="flex items-center justify-center rounded-md transition-opacity opacity-80 hover:opacity-100"
                >
                  {mobileMenuOpen ? <X className="h-7 w-7" /> : <Menu className="h-7 w-7" />}
                </button>
              </div>
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
            className="relative overflow-hidden lg:hidden border-t dark:border-white/[0.08] border-zinc-200/50"
            style={{ backgroundColor: hexToRgba(kennel.menuBackgroundColor, kennel.menuBackgroundOpacity) }}
          >
            <nav className="flex flex-col px-4 py-3 gap-1">
              {visibleNavItems.map((item) => (
                <a
                  key={item.label}
                  href={item.href}
                  className="rounded-xl px-3 py-3 text-xl font-medium dark:hover:bg-white/[0.06] hover:bg-zinc-100 transition-colors"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {item.label}
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
              {/* <div className="pt-2 mt-1 border-t dark:border-white/[0.08] border-zinc-200/50">
                <button
                  className="w-full rounded-full py-3 text-xl font-semibold"
                  style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
                >
                  Member login
                </button>
              </div> */}
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}
