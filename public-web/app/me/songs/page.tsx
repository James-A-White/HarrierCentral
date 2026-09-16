import type { Metadata } from "next";
import Link from "next/link";
import { getSongs } from "@/lib/api";
import { getMyKennels } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { SongsSection } from "@/components/kennel/SongsSection";

export const metadata: Metadata = { title: "Songs" };

/** The songbooks of the kennels I follow, one section each. */
export default async function MySongsPage() {
  const s = await requireMember();
  const kennels = (await getMyKennels(s).catch(() => [])).filter((k) => k.Following === 1 || k.IsHomeKennel === 1);
  const books = await Promise.all(
    kennels.map(async (k) => ({ kennel: k, songs: await getSongs(k.PublicKennelId).catch(() => []) })),
  );
  const withSongs = books.filter((b) => b.songs.length > 0);
  return (
    <div className="space-y-10">
      <h1 className="text-xl font-bold">Songs</h1>
      {withSongs.length === 0 && (
        <p className="text-zinc-300">
          None of the kennels you follow has published a songbook yet.{" "}
          <Link href="/me/kennels" className="underline underline-offset-2">Follow more kennels</Link>
        </p>
      )}
      {withSongs.map(({ kennel, songs }) => (
        <section key={kennel.PublicKennelId}>
          <h2 className="mb-3 flex items-center gap-3 text-lg font-bold">
            {kennel.KennelLogo?.startsWith("https://") && (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={kennel.KennelLogo} alt="" className="h-8 w-8 object-contain" />
            )}
            {kennel.KennelShortName} · {songs.length} song{songs.length === 1 ? "" : "s"}
          </h2>
          <SongsSection songs={songs} slug={kennel.KennelSlug} />
        </section>
      ))}
    </div>
  );
}
