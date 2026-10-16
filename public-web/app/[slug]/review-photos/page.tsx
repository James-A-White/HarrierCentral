import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Images, Smartphone } from "lucide-react";
import { getKennelLandingData } from "@/lib/api";
import { toKennelContext } from "@/lib/kennel-utils";
import { StickyNav } from "@/components/StickyNav";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { Card, CardContent } from "@/components/ui/card";

/**
 * `/<slug>/review-photos` (E9.F1.S33, 2026-10-16): the link in the weekly
 * reminder Harrier Central posts in a kennel's Mismanagement chat. The app
 * (3.1.10+1482 and later) claims it and opens the kennel's Review photos
 * screen; this page is what everyone else lands on — no app, an older app,
 * or a desktop — so the link is never a dead end. Photo review is the app's,
 * so the page says where to go rather than pretending to do it. Not indexed.
 */
interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const kennel = await getKennelLandingData(slug);
  if (!kennel) return { title: "Kennel not found" };
  return {
    title: `Review photos | ${kennel.KennelName}`,
    robots: { index: false, follow: false },
  };
}

export default async function ReviewPhotosPage({ params }: PageProps) {
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
        "--color-accent": kennel.accentColor,
      } as React.CSSProperties}
    >
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <KennelBackground kennel={kennel} />
        <StickyNav kennel={kennel} slug={slug} alwaysVisible />

        <div className="relative z-10 pt-20 pb-4 mx-auto w-full px-4 md:px-6">
          <Link
            href={`/${slug}`}
            className="inline-flex items-center gap-2 rounded-full border px-5 py-2.5 text-xl font-semibold shadow-sm transition-colors dark:border-white/15 dark:bg-white/[0.08] dark:text-white dark:hover:bg-white/[0.14] border-zinc-300 bg-white hover:bg-zinc-50 text-zinc-900"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to {kennelData.KennelShortName}
          </Link>
        </div>

        <main className="relative z-10 mx-auto w-full max-w-2xl px-4 md:px-6 pb-16">
          <Card className="dark:bg-black/40 bg-white/90 backdrop-blur-sm">
            <CardContent className="p-6 md:p-8 text-center min-w-0">
              <Images className="mx-auto h-12 w-12 dark:text-white/80 text-zinc-700" aria-hidden />
              <h1 className="mt-4 text-3xl font-black dark:text-white text-zinc-900 md:text-4xl">
                Review {kennelData.KennelShortName}&rsquo;s photos in the app
              </h1>
              <p className="mt-4 text-xl dark:text-white/85 text-zinc-700">
                Photos waiting for review are approved in the Harrier Central app, by the
                kennel&rsquo;s photo reviewers.
              </p>
              <div className="mt-6 flex flex-col items-center gap-3 text-lg dark:text-white/80 text-zinc-700">
                <p className="flex items-start gap-2 text-left min-w-0">
                  <Smartphone className="h-5 w-5 mt-1 shrink-0" aria-hidden />
                  <span>
                    On your phone, with the app installed and up to date, this link opens the
                    kennel&rsquo;s Review photos screen directly.
                  </span>
                </p>
                <p className="text-left min-w-0">
                  Or open {kennelData.KennelShortName}&rsquo;s page in the app and tap{" "}
                  <strong>Review photos</strong>.
                </p>
              </div>
            </CardContent>
          </Card>
        </main>
      </body>
    </html>
  );
}
