"use client";

import { useState } from "react";
import { CalendarPlus, CalendarDays, CalendarSync, X } from "lucide-react";

/**
 * "Add to calendar" on a run page (James, 2026-10-17 — the same choice as the
 * app's run page): this run only, as a one-off snapshot, or the kennel's
 * calendar (recommended), which brings new runs and changes by itself.
 * Opening the choice is the tap's feedback; each option is a plain link, so
 * the browser's download or the calendar app's own dialog follows.
 */
export function AddToCalendar({ runIcsUrl, feedUrl, kennelShortName, className, style }: {
  runIcsUrl: string;
  feedUrl: string;
  kennelShortName: string;
  className: string;
  style: React.CSSProperties;
}) {
  const [open, setOpen] = useState(false);
  const webcal = feedUrl.replace(/^https?:\/\//, "webcal://");
  const google = `https://calendar.google.com/calendar/r?cid=${encodeURIComponent(webcal)}`;
  const pill = "rounded-full px-4 py-2 text-[14px] font-semibold text-center";

  return (
    <>
      <button onClick={() => setOpen(true)} className={className} style={style}>
        <CalendarPlus className="h-4 w-4" />
        Add to calendar
      </button>
      {open && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 p-4 sm:items-center"
          onClick={() => setOpen(false)}
          role="dialog"
          aria-modal="true"
          aria-label="Add to calendar"
        >
          <div
            className="w-full max-w-md rounded-2xl bg-white p-5 text-zinc-900 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-semibold">Add to calendar</h2>
              <button onClick={() => setOpen(false)} aria-label="Close" className="rounded-full p-1 hover:bg-zinc-100">
                <X className="h-5 w-5" />
              </button>
            </div>

            <a
              href={runIcsUrl}
              download
              onClick={() => setOpen(false)}
              className="flex gap-3 rounded-xl p-3 text-left hover:bg-zinc-50"
            >
              <CalendarDays className="mt-0.5 h-6 w-6 shrink-0 text-blue-700" />
              <span className="min-w-0">
                <span className="block font-semibold">This run only</span>
                <span className="block text-sm text-zinc-600">
                  A snapshot of the run as it is now. If the time, place or hares change later, your calendar
                  won&apos;t be updated.
                </span>
              </span>
            </a>

            <div className="flex gap-3 rounded-xl p-3 text-left">
              <CalendarSync className="mt-0.5 h-6 w-6 shrink-0 text-blue-700" />
              <span className="min-w-0">
                <span className="block font-semibold">All {kennelShortName} runs (recommended)</span>
                <span className="block text-sm text-zinc-600">
                  Subscribe to {kennelShortName}&apos;s calendar: new runs and changes arrive by themselves whenever
                  your calendar app checks for updates, each with a link back to the run.
                </span>
                <span className="mt-2 flex flex-wrap gap-2">
                  <a href={webcal} className={`${pill} bg-blue-700 text-white`}>Apple / Outlook</a>
                  <a href={google} target="_blank" rel="noopener noreferrer" className={`${pill} bg-zinc-200 text-zinc-900`}>
                    Google Calendar
                  </a>
                </span>
              </span>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
