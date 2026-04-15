import type { Metadata } from "next";
import { getGlobalCalendar } from "@/lib/api";
import { GlobalCalendar } from "@/components/global/GlobalCalendar";

export const metadata: Metadata = {
  title: "Global Calendar | hashruns.org",
  description: "Upcoming hash runs across all Harrier Central kennels worldwide.",
};

export default async function GlobalCalendarPage() {
  const today = new Date().toISOString().slice(0, 10);

  let initialRows: Awaited<ReturnType<typeof getGlobalCalendar>> = [];
  try {
    initialRows = await getGlobalCalendar({ fromDate: today, daysLimit: 30 });
  } catch {
    // Gracefully degrade — load-more will retry as the user scrolls
  }

  return (
    <main className="mx-auto max-w-2xl px-4 pb-24">
      <div className="py-8">
        <h1 className="text-3xl font-bold tracking-tight">Upcoming Runs</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Hash runs across all kennels — click a logo to visit that kennel&rsquo;s
          site.
        </p>
      </div>
      <GlobalCalendar initialRows={initialRows} initialFromDate={today} />
    </main>
  );
}
