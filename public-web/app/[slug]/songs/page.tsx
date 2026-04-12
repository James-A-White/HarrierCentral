import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Music2 } from "lucide-react";
import { getKennelLandingData, getSongs, type KennelLandingData } from "@/lib/api";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { SongsSection } from "@/components/kennel/SongsSection";
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

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);
  if (!kennel) return { title: "Kennel not found" };

  const faviconUrl = kennel.FaviconUrl?.startsWith("https://") ? kennel.FaviconUrl
    : kennel.KennelLogo?.startsWith("https://") ? kennel.KennelLogo
    : undefined;

  return {
    title: `Songs | ${kennel.KennelShortName}`,
    description: `Song book for ${kennel.KennelName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
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
    primaryColor: "#dc2626",
    primaryFg: "#ffffff",
    accentColor: "#f97316",
    theme: "dark",
    titleText: data.WebsiteTitleText ?? undefined,
    titleTextColor: data.TitleTextColor ?? undefined,
    logoLetter: data.KennelShortName.charAt(0).toUpperCase(),
    logoUrl: data.KennelLogo?.startsWith("https://") ? data.KennelLogo : undefined,
    backgroundImageUrl: data.WebsiteBackgroundImage?.startsWith("https://") ? data.WebsiteBackgroundImage : undefined,
    ...parseOverlayColor(data.WebsiteBackgroundColor ?? null),
    scrollBlur: Math.min(100, Math.max(0, data.ScrollBlur ?? 0)),
    socialLinks: {},
    stats: { totalRuns: 0, activeMembers: 0, photosUploaded: 0, yearsRunning: 0 },
  };
}

export default async function SongsPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

  const [songs] = await Promise.all([
    getSongs(kennelData.PublicKennelId),
  ]);

  const kennel = toKennelContext(kennelData);

  return (
    <html
      lang="en"
      className="dark"
      style={{
        "--color-primary": kennel.primaryColor,
        "--color-primary-fg": kennel.primaryFg,
        "--color-accent": kennel.accentColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        <div className="pt-20 pb-4 mx-auto w-full max-w-3xl px-4 md:px-6">
          <Link
            href={`/${slug}`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to {kennelData.KennelShortName}
          </Link>
        </div>

        <main className="mx-auto max-w-3xl px-4 pb-24 md:px-6">
          {songs.length === 0 ? (
            <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white p-12 flex flex-col items-center gap-3 text-center">
              <Music2 className="h-8 w-8 dark:text-white/20 text-zinc-300" />
              <p className="text-2xl dark:text-white text-zinc-900">
                No songs have been added yet.
              </p>
            </div>
          ) : (
            <SongsSection songs={songs} slug={slug} />
          )}
        </main>
      </body>
    </html>
  );
}
