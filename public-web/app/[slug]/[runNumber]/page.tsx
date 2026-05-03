import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Home } from "lucide-react";
import { getKennelLandingData, getEvents, type KennelLandingData, type RunEvent } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { RunDetail } from "@/components/kennel/RunDetail";

interface PageProps {
  params: Promise<{ slug: string; runNumber: string }>;
  searchParams: Promise<{ back?: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug, runNumber } = await params;
  const [kennel, event] = await resolveKennelAndEvent(slug, runNumber);
  if (!kennel || !event) return { title: "Run not found" };

  const faviconUrl = kennel.FaviconUrl?.startsWith("https://") ? kennel.FaviconUrl
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  const plainDescription = event.EventDescription
    ? event.EventDescription.replace(/<[^>]*>/g, "").slice(0, 160)
    : `Run #${event.EventNumber} — ${kennel.KennelName}`;

  return {
    title: `${event.EventName} | ${kennel.KennelName}`,
    description: plainDescription,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    ...(event.EventImage?.startsWith("https://") && {
      openGraph: { images: [{ url: event.EventImage }] },
    }),
  };
}

// ── Shared data fetcher ────────────────────────────────────────────────────────

async function resolveKennelAndEvent(
  slug: string,
  runNumber: string
): Promise<[KennelLandingData | null, RunEvent | null]> {
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) return [null, null];

  const num = parseInt(runNumber, 10);
  if (isNaN(num)) return [kennelData, null];

  const [futureResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  daysOffset: 365 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 730 }),
  ]);

  const allEvents = [
    ...(futureResult?.events ?? []),
    ...(pastResult?.events  ?? []),
  ];

  const event = allEvents.find((e) => e.EventNumber === num) ?? null;
  return [kennelData, event];
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default async function RunDetailPage({ params, searchParams }: PageProps) {
  const { slug, runNumber } = await params;
  const { back } = await searchParams;
  const [kennelData, event] = await resolveKennelAndEvent(slug, runNumber);

  if (!kennelData) notFound();
  if (!event) notFound();

  const kennel = toKennelContext(kennelData);

  const backHref = back ?? `/${slug}`;
  const showKennelHomeBtn = !!back && back !== `/${slug}`;
  let backLabel = `Back to ${kennelData.KennelShortName}`;
  if (back === `/${slug}/runs`) backLabel = "Back to runs";
  else if (back === "/") backLabel = "Back to global runs";
  else if (back === "/calendar") backLabel = "Back to calendar";
  else if (back && back !== `/${slug}`) backLabel = "Back";

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary": kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent": kennel.accentColor,
        "--kennel-text-title": kennel.textTitleColor,
        "--kennel-text-body": kennel.textBodyColor,
        "--kennel-text-muted": kennel.textMutedColor,
        "--kennel-card-bg": kennel.cardBackgroundColor,
        "--kennel-btn-primary": kennel.buttonPrimaryColor,
        "--kennel-btn-cancel": kennel.buttonCancelColor,
        "--kennel-btn-secondary": kennel.buttonSecondaryColor,
        "--kennel-run-card-bg": kennel.runCardBackgroundColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        {/* Back navigation */}
        <div
          className="relative z-10 pb-4 mx-auto w-full px-4 md:px-6 flex items-center justify-between gap-3"
          style={{ paddingTop: "calc(80px + 1rem)" }}
        >
          <Link
            href={backHref}
            className="inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50"
            style={{ color: "var(--kennel-text-body)" }}
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            <span className="sm:hidden">Back</span>
            <span className="hidden sm:inline">{backLabel}</span>
          </Link>
          {showKennelHomeBtn && (
            <Link
              href={`/${slug}`}
              className="inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50"
              style={{ color: "var(--kennel-text-body)" }}
            >
              <Home className="h-3.5 w-3.5" />
              {kennelData.KennelShortName}
            </Link>
          )}
        </div>

        {/* Hero image */}
        {event.EventImage && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={event.EventImage} alt={event.EventName} className="relative z-10 w-full h-auto block" />
        )}

        {/* Detail card */}
        <main className="relative z-10 mx-auto w-full max-w-lg px-4 py-6 md:px-6">
          <div className="rounded-2xl border border-white/[0.08] p-5" style={{ backgroundColor: "var(--kennel-card-bg)" }}>
            <RunDetail run={event} kennel={kennel} />
          </div>
        </main>
      </body>
    </html>
  );
}
