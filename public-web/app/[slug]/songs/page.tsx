import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Music2 } from "lucide-react";
import { getKennelLandingData, getSongs } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { SongsSection } from "@/components/kennel/SongsSection";

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
        "--kennel-primary": kennel.primaryColor,
        "--kennel-primary-fg": kennel.primaryFg,
        "--kennel-accent": kennel.accentColor,
        "--kennel-text-title": kennel.textTitleColor,
        "--kennel-text-body": kennel.textBodyColor,
        "--kennel-text-muted": kennel.textMutedColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        <div className="pt-20 pb-4 mx-auto w-full max-w-3xl px-4 md:px-6">
          <Link
            href={`/${slug}`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50"
            style={{ color: "var(--kennel-text-body)" }}
          >
            <ArrowLeft className="h-4 w-4" />
            Back to {kennelData.KennelShortName}
          </Link>
        </div>

        <main className="mx-auto max-w-3xl px-4 pb-24 md:px-6">
          {songs.length === 0 ? (
            <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white p-12 flex flex-col items-center gap-3 text-center">
              <Music2 className="h-8 w-8" style={{ color: "var(--kennel-text-muted)" }} />
              <p className="text-2xl" style={{ color: "var(--kennel-text-body)" }}>
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
