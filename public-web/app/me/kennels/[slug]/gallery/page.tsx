import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getKennelArt, getMyKennels } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";

export const metadata: Metadata = { title: "Run Artwork" };

/**
 * The app's "Run art gallery" (hash_run_art_gallery_page.dart): every run
 * of the kennel with an event image, newest first, as white cards — the
 * image, the run's name, and the date — the image opening the run page.
 */
export default async function KennelGalleryPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const s = await requireMember();
  const mine = await getMyKennels(s).catch(() => []);
  const kennel = mine.find((k) => k.KennelSlug.toLowerCase() === slug.toLowerCase()) ?? null;
  if (!kennel) notFound();
  const items = await getKennelArt(s, kennel.PublicKennelId.toLowerCase()).catch(() => []);
  const here = `/me/kennels/${kennel.KennelSlug}`;

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href={here} aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">Run Artwork</h2>
        <span className="w-4" />
      </div>
      {items.length === 0 && <p className="px-3 py-8 text-center text-[20px] text-white">No run artwork yet.</p>}
      <ul className="space-y-3 px-2 pt-3">
        {items.map((it) => (
          <li key={it.PublicEventId} className="overflow-hidden rounded-md bg-white text-zinc-900 shadow">
            <Link href={`/${it.KennelSlug}/${it.EventNumber}?back=${encodeURIComponent(`${here}/gallery`)}`}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={it.EventImage} alt={it.EventName} className="w-full object-contain" style={{ maxHeight: 480 }} />
            </Link>
            <div className="px-3 pb-3 pt-2.5">
              <div className="text-[24px] font-semibold leading-tight">{it.EventName}</div>
              <div className="text-[17px] text-zinc-500" suppressHydrationWarning>{artDate(it.EventStartDatetime)}</div>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

/** DateFormat("E, MMM d, yyyy 'at' h:mm a") on the run's local wall-clock. */
function artDate(local: string): string {
  const d = new Date(/Z$|[+-]\d\d:\d\d$/.test(local) ? local : `${local}Z`);
  const day = d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric", timeZone: "UTC" });
  const time = d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", timeZone: "UTC" });
  return `${day} at ${time}`;
}
