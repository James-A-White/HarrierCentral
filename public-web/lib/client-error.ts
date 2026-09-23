/**
 * Reports a failure from BROWSER code to the same place every other web
 * error goes (/api/web-error → publicWeb_logWebError → HC.ErrorLog).
 *
 * `lib/web-log.ts` is server-only; client components and the fetch helpers
 * in `lib/packtrack.ts` could only `console.error`, which on a visitor's
 * phone nobody sees and on App Service nobody reads. Five PackTrack fetch
 * failures were logged that way and never reached a row.
 *
 * Fire-and-forget, never throws, and an identical message is sent once per
 * page load — a polling map that has lost its network would otherwise post
 * every thirty seconds.
 */
const sent = new Set<string>();

export function reportClientError(source: string, error: unknown, extra?: string): void {
  try {
    if (typeof window === "undefined") return;
    const message = error instanceof Error ? error.message || error.name : String(error);
    const key = `${source}:${message}`;
    if (sent.has(key)) return;
    sent.add(key);
    void fetch("/api/web-error", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        source,
        message: message.slice(0, 240),
        stack: [extra, error instanceof Error ? error.stack : undefined].filter(Boolean).join("\n").slice(0, 2000),
        url: window.location.pathname + window.location.search,
      }),
      keepalive: true,
    });
  } catch {
    /* reporting must never be worse than the failure it reports */
  }
}
