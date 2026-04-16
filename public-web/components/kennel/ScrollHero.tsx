"use client";

import { useEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";
import { motion, useTransform } from "framer-motion";
import Link from "next/link";
import { ChevronDown } from "lucide-react";
import type { KennelContext } from "@/lib/types/kennel";
import type { RunEvent } from "@/lib/api";
import { useWindowScrollMotionValue } from "@/lib/useWindowScrollMotionValue";

interface ScrollHeroProps {
  kennel: KennelContext;
  slug: string;
  nextRun?: RunEvent | null;
}

const DEFAULT_NAV_BOTTOM_PX = 88;
const HERO_FILL_RATIO = 0.8;
const LAYOUT_POSITION_EPSILON_PX = 0.5;
const LAYOUT_SCALE_EPSILON = 0.002;
const HERO_FADE_SCROLL_START = 220;
const HERO_FADE_SCROLL_END = 760;
const BACKGROUND_SCROLL_BLEND_END = 300;
const HERO_BUTTON_TEXT_PX = 22.4;

export function ScrollHero({ kennel, slug, nextRun }: ScrollHeroProps) {
  const pathname = usePathname();
  const scrollY = useWindowScrollMotionValue();
  const sectionRef = useRef<HTMLElement | null>(null);
  const heroContentRef = useRef<HTMLDivElement | null>(null);
  const frameRef = useRef<number | null>(null);
  const lastLayoutRef = useRef({ frameTopPx: DEFAULT_NAV_BOTTOM_PX, frameBottomInsetPx: 0, fitScale: 1 });
  const [frameTopPx, setFrameTopPx] = useState(DEFAULT_NAV_BOTTOM_PX);
  const [frameBottomInsetPx, setFrameBottomInsetPx] = useState(0);
  const [fitScale, setFitScale] = useState(1);

  useEffect(() => {
    const computeLayout = () => {
      frameRef.current = null;
      const section = sectionRef.current;
      const content = heroContentRef.current;
      if (!section || !content) return;

      const nav = document.querySelector<HTMLElement>("[data-sticky-nav='true']");
      const navBottom = nav?.getBoundingClientRect().bottom ?? DEFAULT_NAV_BOTTOM_PX;
      const sectionBottom = section.getBoundingClientRect().bottom;
      const clampedSectionBottom = Math.max(0, Math.min(window.innerHeight, sectionBottom));
      const availableHeight = Math.max(0, clampedSectionBottom - navBottom);
      const nextFrameBottomInsetPx = Math.max(0, window.innerHeight - clampedSectionBottom);

      // Fit the full hero stack (including buttons and all spacing)
      // to 80% of the live frame between nav-bottom and content-top.
      const contentHeight = content.scrollHeight;
      const targetHeight = availableHeight * HERO_FILL_RATIO;
      const nextFitScale =
        contentHeight > 0 && targetHeight > 0
          ? Math.min(1, targetHeight / contentHeight)
          : 1;

      if (Math.abs(navBottom - lastLayoutRef.current.frameTopPx) > LAYOUT_POSITION_EPSILON_PX) {
        lastLayoutRef.current.frameTopPx = navBottom;
        setFrameTopPx(navBottom);
      }

      if (Math.abs(nextFrameBottomInsetPx - lastLayoutRef.current.frameBottomInsetPx) > LAYOUT_POSITION_EPSILON_PX) {
        lastLayoutRef.current.frameBottomInsetPx = nextFrameBottomInsetPx;
        setFrameBottomInsetPx(nextFrameBottomInsetPx);
      }

      if (Math.abs(nextFitScale - lastLayoutRef.current.fitScale) > LAYOUT_SCALE_EPSILON) {
        lastLayoutRef.current.fitScale = nextFitScale;
        setFitScale(nextFitScale);
      }
    };

    const queueComputeLayout = () => {
      // Always keep only the latest RAF callback so a stale queued frame can't
      // block future layout work after route/bfcache restores.
      if (frameRef.current !== null) {
        window.cancelAnimationFrame(frameRef.current);
      }
      frameRef.current = window.requestAnimationFrame(computeLayout);
    };

    queueComputeLayout();

    const resizeObserver = new ResizeObserver(queueComputeLayout);
    if (heroContentRef.current) {
      resizeObserver.observe(heroContentRef.current);
    }
    if (sectionRef.current) {
      resizeObserver.observe(sectionRef.current);
    }

    window.addEventListener("resize", queueComputeLayout);
    window.addEventListener("scroll", queueComputeLayout, { passive: true });
    window.addEventListener("pageshow", queueComputeLayout);
    window.addEventListener("popstate", queueComputeLayout);

    return () => {
      resizeObserver.disconnect();
      window.removeEventListener("resize", queueComputeLayout);
      window.removeEventListener("scroll", queueComputeLayout);
      window.removeEventListener("pageshow", queueComputeLayout);
      window.removeEventListener("popstate", queueComputeLayout);
      if (frameRef.current !== null) {
        window.cancelAnimationFrame(frameRef.current);
        frameRef.current = null;
      }
    };
  }, [pathname]);

  const scale = fitScale;
  const opacity = useTransform(scrollY, [HERO_FADE_SCROLL_START, HERO_FADE_SCROLL_END], [1, 0]);
  // Animate opacity only — never animate CSS filter (blur) on large elements;
  // that runs on the CPU per frame and will peg all cores on a large display.
  // Instead we cross-fade between an un-blurred and a pre-blurred layer.
  const blurredLayerOpacity = useTransform(scrollY, [0, BACKGROUND_SCROLL_BLEND_END], [0, 1]);
  // ScrollBlur 0–100 maps to 0–120px. Pre-baked as a static filter; only opacity animates.
  // 120px gives a much stronger full-blur state when value reaches 100.
  const clampedScrollBlur = Math.min(100, Math.max(0, kennel.scrollBlur));
  const blurPx = (clampedScrollBlur / 100) * 120;
  const overlayOpacity = useTransform(scrollY, [0, BACKGROUND_SCROLL_BLEND_END], [0, kennel.backgroundOverlayMaxOpacity]);

  // All kennel background images — local default or kennel-uploaded — use bg-cover.
  // scale-[1.08] on the blur layer prevents CSS blur from feathering to transparent
  // at viewport edges. The base layer uses the same class for consistency.
  const bgLayerClass = "fixed inset-0 -z-10 scale-[1.08] bg-cover bg-center bg-no-repeat";
  const bgLayerStyle = { backgroundImage: `url(${kennel.backgroundImageUrl})` };

  return (
    <section ref={sectionRef} className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden">
      {/* Background */}
      {kennel.backgroundImageUrl ? (
        <>
          {/* Layer 1 — sharp base image, always visible */}
          <div className={bgLayerClass} style={bgLayerStyle} />
          {/* Layer 2 — pre-blurred image, fades in on scroll (opacity only, GPU compositor) */}
          {blurPx > 0 && (
            <motion.div
              className={bgLayerClass}
              style={{ ...bgLayerStyle, filter: `blur(${blurPx}px)`, opacity: blurredLayerOpacity }}
            />
          )}
          {/* Colour overlay — fades in on scroll alongside the blur layer */}
          <motion.div
            className="fixed inset-0"
            style={{ backgroundColor: kennel.backgroundOverlayColor, opacity: overlayOpacity, zIndex: -9 }}
          />
        </>
      ) : (
        <div className="absolute inset-0 -z-10 overflow-hidden">
          {/* Solid dark base */}
          <div className="absolute inset-0 bg-zinc-950" />
          {/* Kennel-colour radial tint — keeps brand identity visible */}
          <div
            className="absolute inset-0"
            style={{
              background: `radial-gradient(circle at 50% 0%, color-mix(in srgb, var(--kennel-primary) 18%, transparent) 0%, transparent 55%)`,
            }}
          />
          {/* Static colour overlay at DB max opacity — no scroll animation */}
          <div
            className="absolute inset-0"
            style={{ backgroundColor: kennel.backgroundOverlayColor, opacity: kennel.backgroundOverlayMaxOpacity }}
          />
        </div>
      )}

      {/* Hero content */}
      <div
        className="fixed inset-x-0 z-0"
        style={{ top: `${frameTopPx}px`, bottom: `${frameBottomInsetPx}px` }}
      >
        <div className="flex h-full items-center justify-center">
          <motion.div className="origin-center" style={{ scale, opacity }}>
          <div
            ref={heroContentRef}
            className="mx-auto flex w-full max-w-6xl flex-col items-center justify-center px-4 text-center"
          >
        {/* Logo */}
        {kennel.logoUrl ? (
          <motion.img
            src={kennel.logoUrl}
            alt={kennel.shortName}
            className="mb-6 h-auto max-h-[52svh] w-[min(56vw,56svh)] max-w-[620px] object-contain drop-shadow-2xl"
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, ease: [0.19, 1, 0.22, 1] }}
          />
        ) : (
          <motion.div
            className="mb-6 flex h-[clamp(6rem,12svh,10rem)] w-[clamp(6rem,12svh,10rem)] items-center justify-center rounded-[2rem] border border-black/10 shadow-2xl shadow-black/10 dark:border-white/15 dark:shadow-black/40"
            style={{ backgroundColor: "var(--kennel-primary)" }}
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, ease: [0.19, 1, 0.22, 1] }}
          >
            <span className="text-4xl font-black" style={{ color: "var(--kennel-primary-fg)" }}>
              {kennel.logoLetter}
            </span>
          </motion.div>
        )}

        {/* Title text — custom display name from KennelWebsite.TitleText */}
        {kennel.titleText && (
          <motion.p
            className="mt-3 text-[clamp(1.5rem,4.2vh,3.25rem)] font-bold tracking-wide"
            style={{
              color: kennel.titleTextColor ?? (kennel.theme === "dark" ? "#ffffff" : "#18181b"),
            }}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.1, ease: [0.19, 1, 0.22, 1] }}
          >
            {kennel.titleText}
          </motion.p>
        )}

        {/* Short name */}
        <motion.h1
          className="text-[clamp(2.5rem,9vh,7rem)] font-black uppercase text-zinc-900 dark:text-white"
          style={{ letterSpacing: "0.06em" }}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.1, ease: [0.19, 1, 0.22, 1] }}
        >
          {kennel.shortName}
        </motion.h1>

        <motion.p
          className="mt-2 text-[clamp(1.1rem,3.8vh,2rem)] font-semibold text-zinc-700 dark:text-white/80"
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.2, ease: [0.19, 1, 0.22, 1] }}
        >
          {kennel.name}
        </motion.p>

        <motion.div
          className="mt-[clamp(1.25rem,4vh,2.5rem)] flex flex-col gap-3 sm:flex-row"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4, ease: [0.19, 1, 0.22, 1] }}
        >
          {nextRun && (
            <Link
              href={`/${slug}/${nextRun.EventNumber}`}
              className="rounded-full px-8 py-3 text-base font-semibold transition-opacity hover:opacity-90"
              style={{
                backgroundColor: "var(--kennel-primary)",
                color: "var(--kennel-primary-fg)",
                fontSize: `${HERO_BUTTON_TEXT_PX}px`,
              }}
            >
              See next run
            </Link>
          )}
          <button
            className="rounded-full border px-8 py-3 text-base font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.12] border-zinc-200 bg-transparent hover:bg-zinc-50 text-zinc-900"
            style={{ fontSize: `${HERO_BUTTON_TEXT_PX}px` }}
          >
            New runner info
          </button>
        </motion.div>
          </div>
        </motion.div>
        </div>
      </div>

      {/* Scroll cue */}
      <motion.div
        className="absolute bottom-8 flex flex-col items-center gap-2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2 }}
      >
        <span className="text-xs uppercase tracking-[0.2em] dark:text-white/30 text-zinc-400">Scroll</span>
        <motion.div
          animate={{ y: [0, 4, 0] }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        >
          <ChevronDown className="h-4 w-4 dark:text-white/30 text-zinc-400" />
        </motion.div>
      </motion.div>
    </section>
  );
}
