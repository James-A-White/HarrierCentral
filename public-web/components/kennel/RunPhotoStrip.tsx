/**
 * The app's Photos tab, on the public run page: the Hash Flash-approved
 * photos of the run as a grid. Server component; nothing to do when there
 * are none.
 */
import type { RunPhoto } from "@/lib/api";

export function RunPhotoStrip({ photos }: { photos: RunPhoto[] }) {
  if (photos.length === 0) return null;
  return (
    <section className="mt-8">
      <h3 className="mb-3 text-lg font-bold" style={{ color: "var(--kennel-text-title)" }}>Photos · {photos.length}</h3>
      <ul className="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4">
        {photos.map((p) => (
          <li key={p.photoId} className="overflow-hidden rounded-xl bg-black/20">
            <a href={p.blobUrl} target="_blank" rel="noopener noreferrer">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={p.blobUrl} alt={p.title ?? ""} loading="lazy" className="aspect-square w-full object-cover transition-transform hover:scale-[1.02]" />
            </a>
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
