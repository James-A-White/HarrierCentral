import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { getKennelLandingData, getSong, type KennelLandingData } from "@/lib/api";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { AudioPlayer } from "@/components/kennel/AudioPlayer";
import { Card, CardContent } from "@/components/ui/card";
import type { KennelContext } from "@/lib/types/kennel";

function parseOverlayColor(raw: string | null): {
  backgroundOverlayColor: string;
  backgroundOverlayMaxOpacity: number;
} {
  if (raw && /^#[0-9A-Fa-f]{8}$/.test(raw)) {
    const maxOpacity = parseInt(raw.slice(7, 9), 16) / 255;
    return { backgroundOverlayColor: `#${raw.slice(1, 7)}`, backgroundOverlayMaxOpacity: maxOpacity };
  }
  return {
    backgroundOverlayColor: raw && /^#[0-9A-Fa-f]{6}$/.test(raw) ? raw : "#000000",
    backgroundOverlayMaxOpacity: 0.88,
  };
}

function parseMenuBackground(raw: string | null, theme: "dark" | "light"): {
  menuBackgroundColor: string;
  menuBackgroundOpacity: number;
} {
  const s = raw?.trim() ?? "";
  if (/^#[0-9A-Fa-f]{8}$/.test(s)) {
    const maxOpacity = parseInt(s.slice(7, 9), 16) / 255;
    return { menuBackgroundColor: `#${s.slice(1, 7)}`, menuBackgroundOpacity: maxOpacity };
  }
  if (/^#[0-9A-Fa-f]{6}$/.test(s)) {
    return { menuBackgroundColor: s, menuBackgroundOpacity: 1.0 };
  }
  return theme === "dark"
    ? { menuBackgroundColor: "#09090b", menuBackgroundOpacity: 0.8 }
    : { menuBackgroundColor: "#ffffff", menuBackgroundOpacity: 0.8 };
}

interface PageProps {
  params: Promise<{ slug: string; songId: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug, songId } = await params;
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) return { title: "Song not found" };

  const song = await getSong(kennelData.PublicKennelId, songId);

  const faviconUrl = kennelData.FaviconUrl?.startsWith("https://") ? kennelData.FaviconUrl
    : kennelData.KennelLogo?.startsWith("https://") ? kennelData.KennelLogo
    : undefined;

  return {
    title: song ? `${song.SongName} | ${kennelData.KennelShortName}` : "Song not found",
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
    ...(song?.ImageUrl?.startsWith("https://") && {
      openGraph: { images: [{ url: song.ImageUrl }] },
    }),
  };
}

function toKennelContext(data: KennelLandingData): KennelContext {
  return {
    slug: data.KennelUniqueShortName,
    name: data.KennelName,
    shortName: data.KennelShortName,
    tagline: "",
    city: "",
    foundedYear: 0,
    primaryColor: data.PrimaryColor ?? "#dc2626",
    primaryFg: "#ffffff",
    accentColor: data.AccentColor ?? "#f97316",
    theme: "dark",
    titleText: data.WebsiteTitleText ?? undefined,
    titleTextColor: data.TitleTextColor ?? undefined,
    logoLetter: data.KennelShortName.charAt(0).toUpperCase(),
    logoUrl: data.KennelLogo?.startsWith("https://") ? data.KennelLogo : undefined,
    backgroundImageUrl: data.WebsiteBackgroundImage?.startsWith("https://") ? data.WebsiteBackgroundImage : undefined,
    ...parseOverlayColor(data.WebsiteBackgroundColor ?? null),
    scrollBlur: Math.min(100, Math.max(0, data.ScrollBlur ?? 0)),
    ...parseMenuBackground(data.MenuBackgroundColor ?? null, data.ThemeMode === "light" ? "light" : "dark"),
    menuTextColor: data.MenuTextColor ?? (data.ThemeMode === "light" ? "#18181b" : "#ffffff"),
    socialLinks: {},
    stats: { totalRuns: 0, activeMembers: 0, photosUploaded: 0, yearsRunning: 0 },
  };
}

const BAWDY_LEVELS: Record<number, { icon: string; count: number }> = {
  0: { icon: "😇", count: 1 },
  1: { icon: "🍺", count: 2 },
  2: { icon: "🌶️", count: 3 },
  3: { icon: "🔥", count: 4 },
};

function BawdyBadge({ rating }: { rating: number | null }) {
  if (rating === null) return null;
  const level = BAWDY_LEVELS[Math.min(Math.max(rating, 0), 3)];
  return (
    <span className="flex items-center gap-1 leading-none" aria-label={`Bawdy rating: ${rating}/3`}>
      {Array.from({ length: level.count }, (_, i) => (
        <span key={i} className="text-2xl">{level.icon}</span>
      ))}
    </span>
  );
}

export default async function SongDetailPage({ params }: PageProps) {
  const { slug, songId } = await params;

  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const song = await getSong(kennelData.PublicKennelId, songId);
  if (!song) notFound();

  const kennel = toKennelContext(kennelData);

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--kennel-primary": kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent": kennel.accentColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        {/* Back link */}
        <div className="pt-20 pb-4 mx-auto w-full max-w-3xl px-4 md:px-6">
          <Link
            href={`/${slug}/songs`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to songs
          </Link>
        </div>

        {/* Hero image — only rendered when present */}
        {song.ImageUrl?.startsWith("https://") && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={song.ImageUrl}
            alt={song.SongName}
            className="w-full h-auto block max-h-[60vh] object-cover"
          />
        )}

        <main className="mx-auto max-w-3xl px-4 py-8 pb-24 md:px-6 space-y-6">

          {/* Title block */}
          <div>
            <h1 className="text-4xl font-black dark:text-white text-zinc-900 md:text-5xl leading-tight">
              {song.SongName}
            </h1>
            {song.TuneOf && (
              <p className="mt-2 text-2xl dark:text-white text-zinc-900">
                Tune of: <em>{song.TuneOf}</em>
              </p>
            )}
            {song.BawdyRating !== null && (
              <div className="mt-3">
                <BawdyBadge rating={song.BawdyRating} />
              </div>
            )}
            {song.Tags && (
              <div className="mt-3 flex flex-wrap gap-2">
                {song.Tags.split(",").map((tag) => tag.trim()).filter(Boolean).map((tag) => (
                  <span
                    key={tag}
                    className="inline-block rounded-full px-3 py-1 text-xl font-medium dark:bg-white/[0.08] dark:text-white bg-zinc-100 text-zinc-900"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </div>

          {/* Audio player */}
          {song.AudioUrl && (
            <AudioPlayer src={song.AudioUrl} />
          )}

          {/* Lyrics */}
          {song.Lyrics && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-4">
                  Lyrics
                </h2>
                <pre className="text-2xl leading-9 dark:text-white text-zinc-900 whitespace-pre-wrap font-sans break-words">
                  {song.Lyrics}
                </pre>
              </CardContent>
            </Card>
          )}

          {/* Actions */}
          {song.Actions && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-3">
                  Actions
                </h2>
                <p className="text-2xl leading-9 dark:text-white text-zinc-900">
                  {song.Actions}
                </p>
              </CardContent>
            </Card>
          )}

          {/* Notes */}
          {song.Notes && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-3">
                  Notes
                </h2>
                <p className="text-2xl leading-9 dark:text-white text-zinc-900">
                  {song.Notes}
                </p>
              </CardContent>
            </Card>
          )}

          {/* Variants */}
          {song.Variants && (
            <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
              <CardContent className="p-5 md:p-6">
                <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-4">
                  Variants
                </h2>
                <pre className="text-2xl leading-9 dark:text-white text-zinc-900 whitespace-pre-wrap font-sans break-words">
                  {song.Variants}
                </pre>
              </CardContent>
            </Card>
          )}

        </main>
      </body>
    </html>
  );
}
