"use client";

import { ErrorReporter } from "@/components/ErrorReporter";

/**
 * The last line of defence: a crash in the root layout. Next.js replaces
 * the whole document here, so this file carries its own html and body.
 */
export default function GlobalError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#18181b", color: "#fafafa", fontFamily: "system-ui, sans-serif", padding: 24 }}>
        <ErrorReporter error={error} source="global-error" />
        <div style={{ maxWidth: 420, textAlign: "center" }}>
          <h1 style={{ fontSize: 22, marginBottom: 12 }}>Something broke on our side</h1>
          <p style={{ opacity: 0.8, lineHeight: 1.5, marginBottom: 20 }}>
            It has been reported. Try again, and if it keeps happening let us know at harriercentral@gmail.com.
          </p>
          <button onClick={reset} style={{ background: "#B71C1C", color: "#fff", border: 0, borderRadius: 999, padding: "10px 22px", fontSize: 16, cursor: "pointer" }}>
            Try again
          </button>
        </div>
      </body>
    </html>
  );
}
