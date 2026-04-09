import { getGlobalCalendar } from "@/lib/api";
import { GlobalCalendar } from "@/components/global/GlobalCalendar";

export const metadata = {
  title: "Harrier Central — Global Run Calendar",
  description:
    "Upcoming hash runs across all Harrier Central kennels worldwide.",
};

export default async function GlobalCalendarPage() {
  // Use today's UTC date as the start of the initial fetch window
  const today = new Date().toISOString().slice(0, 10);

  // Gracefully degrade if the SP is not yet deployed or the API is unavailable.
  let initialRows: Awaited<ReturnType<typeof getGlobalCalendar>> = [];
  try {
    initialRows = await getGlobalCalendar({ fromDate: today, daysLimit: 30 });
  } catch {
    // Render with an empty calendar — load-more will retry as the user scrolls
  }

  return (
    <html lang="en" className="dark">
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        {/* Default platform background — same tile used by kennels without their own image */}
        <div className="fixed inset-0 -z-10 scale-[1.08] bg-repeat" style={{ backgroundImage: "url(/images/default-background.png)", backgroundSize: "512px 512px" }} />
        <div className="fixed inset-0 -z-10 scale-[1.08] bg-repeat" style={{ backgroundImage: "url(/images/default-background.png)", backgroundSize: "512px 512px", filter: "blur(14px)" }} />
        <div className="fixed inset-0 -z-[9]" style={{ backgroundColor: "#000000", opacity: 0.55 }} />
        {/* Sticky header */}
        <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 px-4 py-4 backdrop-blur-lg">
          <div className="mx-auto max-w-2xl">
            <p className="text-sm font-semibold tracking-widest text-zinc-400 uppercase">
              Harrier Central
            </p>
          </div>
        </header>

        <main className="mx-auto max-w-2xl px-4 pb-24">
          <div className="py-8">
            <h1 className="text-3xl font-bold tracking-tight">
              Upcoming Runs
            </h1>
            <p className="mt-1 text-sm text-zinc-400">
              Hash runs across all kennels — click a logo to visit that
              kennel&rsquo;s site.
            </p>
          </div>

          <GlobalCalendar initialRows={initialRows} initialFromDate={today} />
        </main>
      </body>
    </html>
  );
}
