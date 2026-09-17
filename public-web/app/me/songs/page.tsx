import type { Metadata } from "next";
import { getAllSongs } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { SongsSection } from "@/components/kennel/SongsSection";

export const metadata: Metadata = { title: "Songs" };

/**
 * The app's Songs tab: the whole songbook in one list with the search,
 * not grouped by kennel (James, 2026-09-17: "I think the app shows all
 * songs, and you only see the kennel songbook when you are in run
 * tools"). The app reads every row of its synced songs table, ordered by
 * name, and this is the same set.
 */
export default async function MySongsPage() {
  const s = await requireMember();
  const songs = await getAllSongs(s).catch(() => []);

  return (
    <div className="-mx-3 -mt-3 sm:-mt-4">
      {songs.length === 0 ? (
        <p className="px-3 py-8 text-center text-white/90">No songs have been published yet.</p>
      ) : (
        <SongsSection songs={songs} slug="" linkBase="/me/songs" />
      )}
    </div>
  );
}
