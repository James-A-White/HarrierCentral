import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { getAllSongs } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { AudioPlayer } from "@/components/kennel/AudioPlayer";

interface PageProps {
  params: Promise<{ songId: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { songId } = await params;
  const s = await requireMember();
  const [song] = await getAllSongs(s, songId).catch(() => []);
  return { title: song?.SongName ?? "Song" };
}

const BAWDY = ["😇", "🌶️", "🔥", "🍺"];

/**
 * One song from the member songbook, in the member chrome, so the reader
 * never leaves /me and always has a way back. The kennel-branded version
 * of this page still lives at /[slug]/songs/[songId] for public visitors.
 */
export default async function MemberSongPage({ params }: PageProps) {
  const { songId } = await params;
  if (!/^[0-9a-f-]{36}$/i.test(songId)) notFound();
  const s = await requireMember();
  const [song] = await getAllSongs(s, songId).catch(() => []);
  if (!song) notFound();

  const tags = (song.Tags ?? "").split(",").map((t) => t.trim()).filter(Boolean);

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href="/me/songs" aria-label="Back to songs" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">Songs</h2>
        <span className="w-4" />
      </div>

      {song.ImageUrl?.startsWith("https://") && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={song.ImageUrl} alt="" className="max-h-72 w-full object-cover" />
      )}

      <div className="px-4 pt-5 text-white">
        <h1 className="text-[32px] font-black leading-tight">{song.SongName}</h1>
        {song.TuneOf && <p className="mt-1 text-[20px] italic text-white/80">Tune of: {song.TuneOf}</p>}
        <div className="mt-2 flex flex-wrap items-center gap-2">
          {song.BawdyRating !== null && (
            <span aria-label={`Bawdy rating ${song.BawdyRating} of 3`} className="text-[20px] leading-none">
              {BAWDY[Math.min(Math.max(song.BawdyRating, 0), 3)]}
            </span>
          )}
          {tags.map((tag) => (
            <span key={tag} className="rounded-full bg-white/10 px-3 py-1 text-[14px] text-white/85">{tag}</span>
          ))}
        </div>
        {song.AudioUrl?.startsWith("https://") && <div className="mt-4"><AudioPlayer src={song.AudioUrl} /></div>}
      </div>

      <Block title="Lyrics" body={song.Lyrics} />
      <Block title="Actions" body={song.Actions} />
      <Block title="Variants" body={song.Variants} />
      <Block title="Notes" body={song.Notes} />
    </div>
  );
}

function Block({ title, body }: { title: string; body: string | null }) {
  if (!body?.trim()) return null;
  return (
    <section className="mx-3 mt-5 rounded-xl bg-black/30 p-4">
      <h2 className="mb-3 text-[15px] uppercase tracking-[0.15em] text-yellow-300">{title}</h2>
      <pre className="whitespace-pre-wrap break-words font-sans text-[20px] leading-8 text-white">{body}</pre>
    </section>
  );
}
