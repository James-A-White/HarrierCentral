export const revalidate = 300;

import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, MapPin, Clock, Users, Tag, ExternalLink, Navigation } from "lucide-react";
import { getKennelLandingData, getEvents, type KennelLandingData, type RunEvent } from "@/lib/api";
import { BrowserLocalTime } from "@/components/kennel/BrowserLocalTime";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { Card, CardContent } from "@/components/ui/card";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const [kennel, event] = await resolveKennelAndRun(slug);
  if (!kennel) return { title: "Kennel not found" };
  if (!event) return { title: `No past runs | ${kennel.KennelName}` };

  const faviconUrl = kennel.FaviconUrl?.startsWith("https://") ? kennel.FaviconUrl
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  return {
    title: `Last Run | ${kennel.KennelName}`,
    description: `The most recent run for ${kennel.KennelName}: ${event.EventName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    alternates: { canonical: `/${slug}/${event.EventNumber}` },
    ...(event.EventImage?.startsWith("https://") && {
      openGraph: { images: [{ url: event.EventImage }] },
    }),
  };
}

// ── Data fetcher ───────────────────────────────────────────────────────────────

async function resolveKennelAndRun(
  slug: string
): Promise<[KennelLandingData | null, RunEvent | null]> {
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) return [null, null];

  const result = await getEvents(kennelData.PublicKennelId, { isFuture: false, maxEvents: 1 });
  const event = result?.events[0] ?? null;
  return [kennelData, event];
}


// ── Helpers ────────────────────────────────────────────────────────────────────

function formatDateLong(run: RunEvent): { date: string; kennelTime: string } {
  const gmt = run.EventStartDatetimeGmt;
  const tz  = run.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  return {
    date: src.toLocaleDateString("en-GB", {
      weekday: "long", day: "numeric", month: "long", year: "numeric",
      timeZone: displayTz,
    }),
    kennelTime: new Intl.DateTimeFormat("en-GB", {
      hour: "2-digit", minute: "2-digit", timeZoneName: "short",
      timeZone: displayTz,
    }).format(src),
  };
}

function formatFee(amount: number | null, currency: string | null): string {
  if (!amount || amount === 0) return "Free";
  return currency ? `${currency} ${amount.toFixed(2)}` : amount.toFixed(2);
}

function mapsUrl(lat: number | null, lon: number | null, label: string): string | null {
  if (!lat || !lon) return null;
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}&query_place_id=${encodeURIComponent(label)}`;
}

function parseW3w(json: string | null): string | null {
  if (!json) return null;
  try {
    const parsed = JSON.parse(json) as { map?: string; words?: string };
    return parsed.map ?? (parsed.words ? `https://what3words.com/${parsed.words}` : null);
  } catch {
    return null;
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex gap-3 py-3 border-b dark:border-white/[0.07] border-zinc-100 last:border-0">
      <span className="w-32 shrink-0 text-xl uppercase tracking-[0.12em] dark:text-white text-zinc-900 pt-0.5">
        {label}
      </span>
      <span className="text-2xl dark:text-white text-zinc-900 font-medium">{value}</span>
    </div>
  );
}

// ── Page ───────────────────────────────────────────────────────────────────────

export default async function LastRunPage({ params }: PageProps) {
  const { slug } = await params;
  const [kennelData, event] = await resolveKennelAndRun(slug);

  if (!kennelData) notFound();
  if (!event) notFound();

  const kennel = toKennelContext(kennelData);
  const { date, kennelTime } = formatDateLong(event);
  const mapsLink = mapsUrl(event.Latitude, event.Longitude, event.LocationOneLineDesc ?? event.EventName);
  const w3wLink = parseW3w(event.w3wJson);

  const locationParts = [
    event.LocationOneLineDesc,
    event.LocationStreet,
    event.LocationCity,
    event.LocationPostCode,
  ].filter(Boolean).join(", ");

  const BADGE = "inline-flex rounded-full border dark:border-white/20 border-zinc-200 dark:bg-white/10 bg-zinc-100 px-3 py-1 text-base font-semibold dark:text-white/90 text-zinc-700";

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary": kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--color-accent": kennel.accentColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        {/* Back button */}
        <div className="relative z-10 pt-20 pb-4 mx-auto w-full px-4 md:px-6">
          <Link
            href={`/${slug}`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to {kennelData.KennelShortName}
          </Link>
        </div>

        {/* Hero — image or gradient fallback */}
        {event.EventImage ? (
          <>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={event.EventImage} alt={event.EventName} className="w-full h-auto block" />
            <div className="relative z-10 mx-auto w-full px-4 md:px-6 pt-6 pb-2">
              <div className="flex flex-wrap items-center gap-2 mb-3">
                <span className={BADGE}>Last Run</span>
                <span className={BADGE}>#{event.EventNumber}</span>
                {event.EventTypeName && <span className={BADGE}>{event.EventTypeName}</span>}
              </div>
              <h1 className="text-4xl font-black dark:text-white text-zinc-900 md:text-5xl">{event.EventName}</h1>
              <p className="mt-2 text-2xl dark:text-white text-zinc-900" suppressHydrationWarning>
                {date} · {kennelTime}
              </p>
            </div>
          </>
        ) : (
          <div
            className="relative z-10 min-h-[35vh] flex flex-col justify-end pb-10"
            style={{
              backgroundImage: `linear-gradient(160deg, color-mix(in srgb, var(--kennel-primary) 30%, transparent) 0%, color-mix(in srgb, var(--kennel-primary) 55%, #09090b) 100%)`,
            }}
          >
            <div className="mx-auto w-full px-4 md:px-6">
              <div className="flex flex-wrap items-center gap-2 mb-3">
                <span className={BADGE}>Last Run</span>
                <span className={BADGE}>#{event.EventNumber}</span>
                {event.EventTypeName && <span className={BADGE}>{event.EventTypeName}</span>}
              </div>
              <h1 className="text-4xl font-black text-white md:text-5xl">{event.EventName}</h1>
              <p className="mt-2 text-2xl text-white" suppressHydrationWarning>
                {date} · {kennelTime}
              </p>
            </div>
          </div>
        )}

        {/* Main content */}
        <main className="relative z-10 mx-auto w-full px-4 py-10 md:px-6 space-y-6">

          {/* Details card */}
          <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
            <CardContent className="p-5 md:p-6">
              <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-1">
                Run details
              </h2>

              {event.Hares && (
                <DetailRow
                  label="Hares"
                  value={
                    <span className="flex items-center gap-1.5">
                      <Users className="h-4 w-4 dark:text-white/40 text-zinc-400 shrink-0" />
                      {event.Hares}
                    </span>
                  }
                />
              )}

              <DetailRow
                label="Date"
                value={
                  <span suppressHydrationWarning>
                    <span className="flex items-center gap-1.5">
                      <Clock className="h-4 w-4 dark:text-white/40 text-zinc-400 shrink-0" />
                      {date} at {kennelTime}
                    </span>
                    {event.EventStartDatetimeGmt && (
                      <BrowserLocalTime
                        gmtIso={event.EventStartDatetimeGmt}
                        kennelFormatted={kennelTime}
                        className="block text-base opacity-60 mt-0.5 ml-5"
                      />
                    )}
                  </span>
                }
              />

              {locationParts && (
                <DetailRow
                  label="Location"
                  value={
                    <span className="flex items-start gap-1.5">
                      <MapPin className="h-4 w-4 dark:text-white/40 text-zinc-400 shrink-0 mt-0.5" />
                      {locationParts}
                    </span>
                  }
                />
              )}

              {(event.EventPriceForMembers !== null || event.EventPriceForNonMembers !== null) && (
                <DetailRow
                  label="Fees"
                  value={
                    <span>
                      {formatFee(event.EventPriceForMembers, event.EventCurrencyType)} members
                      {event.EventPriceForNonMembers !== null && (
                        <span className="dark:text-white text-zinc-900">
                          {" "}· {formatFee(event.EventPriceForNonMembers, event.EventCurrencyType)} non-members
                        </span>
                      )}
                    </span>
                  }
                />
              )}
            </CardContent>
          </Card>

          {/* Permalink note */}
          <p className="text-xl dark:text-white/50 text-zinc-500">
            Permanent link:{" "}
            <Link href={`/${slug}/${event.EventNumber}`} className="underline dark:text-white/70 text-zinc-700">
              /{slug}/{event.EventNumber}
            </Link>
          </p>

          {/* Action buttons */}
          {(mapsLink || w3wLink || event.EventUrl) && (
            <div className="flex flex-wrap gap-3">
              {mapsLink && (
                <a
                  href={mapsLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
                >
                  <Navigation className="h-4 w-4" />
                  Open in Maps
                </a>
              )}
              {w3wLink && (
                <a
                  href={w3wLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
                >
                  ///
                  What3Words
                </a>
              )}
              {event.EventUrl && (
                <a
                  href={event.EventUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold transition-colors dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.10] border-zinc-200 bg-white hover:bg-zinc-50 text-zinc-900"
                >
                  <ExternalLink className="h-4 w-4" />
                  Event page
                </a>
              )}
            </div>
          )}

          {/* Tags */}
          {event.tags.length > 0 && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-3 flex items-center gap-1.5">
                  <Tag className="h-4 w-4" />
                  Tags
                </h2>
                <div className="flex flex-wrap gap-2">
                  {event.tags.map((tag) => (
                    <span
                      key={tag}
                      className="inline-flex rounded-full border px-3 py-1 text-xl font-medium dark:border-white/10 dark:bg-white/5 dark:text-white border-zinc-200 bg-zinc-50 text-zinc-900"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Description */}
          {event.EventDescription && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-3">
                  About this run
                </h2>
                <p className="text-2xl leading-9 dark:text-white text-zinc-900 whitespace-pre-wrap">
                  {event.EventDescription}
                </p>
              </CardContent>
            </Card>
          )}

        </main>
      </body>
    </html>
  );
}
