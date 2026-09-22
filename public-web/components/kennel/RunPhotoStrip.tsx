/**
 * The app's Photos tab, on the public run page: the Hash Flash-approved photos
 * of the run as a grid of thumbnails. Server component; nothing to do when
 * there are none.
 *
 * Each thumbnail opens the run's photo carousel **at that photo**, rather than
 * the raw blob on the storage account. Linking straight to the blob was a dead
 * end — a bare image with no way back to the run, no way on to the next photo,
 * and none of the kennel's styling — and this grid was the main way into it.
 * The `#photo-N` fragment is the same anchor the carousel's own arrows and
 * thumbnails use, so no script is needed to land on the right one.
 */
import Link from "next/link";
import type { RunPhoto } from "@/lib/api";

interface RunPhotoStripProps {
  photos: RunPhoto[];
  slug: string;
  runNumber: string | number;
}

export function RunPhotoStrip({ photos, slug, runNumber }: RunPhotoStripProps) {
  if (photos.length === 0) return null;
  return (
    <section className="mt-8">
      <h3 className="mb-3 text-lg font-bold" style={{ color: "var(--kennel-text-title)" }}>Photos · {photos.length}</h3>
      <ul className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4">
        {photos.map((p, index) => (
          <li key={p.photoId} className="overflow-hidden rounded-xl bg-black/20">
            <Link href={`/${slug}/${runNumber}/photos#photo-${index + 1}`}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={p.blobUrl} alt={p.title ?? ""} loading="lazy" className="aspect-square w-full object-cover transition-transform hover:scale-[1.02]" />
            </Link>
            {(p.title || p.uploaderDisplayName) && (
              <p className="truncate px-2 py-1 text-xs" style={{ color: "var(--kennel-text-muted)" }}>
                {p.title ?? ""}{p.title && p.uploaderDisplayName ? " · " : ""}{p.uploaderDisplayName ?? ""}
              </p>
            )}
          </li>
        ))}
      </ul>
    </section>
  );
}
