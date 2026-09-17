"use client";

import { useEffect } from "react";

/**
 * Reports a crash the React error boundary caught, so a broken page tells
 * us rather than only the visitor. Fire-and-forget: if the report fails
 * there is nothing sensible left to do about it.
 */
export function ErrorReporter({ error, source }: { error: Error & { digest?: string }; source: string }) {
  useEffect(() => {
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
