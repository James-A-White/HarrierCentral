"use client";

import { useEffect } from "react";

/**
 * A page opened before a deploy asks for a code chunk that the deploy
 * removed (an iPhone on an LH3 run page, 2026-10-14, after four redeploys
 * that day). The fix is the new build, so reload once instead of showing
 * an error. The session flag stops a loop if the chunk really is missing.
 */
function reloadForStaleChunk(error: Error): boolean {
  const stale = error.name === "ChunkLoadError" || /Failed to load chunk|Loading chunk .* failed/.test(error.message ?? "");
  if (!stale) return false;
  try {
    const key = "hc-chunk-reload";
    const last = Number(sessionStorage.getItem(key) ?? 0);
    if (Date.now() - last < 60_000) return false; // reloaded a minute ago: report it
    sessionStorage.setItem(key, String(Date.now()));
  } catch {
    return false; // no storage, no loop guard: report rather than risk a loop
  }
  window.location.reload();
  return true;
}

/**
 * Reports a crash the React error boundary caught, so a broken page tells
 * us rather than only the visitor. Fire-and-forget: if the report fails
 * there is nothing sensible left to do about it.
 */
export function ErrorReporter({ error, source }: { error: Error & { digest?: string }; source: string }) {
  useEffect(() => {
    if (reloadForStaleChunk(error)) return;
    try {
      void fetch("/api/web-error", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          source,
          message: error.message || error.name,
          stack: error.stack?.slice(0, 2000),
          digest: error.digest,
          url: window.location.pathname + window.location.search,
        }),
        keepalive: true,
      });
    } catch { /* the page is already broken; do not make it worse */ }
  }, [error, source]);
  return null;
}
