"use client";

/**
 * The app's "Get a Life (Leaderboards)" (leaderboard.dart) for one kennel:
 * the 365 days · In <year> · Total tabs, the "Show Kennels" and "Home
 * Kennel" checkboxes, the yellow Runs · Hared · Hasher header (tap to
 * sort), and the white condensed rows — the home kennel's short name
 * after the name when Show Kennels is on and it is not this kennel.
 */
import { useMemo, useState } from "react";
import Link from "next/link";
import type { LeaderboardRow } from "@/lib/member-api";

type Tab = "365" | "year" | "total";
type Col = 0 | 1 | 2;

export function LeaderboardView({ rows, kennelShortName, back }: { rows: LeaderboardRow[]; kennelShortName: string; back: string }) {
  const [tab, setTab] = useState<Tab>("365");
  const [showKennels, setShowKennels] = useState(false);
  const [homeOnly, setHomeOnly] = useState(false);
  const [sortCol, setSortCol] = useState<Col>(0);
  const [asc, setAsc] = useState(false);
  const year = new Date().getFullYear();

  const runsOf = (r: LeaderboardRow) => tab === "total" ? r.totalRunCount : tab === "365" ? r.rollingYearTotalRunCount : r.ytdTotalRunCount;
  const haredOf = (r: LeaderboardRow) => tab === "total" ? r.totalHaringCount : tab === "365" ? r.rollingYearHaringCount : r.ytdHaringCount;

  const list = useMemo(() => {
    const out = rows.filter((r) => !homeOnly || r.isHomeKennel === 1);
    out.sort((a, b) => {
      const byName = a.displayName.toLowerCase().localeCompare(b.displayName.toLowerCase());
      let cmp = sortCol === 0 ? runsOf(a) - runsOf(b) : sortCol === 1 ? haredOf(a) - haredOf(b) : -byName;
      if (!asc) cmp = -cmp;
      return cmp || byName;
    });
    return out;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rows, tab, homeOnly, sortCol, asc]);

  function sortBy(col: Col) {
    if (col === sortCol) setAsc((a) => !a);
    else { setSortCol(col); setAsc(col === 2); }
  }

  return (
    <div className="-mx-3 -mt-3 pb-8 sm:-mt-4">
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href={back} aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">Get a Life (Leaderboards)</h2>
        <span className="w-4" />
      </div>

      {/* Tabs */}
      <div className="flex text-white" style={{ backgroundColor: "#580438" }}>
        {([["365", "365 days"], ["year", `In ${year}`], ["total", "Total"]] as [Tab, string][]).map(([t, label]) => (
          <button key={t} type="button" onClick={() => setTab(t)}
            className="flex-1 py-2.5 text-[17px] font-semibold"
            style={{ borderBottom: `3px solid ${tab === t ? "#fff" : "transparent"}`, opacity: tab === t ? 1 : 0.75 }}>
            {label}
          </button>
        ))}
      </div>

      {/* Checkboxes */}
      <div className="flex items-center justify-center gap-6 px-3 py-3 text-white">
        <label className="flex items-center gap-2 text-[18px]">
          <input type="checkbox" checked={showKennels} onChange={(e) => setShowKennels(e.target.checked)} className="h-5 w-5 accent-red-800" />
          <span className={`font-condensed ${showKennels ? "font-bold" : ""}`}>Show Kennels</span>
        </label>
        <label className="flex items-center gap-2 text-[18px]">
          <input type="checkbox" checked={homeOnly} onChange={(e) => setHomeOnly(e.target.checked)} className="h-5 w-5 accent-red-800" />
          <span className={`font-condensed ${homeOnly ? "font-bold" : ""}`}>Home Kennel</span>
        </label>
      </div>

      {/* Header */}
      <div className="font-condensed grid grid-cols-12 border-b border-white/40 px-3 pb-1 text-[20px] text-yellow-300">
        <button type="button" onClick={() => sortBy(0)} className={`col-span-2 text-right ${sortCol === 0 ? "font-bold" : ""}`}>Runs</button>
        <button type="button" onClick={() => sortBy(1)} className={`col-span-2 text-right ${sortCol === 1 ? "font-bold" : ""}`}>Hared</button>
        <button type="button" onClick={() => sortBy(2)} className={`col-span-8 pl-4 text-left ${sortCol === 2 ? "font-bold" : ""}`}>Hasher</button>
      </div>

      {list.length === 0 ? (
        <p className="px-3 py-8 text-center text-[20px] text-white">No leaderboard records found</p>
      ) : (
        <ul className="font-condensed text-[22px] text-white">
          {list.map((r, i) => (
            <li key={i} className={`grid grid-cols-12 px-3 py-1 ${r.isMe === 1 ? "bg-white/10 font-bold" : ""}`}>
              <span className="col-span-2 text-right">{runsOf(r)}</span>
              <span className="col-span-2 text-right">{haredOf(r)}</span>
              <span className="col-span-8 truncate pl-4">
                {r.displayName}
                {showKennels && r.isHomeKennel !== 1 && r.homeKennelShortName && r.homeKennelShortName !== kennelShortName && (
                  <span className="text-white/70">  -  {r.homeKennelShortName}</span>
                )}
              </span>
            </li>
          ))}
        </ul>
      )}
      <p className="px-3 pt-4 text-center text-[14px] text-white/60">Hashers with a run in the last year.</p>
    </div>
  );
}
