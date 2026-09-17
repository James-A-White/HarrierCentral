import "server-only";
import { callAdminApi } from "@/lib/member-api";
import type { MemberSession } from "@/lib/member-session";

/**
 * The public web's error log. Everything else in Harrier Central writes its
 * failures to HC.ErrorLog, which is what `tools/log_sweep.sh` and the
 * portal's Usage Data read; the Next.js app only ever called console.error,
 * and on App Service nobody reads that. This sends the same failures to the
 * same table so a web bug shows up in the same sweep as an SP or app one.
 *
 * Two rules, both deliberate:
 *  - It never throws. A logger that can break the page it is reporting on is
 *    worse than no logger, so every failure here is swallowed.
 *  - It never blocks the response. Callers may `void` it.
 */
const VERSION = `web ${process.env.NEXT_PUBLIC_APP_VERSION ?? "unknown"}`;

export interface WebErrorContext {
  /** The route or component that failed, e.g. "/api/member/rsvp". */
  source: string;
  /** What went wrong, one line. */
  error: unknown;
  /** The page or endpoint the reader was on. */
  url?: string;
  /** When a member session was in hand. */
  session?: MemberSession | null;
  /** Anything else worth having next to the stack. */
  detail?: string;
}

function messageOf(error: unknown): string {
  if (error instanceof Error) return error.message || error.name;
  if (typeof error === "string") return error;
  try { return JSON.stringify(error).slice(0, 240); } catch { return String(error); }
}

function detailOf(error: unknown, extra?: string): string {
  const stack = error instanceof Error && error.stack ? error.stack : "";
  return [extra, stack].filter(Boolean).join("\n").slice(0, 2400);
}

export async function logWebError(ctx: WebErrorContext): Promise<void> {
  // Still say it locally: this is how it surfaces in `next dev`.
  console.error(`[${ctx.source}]`, ctx.error);
  try {
    await callAdminApi("logWebError", {
      source: ctx.source.slice(0, 250),
      message: messageOf(ctx.error).slice(0, 250),
      detail: detailOf(ctx.error, ctx.detail),
      version: VERSION,
      url: ctx.url ?? null,
      userId: ctx.session?.userId ?? null,
      deviceId: ctx.session?.deviceId ?? null,
    });
  } catch {
    // Logging the logger's failure would be turtles all the way down.
  }
}
