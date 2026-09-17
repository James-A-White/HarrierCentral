import type { Metadata } from "next";
import { getMyHistory } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { RunCountsView } from "@/components/member/RunCountsView";
import { LightBackground } from "@/components/member/LightBackground";

export const metadata: Metadata = { title: "Run Counts" };

/**
 * The app's Run Counts tab (E9.F7.S5): the light footprint background, a
 * white header card with my photo and totals, then By Kennel / By Country.
 * Data is the app's own three queries, moved into publicWeb_getMyHistory.
 */
export default async function MyHistoryPage() {
  const s = await requireMember();
  const h = await getMyHistory(s).catch(() => null);
  if (!h) return <p className="text-zinc-300">Couldn&apos;t load your run counts just now.</p>;
  const tilde = h.totals.IsEstimate ? "~" : "";

  return (
    <div className="-mx-3 -mt-3 sm:-mt-4">
      <LightBackground />
      {/* The app's header band: 100 px, translucent black, black87 text */}
      <div className="flex h-[100px] items-center gap-5 px-5 text-zinc-900/90" style={{ backgroundColor: "rgba(0,0,0,0.27)" }}>
        {s.photo?.startsWith("http") ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={s.photo} alt="" className="h-20 w-20 shrink-0 rounded-full object-cover" />
        ) : (
          <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full bg-zinc-200 text-3xl font-bold text-zinc-500">{(s.hashName || "?").charAt(0)}</div>
        )}
        <div className="text-[17px] leading-[1.2]">
          <div className="font-bold">My total run counts</div>
          <div className="font-semibold">Total runs: {tilde}{h.totals.Runs}</div>
          <div className="font-semibold">Total times hared: {tilde}{h.totals.Haring}</div>
        </div>
      </div>
      <div className="px-3 pt-5">
        <RunCountsView kennels={h.kennels} countries={h.countries} />
      </div>
    </div>
  );
}
