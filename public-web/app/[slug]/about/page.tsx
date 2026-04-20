import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { getKennelLandingData, type KennelLandingData } from "@/lib/api";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { Card, CardContent } from "@/components/ui/card";
import type { KennelContext } from "@/lib/types/kennel";

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
    title: `About | ${kennel.KennelName}`,
    description: kennel.KennelDescription ?? `About ${kennel.KennelName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
  };
}

function toKennelContext(data: KennelLandingData): KennelContext {
  const hasCustomBackground = data.WebsiteBackgroundImage?.startsWith("https://") ?? false;
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
    backgroundImageUrl: hasCustomBackground ? data.WebsiteBackgroundImage! : "/images/jungle_background.jpg",
    backgroundOverlayColor: "#000000",
    backgroundOverlayMaxOpacity: 0.88,
    scrollBlur: Math.min(100, Math.max(0, data.ScrollBlur ?? 0)),
    menuBackgroundColor: data.MenuBackgroundColor ?? "#09090b",
    menuBackgroundOpacity: 0.8,
    menuTextColor: data.MenuTextColor ?? "#ffffff",
    socialLinks: {},
    stats: { totalRuns: 0, activeMembers: 0, photosUploaded: 0, yearsRunning: 0 },
  };
}

export default async function AboutPage({ params }: PageProps) {
  const { slug } = await params;
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) notFound();

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

        <div className="relative z-10 pt-20 pb-4 mx-auto w-full max-w-3xl px-4 md:px-6">
          <Link
            href={`/${slug}`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-base font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ArrowLeft className="h-4 w-4" />
            <span className="sm:hidden">Back</span>
            <span className="hidden sm:inline">Back to {kennelData.KennelShortName}</span>
          </Link>
        </div>

        <main className="relative z-10 mx-auto w-full max-w-3xl px-4 pb-24 md:px-6">
          <h1 className="text-4xl font-black dark:text-white text-zinc-900 mb-6 md:text-5xl">
            About {kennelData.KennelName}
          </h1>

          <Card className="rounded-2xl dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white">
            <CardContent className="p-6 md:p-8">
              <p className="text-lg leading-relaxed dark:text-white/70 text-zinc-600">
                More information about this kennel is coming soon.
              </p>
            </CardContent>
          </Card>
        </main>
      </body>
    </html>
  );
}
