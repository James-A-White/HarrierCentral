"use client";

/**
 * The app's Run Counts tab (history_list_page.dart): By Kennel / By
 * Country toggle, then rows of a big round logo or flag, "=", the name in
 * a condensed face, the count large, and "(N times hared)" when there is
 * haring. Tapping a row opens the drill-down.
 */
import { useState } from "react";
import Link from "next/link";
import type { HistoryCountry, HistoryKennel } from "@/lib/member-api";
import { HC_RED } from "@/components/member/app-look";

/** The app's condensed face; the class carries the family (see globals.css). */
export const condensed: React.CSSProperties = { fontWeight: 600 };

export function RunCountsView({ kennels, countries }: { kennels: HistoryKennel[]; countries: HistoryCountry[] }) {
  const [mode, setMode] = useState<"kennel" | "country">("kennel");
  return (
    <div>
      <div className="mx-auto mb-4 flex w-[280px] items-center">
        <Toggle active={mode === "kennel"} onClick={() => setMode("kennel")}>By Kennel</Toggle>
        <Toggle active={mode === "country"} onClick={() => setMode("country")}>By Country</Toggle>
      </div>

      <ul className="space-y-5">
        {mode === "kennel"
          ? kennels.map((k) => (
              <CountRow
                key={k.PublicKennelId}
                href={`/me/history/kennel/${k.PublicKennelId.toLowerCase()}`}
                image={k.KennelLogo?.startsWith("https://") ? k.KennelLogo : null}
                fallback={k.KennelShortName.charAt(0)}
                name={k.KennelName}
                count={`${k.IsEstimate ? "~" : ""}${k.TotalRuns}`}
                hared={k.TotalHaring}
              />
            ))
          : countries.map((c) => (
              <CountRow
                key={c.CountryId}
                href={`/me/history/country/${c.CountryId.toLowerCase()}`}
                image={c.FlagFile ? `/images/flags/${c.FlagFile}` : null}
                fallback={c.CountryCode ?? "?"}
                name={c.CountryName}
                count={String(c.RunCount)}
                hared={c.HareCount}
              />
            ))}
      </ul>
    </div>
  );
}

/** The app's TabBar: a 140 px tab each, the red pill indicator under the selected one. */
export function Toggle({ active, onClick, children, width = 140 }: { active: boolean; onClick: () => void; children: React.ReactNode; width?: number }) {
  return (
    <button type="button" onClick={onClick}
      className="rounded-full py-2 text-[17px] font-semibold transition-colors"
      style={{ width, ...(active ? { backgroundColor: HC_RED, color: "#fff" } : { color: "#000" }) }}>
      {children}
    </button>
  );
}

function CountRow({ href, image, fallback, name, count, hared }: { href: string; image: string | null; fallback: string; name: string; count: string; hared: number }) {
  return (
    <li>
      <Link href={href} className="flex items-center gap-2 pl-2">
        <div className="h-20 w-20 shrink-0 overflow-hidden rounded-full bg-white shadow">
          {image ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={image} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-3xl font-bold text-white" style={{ backgroundColor: HC_RED }}>{fallback}</div>
          )}
        </div>
        <span className="font-condensed shrink-0 text-[32px] leading-none text-zinc-900" style={condensed}> = </span>
        <div className="font-condensed min-w-0 leading-tight text-zinc-900" style={condensed}>
          <div className="text-[20px] leading-[1.05]">{name}</div>
          <div className="text-[32px] leading-none">{count}</div>
          {hared > 0 ? <div className="text-[18px] leading-tight">({hared} times hared)</div> : <div className="h-5" />}
        </div>
      </Link>
    </li>
  );
}
