import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, ExternalLink } from "lucide-react";
import { getKennelLandingData, getEvents } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { RunDetail } from "@/components/kennel/RunDetail";

interface PageProps {
  params: Promise<{ slug: string; guestSlug: string; guestRunNumber: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug, guestSlug, guestRunNumber } = await params;
  const guestRunNum = parseInt(guestRunNumber, 10);
  if (isNaN(guestRunNum)) return { title: "Run not found" };

  const [hostData, guestData] = await Promise.all([
    getKennelLandingData(slug),
    getKennelLandingData(guestSlug),
  ]);
  if (!hostData || !guestData) return { title: "Run not found" };

  return {
    title: `${guestData.KennelShortName} Run #${guestRunNum} | ${hostData.KennelShortName}`,
    description: `Run #${guestRunNum} by ${guestData.KennelName}`,
  };
}

export default async function GuestRunPage({ params }: PageProps) {
  const { slug, guestSlug, guestRunNumber } = await params;

  const guestRunNum = parseInt(guestRunNumber, 10);
  if (isNaN(guestRunNum)) notFound();

  // Load both kennels and guest runs in parallel
  const [hostKennelData, guestKennelData] = await Promise.all([
    getKennelLandingData(slug),
    getKennelLandingData(guestSlug),
  ]);

  if (!hostKennelData) notFound();
  if (!guestKennelData) notFound();

  const [futureResult, pastResult] = await Promise.all([
    getEvents(guestKennelData.PublicKennelId, { isFuture: true,  daysOffset: 365 }),
    getEvents(guestKennelData.PublicKennelId, { isFuture: false, daysOffset: 730 }),
  ]);

  const event = [
    ...(futureResult?.events ?? []),
    ...(pastResult?.events  ?? []),
  ].find((e) => e.EventNumber === guestRunNum);

  if (!event) notFound();

  const hostKennel  = toKennelContext(hostKennelData);
  const guestDetail = {
    name:     guestKennelData.KennelName,
    shortName: guestKennelData.KennelShortName,
    logoUrl:  guestKennelData.KennelLogo ?? undefined,
  };

  const navBtnClass =
    "inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50";

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary":       hostKennel.primaryColor,
        "--kennel-primary-fg":    hostKennel.primaryFg,
        "--kennel-accent":        hostKennel.accentColor,
        "--kennel-text-title":    hostKennel.textTitleColor,
        "--kennel-text-body":     hostKennel.textBodyColor,
        "--kennel-text-muted":    hostKennel.textMutedColor,
        "--kennel-card-bg":       hostKennel.cardBackgroundColor,
        "--kennel-btn-primary":   hostKennel.buttonPrimaryColor,
        "--kennel-btn-cancel":    hostKennel.buttonCancelColor,
        "--kennel-btn-secondary": hostKennel.buttonSecondaryColor,
        "--kennel-run-card-bg":   hostKennel.runCardBackgroundColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={hostKennel} />
        <StickyNav kennel={hostKennel} slug={slug} alwaysVisible />

        {/* Back + external link row */}
        <div
          className="relative z-10 pb-3 mx-auto w-full px-4 md:px-6 flex items-center justify-between gap-3"
          style={{ paddingTop: "calc(80px + 1rem)" }}
        >
          <Link href={`/${slug}`} className={navBtnClass} style={{ color: "var(--kennel-text-body)" }}>
            <ArrowLeft className="h-3.5 w-3.5" />
            <span className="sm:hidden">Back</span>
            <span className="hidden sm:inline">Back to {hostKennelData.KennelShortName}</span>
          </Link>
          <a
            href={`https://www.hashruns.org/${guestSlug}/${guestRunNumber}`}
            target="_blank"
            rel="noopener noreferrer"
            className={navBtnClass}
            style={{ color: "var(--kennel-text-body)" }}
          >
            <ExternalLink className="h-3.5 w-3.5" />
            <span className="sm:hidden">{guestKennelData.KennelShortName}</span>
            <span className="hidden sm:inline">View on {guestKennelData.KennelShortName} site</span>
          </a>
        </div>

        {/* Guest kennel attribution pill */}
        <div className="relative z-10 mx-auto w-full max-w-lg px-4 pb-3 md:px-6">
          <div
            className="inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm dark:border-white/10 border-zinc-200"
            style={{ color: "var(--kennel-text-muted)", backgroundColor: "var(--kennel-card-bg)" }}
          >
            {guestKennelData.KennelLogo && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={guestKennelData.KennelLogo}
                alt={guestKennelData.KennelShortName}
                className="h-5 w-5 shrink-0 object-contain"
              />
            )}
            <span>
              A run by{" "}
              <strong style={{ color: "var(--kennel-text-body)" }}>
                {guestKennelData.KennelName}
              </strong>
            </span>
          </div>
        </div>

        {/* Hero image */}
        {event.EventImage && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={event.EventImage}
            alt={event.EventName}
            className="relative z-10 w-full h-auto block"
          />
        )}

        {/* Detail card */}
        <main className="relative z-10 mx-auto w-full max-w-lg px-4 py-6 md:px-6">
          <div
            className="rounded-2xl border border-white/[0.08] p-5"
            style={{ backgroundColor: "var(--kennel-card-bg)" }}
          >
            <RunDetail
              run={event}
              kennel={guestDetail}
              canonicalPath={`/${slug}/guest/${guestSlug}/${guestRunNumber}`}
            />
          </div>
        </main>
      </body>
    </html>
  );
}
