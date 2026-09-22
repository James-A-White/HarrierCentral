import { notFound } from "next/navigation";
import Link from "next/link";
import { isNumeric, resolveKennelAndEvent } from "@/lib/run-resolve";
import { getRunPhotos } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { RunPhotoCarousel } from "@/components/kennel/RunPhotoCarousel";

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
  const kennel = toKennelContext(kennelData);

  return (
    // Kennel pages render their OWN html and body: app/layout.tsx is a
    // pass-through, because the theme class and the kennel's colour tokens are
    // per-kennel and have to sit on <html>. This page never did — which is why
    // it arrived white, in default fonts, with none of the kennel's styling —
    // so it now follows the run page it is reached from.
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary":    kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent":     kennel.accentColor,
        "--kennel-text-title": kennel.textTitleColor,
        "--kennel-text-body":  kennel.textBodyColor,
        "--kennel-text-muted": kennel.textMutedColor,
        "--kennel-card-bg":    kennel.cardBackgroundColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        {/* The jungle by default, the kennel's own backdrop where it has one —
            the same component every other non-hero kennel page uses, so the
            photos do not arrive looking like a different site. */}
        <KennelBackground kennel={kennel} />

        <main className="relative z-10 mx-auto max-w-4xl px-1 py-8">
          <header className="mb-6 px-3">
            <Link
              href={`/${slug}/${runNumber}`}
              className="text-sm text-white/70 hover:underline"
            >
              ← {event.EventName}
            </Link>
            <h1 className="mt-2 text-2xl font-semibold text-white">Photos</h1>
            <p className="text-sm text-white/60">
              {kennelData.KennelName}
              {photos.length > 0
                ? ` · ${photos.length} photo${photos.length === 1 ? "" : "s"}`
                : ""}
            </p>
          </header>

          {photos.length === 0 ? (
            // A run with no photos is ordinary, not a failure — say so plainly
            // rather than showing an empty frame that looks broken.
            <p className="mx-3 rounded-lg border border-white/15 bg-black/30 p-6 text-center text-white/70 backdrop-blur-sm">
              No photos have been shared for this run yet.
            </p>
          ) : (
            <RunPhotoCarousel photos={photos} eventName={event.EventName} />
          )}
        </main>
      </body>
    </html>
  );
}
