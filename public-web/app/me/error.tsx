"use client";

import Link from "next/link";
import { ErrorReporter } from "@/components/ErrorReporter";

/** A crash inside the member area, reported and recoverable in place. */
export default function MemberError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <div className="mx-auto max-w-sm px-4 py-16 text-center text-white">
      <ErrorReporter error={error} source="/me" />
      <h1 className="mb-3 text-[22px] font-bold">That page did not load</h1>
      <p className="mb-6 text-[16px] text-white/80">
        It has been reported. Try again, or head back to your runs.
      </p>
      <div className="flex items-center justify-center gap-3">
        <button type="button" onClick={reset} className="rounded-full px-5 py-2 text-[16px] font-semibold text-white" style={{ backgroundColor: "#B71C1C" }}>
          Try again
        </button>
        <Link href="/me/runs" className="rounded-full bg-white/15 px-5 py-2 text-[16px] font-semibold text-white">My runs</Link>
      </div>
    </div>
  );
}
