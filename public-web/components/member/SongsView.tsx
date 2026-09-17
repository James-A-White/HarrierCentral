"use client";

/**
 * The app's Songs tab (songs_page.dart + songs_page_controller.dart),
 * mirrored: the white search bar with its shadow and X, the four naughty
 * chips, and the white song cards with the tick, the artwork, the name,
 * "Tune of:" in the condensed face and the rating on the right.
 *
 * Search and chips are FIXED at the top while the list scrolls, as the app
 * pins them above a list positioned 92px down.
 *
 * Kept faithful to the app's behaviour: all four chips start active, a song
 * passes when its rating (clamped 0..3) is in the active set, and the search
 * matches name, tune, tags and lyrics.
 */
import { useMemo, useState } from "react";
import Link from "next/link";
import { Search, Music2 } from "lucide-react";
import type { Song } from "@/lib/api";

/** songs_page_controller.bawdyIcons */
const BAWDY: Record<number, string> = { 0: "😇", 1: "🍺🍺", 2: "🌶️🌶️🌶️", 3: "🔥🔥🔥🔥" };
const RATINGS = [0, 1, 2, 3];

/** themeButtonColors; themeLightBackground is Colors.yellow.shade100. */
const THEME_BUTTON = "#6C0243";

const clamp = (n: number | null) => Math.min(Math.max(n ?? 0, 0), 3);

export function SongsView({ songs }: { songs: Song[] }) {
  const [query, setQuery] = useState("");
  const [active, setActive] = useState<Set<number>>(new Set(RATINGS));
  // The app keeps this in memory only — the songmeister ticking songs off
  // during a circle, not a saved preference. Mirrored as component state.
  const [sung, setSung] = useState<Set<string>>(new Set());

  const haystacks = useMemo(() => {
    const m = new Map<string, string>();
    for (const s of songs) {
      m.set(s.id, [s.SongName, s.TuneOf ?? "", s.Tags ?? "", s.Lyrics ?? ""].join("\n").toLowerCase());
    }
    return m;
  }, [songs]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return songs.filter((s) => {
      if (!active.has(clamp(s.BawdyRating))) return false;
      if (!q) return true;
      return (haystacks.get(s.id) ?? "").includes(q);
    });
  }, [songs, query, active, haystacks]);

  function toggleChip(r: number) {
    setActive((prev) => {
      const next = new Set(prev);
      if (next.has(r)) next.delete(r); else next.add(r);
      return next;
    });
  }

  return (
    <div className="-mx-3 -mt-3 sm:-mt-4">
      {/* Search + chips, pinned under the title bar as the app pins them */}
      <div className="fixed inset-x-0 top-12 z-40">
        <div
          className="flex h-[52px] items-center gap-2 bg-white pl-[10px] pr-1"
          style={{ boxShadow: "0 4px 10px rgba(0,0,0,0.55)" }}
        >
          <Search className="h-6 w-6 shrink-0 text-black" aria-hidden="true" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoCorrect="off"
            aria-label="Search songs"
            placeholder="Search songs..."
            className="member-font min-w-0 flex-1 bg-transparent text-[16px] font-semibold leading-none text-black placeholder:text-[20px] placeholder:font-semibold placeholder:text-black/[0.54] focus:outline-none"
          />
          <button
            type="button"
            onClick={() => setQuery("")}
            aria-label="Clear search"
            className="w-10 shrink-0 text-[20px] font-medium text-zinc-600"
          >
            X
          </button>
        </div>

        <div className="flex items-center justify-evenly bg-white px-2 py-1">
          {RATINGS.map((r) => {
            const on = active.has(r);
            return (
              <button
                key={r}
                type="button"
                onClick={() => toggleChip(r)}
                aria-pressed={on}
                aria-label={`Rating ${r}`}
                className="rounded-md px-2 py-1.5 text-[16px] leading-none transition-opacity"
                style={{
                  backgroundColor: on ? "#fff" : "#e0e0e0",
                  border: `${on ? 2 : 1}px solid ${on ? THEME_BUTTON : "#bdbdbd"}`,
                  opacity: on ? 1 : 0.4,
                }}
              >
                {BAWDY[r]}
              </button>
            );
          })}
        </div>
      </div>

      <ul className="pb-24 pt-[100px]">
        {filtered.length === 0 && (
          <li className="px-4 py-10 text-center text-[20px] text-white">No songs match.</li>
        )}
        {filtered.map((song) => {
          const ticked = sung.has(song.id);
          return (
            <li key={song.id} className="px-[10px] pb-2">
              <div className="flex items-center gap-2 rounded-lg bg-white px-3.5 py-2.5 shadow">
                <button
                  type="button"
                  role="checkbox"
                  aria-checked={ticked}
                  aria-label={`Mark ${song.SongName} as sung`}
                  onClick={() => setSung((p) => { const n = new Set(p); if (n.has(song.id)) n.delete(song.id); else n.add(song.id); return n; })}
                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[3px] border-2"
                  style={{ borderColor: ticked ? THEME_BUTTON : "#757575", backgroundColor: ticked ? THEME_BUTTON : "transparent" }}
                >
                  {ticked && (
                    <svg viewBox="0 0 24 24" className="h-5 w-5 text-white" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><path d="M5 13l4 4L19 7" /></svg>
                  )}
                </button>

                <Link href={`/me/songs/${song.id}`} className="flex min-w-0 flex-1 items-center gap-3">
                  {song.ImageUrl?.startsWith("http") ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={song.ImageUrl} alt="" className="h-9 w-9 shrink-0 rounded object-cover" />
                  ) : (
                    <Music2 className="h-6 w-6 shrink-0" style={{ color: "#757575" }} aria-hidden="true" />
                  )}

                  <div className="min-w-0 flex-1">
                    <div className="member-font truncate text-[16px] font-semibold leading-none text-black">{song.SongName}</div>
                    {song.TuneOf && (
                      <div className="font-condensed mt-1 truncate text-[16px] leading-none" style={{ color: "#757575" }}>
                        Tune of: {song.TuneOf}
                      </div>
                    )}
                  </div>

                  <span className="shrink-0 text-[18px] leading-none">{BAWDY[clamp(song.BawdyRating)]}</span>
                </Link>
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
