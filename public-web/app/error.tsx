"use client";

import Link from "next/link";
import { ErrorReporter } from "@/components/ErrorReporter";

/**
 * A crash anywhere below the root layout — a kennel page, a run, the global
 * pages. Without this file the only boundary was `global-error.tsx`, which
 * Next.js renders by replacing the entire document, so a client error in one
 * component cost the visitor the whole page and the site chrome with it.
 *
 * Reported under its own source so the log says which boundary caught it.
 */
export default function AppError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <div className="mx-auto max-w-sm px-4 py-16 text-center text-white">
      <ErrorReporter error={error} source="app-error" />
      <h1 className="mb-3 text-[22px] font-bold">That did not load</h1>
      <p className="mb-6 text-[16px] text-white/80">
        It has been reported. Try again, and if it keeps happening let us know at harriercentral@gmail.com.
      </p>
      <div className="flex items-center justify-center gap-3">
        <button type="button" onClick={reset} className="rounded-full px-5 py-2 text-[16px] font-semibold text-white" style={{ backgroundColor: "#B71C1C" }}>
          Try again
        </button>
        <Link href="/" className="rounded-full bg-white/15 px-5 py-2 text-[16px] font-semibold text-white">Home</Link>
      </div>
    </div>
  );
}
