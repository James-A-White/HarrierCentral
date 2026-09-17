import type { Metadata } from "next";
import { getAllSongs } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { SongsView } from "@/components/member/SongsView";

export const metadata: Metadata = { title: "Songs" };

/**
 * The app's Songs tab: the whole songbook in one list, not grouped by
 * kennel (a kennel's own songbook stays on the kennel's pages). The UI is
 * mirrored from songs_page.dart — see SongsView.
 */
export default async function MySongsPage() {
  const s = await requireMember();
  const songs = await getAllSongs(s).catch(() => []);
  return <SongsView songs={songs} />;
}
