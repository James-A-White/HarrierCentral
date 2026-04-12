import { notFound } from "next/navigation";
import { getKennelLandingData, type KennelLandingData } from "@/lib/api";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
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
    title: `Events | ${kennel.KennelShortName}`,
    description: `Events for ${kennel.KennelName}`,
    ...(faviconUrl && { icons: { icon: faviconUrl } }),
  };
}

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

export default async function EventsPage({ params }: PageProps) {
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
        <main className="relative z-10 mx-auto max-w-3xl px-4 pb-24 pt-32">
          <h1 className="text-3xl font-bold tracking-tight">Events</h1>
          <p className="mt-2 text-zinc-400">Coming soon.</p>
        </main>
      </body>
    </html>
  );
}
