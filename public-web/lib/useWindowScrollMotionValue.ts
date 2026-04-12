"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import { useMotionValue } from "framer-motion";

/**
 * Returns a MotionValue that tracks window scroll reliably across route changes,
 * browser back/forward restores, and transient event-listener edge cases.
 */
export function useWindowScrollMotionValue() {
  const pathname = usePathname();
  const scrollY = useMotionValue(0);

  useEffect(() => {
    const readScrollY = () =>
      window.scrollY ||
      document.documentElement.scrollTop ||
      document.body.scrollTop ||
      0;

    const sync = () => {
      scrollY.set(readScrollY());
    };

    const syncNextFrame = () => {
      requestAnimationFrame(sync);
    };

    window.addEventListener("scroll", sync, { passive: true });
    window.addEventListener("wheel", syncNextFrame, { passive: true });
    window.addEventListener("touchmove", syncNextFrame, { passive: true });
    window.addEventListener("resize", syncNextFrame);
    window.addEventListener("pageshow", syncNextFrame);
    window.addEventListener("popstate", syncNextFrame);
    document.addEventListener("visibilitychange", syncNextFrame);

    sync();

    // Short fallback window to survive route-cache/bfcache restore timing quirks.
    const intervalId = window.setInterval(sync, 200);
    const timeoutId = window.setTimeout(() => {
      window.clearInterval(intervalId);
    }, 4000);

    return () => {
      window.removeEventListener("scroll", sync);
      window.removeEventListener("wheel", syncNextFrame);
      window.removeEventListener("touchmove", syncNextFrame);
      window.removeEventListener("resize", syncNextFrame);
      window.removeEventListener("pageshow", syncNextFrame);
      window.removeEventListener("popstate", syncNextFrame);
      document.removeEventListener("visibilitychange", syncNextFrame);
      window.clearInterval(intervalId);
      window.clearTimeout(timeoutId);
    };
  }, [pathname, scrollY]);

  return scrollY;
}