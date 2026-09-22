import type { RunPhoto } from "@/lib/api";

interface RunPhotoCarouselProps {
  photos: RunPhoto[];
  eventName: string;
}

/**
 * The run's photos, one at a time, with arrows and a thumbnail strip.
 *
 * **Built with no JavaScript at all**, and deliberately so. This page exists to
 * be shared — the app's share sheet offers it beside PackTrack and Trail TV —
 * so it is usually opened inside WhatsApp's own browser from a link in a group
 * chat. A scripted carousel is exactly the thing that fails there, or fails
 * while hydration is still in flight on a phone on trail data. CSS scroll-snap
 * gives swiping for free, and every control here is a plain `#fragment` link,
 * so the whole thing works before a single script has run.
 *
 * The photo is `object-contain`, not `cover`: a hash photo cropped to a square
 * loses whoever was standing at the edge, and the joke with them. The square
 * crop stays in the thumbnails, where it is only a target to tap.
 *
 * Tapping the photo still opens the full-size original in a new tab, which is
 * how the viewer's own zoom and "save image" keep working — but it is no
 * longer the ONLY way through the set, which it was when this page was a grid.
 */
export function RunPhotoCarousel({ photos, eventName }: RunPhotoCarouselProps) {
  const lastIndex = photos.length - 1;

  // The `download` attribute is IGNORED cross-origin, and the photos live on
  // the blob account — so a direct link would just open the image again. This
  // goes through our own origin, which is what makes it a download and what
  // lets the file arrive named after the run instead of a GUID.
  const downloadHref = (photo: RunPhoto, index: number) =>
    `/api/run-photos/download?url=${encodeURIComponent(photo.blobUrl)}` +
    `&name=${encodeURIComponent(`${eventName} ${index + 1}`)}`;

  return (
    <section aria-label={`Photos from ${eventName}`}>
      {/* The carousel. scroll-snap means a swipe lands squarely on a photo
          rather than halfway between two. */}
      <ul className="flex snap-x snap-mandatory overflow-x-auto scroll-smooth pb-3 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {photos.map((photo, index) => (
          <li
            key={photo.photoId}
            id={`photo-${index + 1}`}
            // px-3 is the margin around each photo: it keeps the frame off the
            // screen edge and lets the next photo show a sliver, which is what
            // tells a thumb there is more to swipe to.
            className="w-full shrink-0 snap-center scroll-mx-3 px-3"
          >
            <figure className="relative rounded-2xl border border-white/15 bg-black/30 p-3 backdrop-blur-sm">
              {/* A fixed stage, with the photo centred in it. Hash photos
                  are a mix of portrait and landscape, and sizing each slide to
                  its own image made the page jump on every swipe and moved the
                  arrows with it. The stage stays put; the photo centres inside
                  it whatever shape it is. */}
              <a
                href={photo.blobUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex h-[58vh] items-center justify-center sm:h-[66vh]"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={photo.blobUrl}
                  alt={photo.title ?? `Photo from ${eventName}`}
                  // The first two are what a visitor sees before scrolling;
                  // everything after that waits until it is swiped to.
                  loading={index < 2 ? "eager" : "lazy"}
                  className="max-h-full max-w-full rounded-xl object-contain"
                />
              </a>

              {/* Arrows sit ABOVE the photo's link, not inside it, or tapping
                  one would open the blob instead of moving along. Each end
                  drops its arrow rather than showing a dead one. */}
              {index > 0 && (
                <a
                  href={`#photo-${index}`}
                  aria-label="Previous photo"
                  className="absolute left-5 top-1/2 z-10 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full border border-white/25 bg-black/55 text-2xl leading-none text-white backdrop-blur-sm transition hover:bg-black/75"
                >
                  <span aria-hidden="true">‹</span>
                </a>
              )}
              {index < lastIndex && (
                <a
                  href={`#photo-${index + 2}`}
                  aria-label="Next photo"
                  className="absolute right-5 top-1/2 z-10 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full border border-white/25 bg-black/55 text-2xl leading-none text-white backdrop-blur-sm transition hover:bg-black/75"
                >
                  <span aria-hidden="true">›</span>
                </a>
              )}

              <figcaption className="mt-3 flex items-center justify-between gap-3 text-sm">
                <span className="min-w-0 truncate text-white/85">
                  {photo.title}
                  {photo.title && photo.uploaderDisplayName ? " · " : ""}
                  {photo.uploaderDisplayName}
                </span>
                <span className="flex shrink-0 items-center gap-3">
                  <a
                    href={downloadHref(photo, index)}
                    download
                    className="flex items-center gap-1.5 rounded-full border border-white/25 bg-black/45 px-3 py-1.5 text-white/90 transition hover:bg-black/70"
                  >
                    {/* Inline so it needs no icon font and no script. */}
                    <svg
                      aria-hidden="true"
                      viewBox="0 0 24 24"
                      className="h-4 w-4"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M12 3v12" />
                      <path d="m7 11 5 5 5-5" />
                      <path d="M5 21h14" />
                    </svg>
                    Download
                  </a>
                  <span className="tabular-nums text-white/55">
                    {index + 1} / {photos.length}
                  </span>
                </span>
              </figcaption>
            </figure>
          </li>
        ))}
      </ul>

      {/* Thumbnails. Fragment links rather than buttons: they move the
          carousel with no script, and they are real links, so a long press
          offers "open in new tab" the way a photo grid should. */}
      {photos.length > 1 && (
        <ol className="mt-4 flex gap-2 overflow-x-auto px-3 pb-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {photos.map((photo, index) => (
            <li key={`thumb-${photo.photoId}`} className="shrink-0">
              <a
                href={`#photo-${index + 1}`}
                aria-label={`Photo ${index + 1} of ${photos.length}`}
                className="block rounded-lg ring-1 ring-white/20 transition hover:ring-white/60 focus-visible:ring-2 focus-visible:ring-white"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={photo.blobUrl}
                  alt=""
                  loading="lazy"
                  className="h-16 w-16 rounded-lg object-cover"
                />
              </a>
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}
