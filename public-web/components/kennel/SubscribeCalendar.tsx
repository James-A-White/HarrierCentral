import { kennelBaseUrl } from "@/lib/seo";

/**
 * "Add our runs to your calendar" (E3.F6.S8): subscribe links for the
 * kennel's iCal feed, /<slug>/runs.ics. `webcal://` opens the subscribe
 * dialog in Apple Calendar and Outlook; Google Calendar takes the feed
 * through its add-by-URL link. Plain links, so the calendar app's own
 * dialog is the feedback for the tap.
 */
export function SubscribeCalendar({ slug, customDomain, kennelShortName }: {
  slug: string;
  customDomain: string | null;
  kennelShortName: string;
}) {
  const feed = `${kennelBaseUrl(slug, customDomain)}/runs.ics`;
  const webcal = feed.replace(/^https?:\/\//, "webcal://");
  const google = `https://calendar.google.com/calendar/r?cid=${encodeURIComponent(webcal)}`;
  const button = "rounded-full px-4 py-2 text-[14px] font-semibold text-center";

  return (
    <div className="mx-auto flex max-w-3xl flex-wrap items-center justify-center gap-2 px-4 py-3 text-center">
      <span className="w-full text-[14px] text-white/80 sm:w-auto">Add {kennelShortName}&apos;s runs to your calendar:</span>
      <a href={webcal} className={button} style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}>
        Apple / Outlook
      </a>
      <a href={google} target="_blank" rel="noopener noreferrer" className={`${button} bg-white/15 text-white`}>
        Google Calendar
      </a>
      <a href={feed} className="w-full text-[12px] text-white/60 underline sm:w-auto">Feed address</a>
    </div>
  );
}
