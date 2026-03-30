"use client";

import { useState, useMemo } from "react";
import { motion } from "framer-motion";
import { Music2, Search, ChevronRight, Volume2 } from "lucide-react";
import Link from "next/link";
import type { Song } from "@/lib/api";

interface SongsSectionProps {
  songs: Song[];
  slug: string;
}

const BAWDY_LEVELS: Record<number, { icon: string; count: number }> = {
  0: { icon: "😇", count: 1 },
  1: { icon: "🍺", count: 2 },
  2: { icon: "🌶️", count: 3 },
  3: { icon: "🔥", count: 4 },
};

function BawdyRating({ rating }: { rating: number | null }) {
  if (rating === null) return null;
  const level = BAWDY_LEVELS[Math.min(Math.max(rating, 0), 3)];
  return (
    <span className="flex items-center shrink-0 leading-none" aria-label={`Bawdy rating: ${rating}/3`}>
      {Array.from({ length: level.count }, (_, i) => (
        <span key={i} className="text-lg">{level.icon}</span>
      ))}
    </span>
  );
}

function SongRow({ song, slug, index }: { song: Song; slug: string; index: number }) {
  return (
    <motion.div
      className="border-b dark:border-white/[0.07] border-zinc-100 last:border-0"
      initial={{ opacity: 0, y: 10 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-40px" }}
      transition={{
        duration: 0.4,
        delay: Math.min(index * 0.04, 0.3),
        ease: [0.19, 1, 0.22, 1],
      }}
    >
      <Link
        href={`/${slug}/songs/${song.id}`}
        className="flex items-center gap-4 py-4 group"
      >
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
            <span className="text-2xl font-semibold dark:text-white text-zinc-900 transition-colors group-hover:dark:text-white group-hover:text-zinc-900">
              {song.SongName}
            </span>
            {song.TuneOf && (
              <span className="text-xl dark:text-white text-zinc-900">
                Tune of: <em>{song.TuneOf}</em>
              </span>
            )}
          </div>
          {song.Tags && (
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {song.Tags.split(",").map((tag) => tag.trim()).filter(Boolean).map((tag) => (
                <span
                  key={tag}
                  className="inline-block rounded-full px-2.5 py-0.5 text-base font-medium dark:bg-white/[0.08] dark:text-white bg-zinc-100 text-zinc-900"
                >
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {song.AudioUrl && (
            <Volume2 className="h-4 w-4 dark:text-white/30 text-zinc-400" />
          )}
          <BawdyRating rating={song.BawdyRating} />
          <ChevronRight className="h-4 w-4 dark:text-white/20 text-zinc-300 transition-colors group-hover:dark:text-white/60 group-hover:text-zinc-500" />
        </div>
      </Link>
    </motion.div>
  );
}

export function SongsSection({ songs, slug }: SongsSectionProps) {
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) return songs;
    return songs.filter(
      (s) =>
        s.SongName.toLowerCase().includes(q) ||
        (s.TuneOf?.toLowerCase().includes(q) ?? false) ||
        (s.Lyrics?.toLowerCase().includes(q) ?? false) ||
        (s.Notes?.toLowerCase().includes(q) ?? false) ||
        (s.Tags?.toLowerCase().includes(q) ?? false)
    );
  }, [songs, query]);

  if (songs.length === 0) return null;

  return (
    <section id="songs" className="mt-8">
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-80px" }}
        transition={{ duration: 0.6, ease: [0.19, 1, 0.22, 1] }}
        className="rounded-[2rem] overflow-hidden dark:border dark:border-white/[0.08] border border-zinc-200 dark:bg-white/[0.04] bg-white"
      >
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-4 px-6 py-5 border-b dark:border-white/[0.07] border-zinc-100">
          <div className="flex items-center gap-3">
            <Music2 className="h-5 w-5 dark:text-white/40 text-zinc-400 shrink-0" />
            <h2 className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900">
              Songs
            </h2>
            <span className="text-xl dark:text-white text-zinc-900 tabular-nums">
              {songs.length}
            </span>
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 dark:text-white/30 text-zinc-400 pointer-events-none" />
            <input
              type="search"
              placeholder="Search songs…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="h-10 w-60 rounded-full border pl-9 pr-4 text-xl outline-none transition-colors dark:border-white/10 dark:bg-white/[0.06] dark:text-white dark:placeholder:text-white focus:dark:ring-2 focus:dark:ring-white/20 border-zinc-200 bg-zinc-50 text-zinc-900 placeholder:text-zinc-700 focus:ring-2 focus:ring-zinc-300"
            />
          </div>
        </div>

        {/* Song list */}
        <div className="px-6">
          {filtered.length === 0 ? (
            <p className="py-10 text-center text-xl dark:text-white text-zinc-900">
              No songs match &ldquo;{query}&rdquo;
            </p>
          ) : (
            filtered.map((song, i) => (
              <SongRow key={song.id} song={song} slug={slug} index={i} />
            ))
          )}
        </div>
      </motion.div>
    </section>
  );
}
