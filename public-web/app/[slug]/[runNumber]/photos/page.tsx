import { notFound } from "next/navigation";
import Link from "next/link";
import { isNumeric, resolveKennelAndEvent } from "@/lib/run-resolve";
import { getRunPhotos } from "@/lib/api";

interface PageProps {
  params: Promise<{ slug: string; runNumber: string }>;
}

// ── Metadata ───────────────────────────────────────────────────────────────────
//
// This page exists to be SHARED — it is one of the links the app's share sheet
// offers alongside PackTrack and Trail TV — so the preview card matters as much
// as the page. The first photo becomes the og:image, which is what somebody
// actually sees when the link lands in a WhatsApp group.

export async function generateMetadata({ params }: PageProps) {
  const { slug, runNumber } = await params;
  if (!isNumeric(runNumber)) return { title: "Photos not found" };

  const [kennel, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennel || !event) return { title: "Photos not found" };

  const photos = await getRunPhotos(event.PublicEventId);
  const title = `Photos — ${event.EventName} | ${kennel.KennelName}`;
  const description =
    photos.length > 0
      ? `${photos.length} photo${photos.length === 1 ? "" : "s"} from ${event.EventName}.`
      : `Photos from ${event.EventName}.`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      images: photos.length > 0 ? [{ url: photos[0].blobUrl }] : undefined,
    },
  };
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default async function RunPhotosPage({ params }: PageProps) {
  const { slug, runNumber } = await params;
  if (!isNumeric(runNumber)) notFound();

  const [kennelData, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennelData || !event) notFound();

  const photos = await getRunPhotos(event.PublicEventId);

  return (
    <main className="mx-auto max-w-6xl px-4 py-8">
      <header className="mb-6">
        <Link
          href={`/${slug}/${runNumber}`}
          className="text-sm text-neutral-500 hover:underline"
        >
          ← {event.EventName}
        </Link>
        <h1 className="mt-2 text-2xl font-semibold">Photos</h1>
        <p className="text-sm text-neutral-500">
          {kennelData.KennelName}
          {photos.length > 0
            ? ` · ${photos.length} photo${photos.length === 1 ? "" : "s"}`
            : ""}
        </p>
      </header>

      {photos.length === 0 ? (
        // A run with no photos is ordinary, not a failure — say so plainly
        // rather than showing an empty grid that looks broken.
        <p className="rounded-lg border border-neutral-200 p-6 text-center text-neutral-500 dark:border-neutral-800">
          No photos have been shared for this run yet.
        </p>
      ) : (
        <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {photos.map((p) => (
            <li key={p.photoId} className="group">
              {/* Opens the full-size original. Deliberately a plain link: the
                  viewer's own browser handles zoom and save, and a link works
                  where a scripted lightbox would not (an in-app browser, a
                  shared screenshot, no JS). */}
              <a href={p.blobUrl} target="_blank" rel="noopener noreferrer">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={p.blobUrl}
                  alt={p.title ?? `Photo from ${event.EventName}`}
                  loading="lazy"
                  className="aspect-square w-full rounded-lg object-cover transition-opacity group-hover:opacity-90"
                />
              </a>
              {(p.title || p.uploaderDisplayName) && (
                <p className="mt-1 truncate text-xs text-neutral-500">
                  {p.title}
                  {p.title && p.uploaderDisplayName ? " · " : ""}
                  {p.uploaderDisplayName}
                </p>
              )}
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
