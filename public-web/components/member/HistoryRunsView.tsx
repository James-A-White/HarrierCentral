"use client";

/**
 * The app's "My runs for <kennel|country>" drill-down
 * (user_run_history_list_page.dart / user_country_history_list_page.dart):
 * My Runs / All Runs toggle, rows with the tick or the hare, the title,
 * "Run #N on <date>", "My FILTH run #115" in green with "and #63 time
 * haring" in purple, and the payment strip where a payment exists — one
 * row per payment, as the app.
 */
import { useState } from "react";
import Link from "next/link";
import type { HistoryRunRow, HistoryRunsHeader } from "@/lib/member-api";
import { HC_GREEN, HC_PURPLE, HC_RED, appDate } from "@/components/member/app-look";
import { condensed } from "@/components/member/RunCountsView";

const AT_HASH = 20;

export function HistoryRunsView({ kind, id, header, initialRuns, showKennelLogo, showFlag }: {
  kind: "kennel" | "country"; id: string; header: HistoryRunsHeader | null; initialRuns: HistoryRunRow[];
  showKennelLogo: boolean; showFlag: boolean;
}) {
  const [all, setAll] = useState(false);
  const [runs, setRuns] = useState<HistoryRunRow[]>(initialRuns);
  const [cache, setCache] = useState<Record<string, HistoryRunRow[]>>({ mine: initialRuns });
  const [loading, setLoading] = useState(false);

  async function switchTo(showAll: boolean) {
    setAll(showAll);
    const key = showAll ? "all" : "mine";
    if (cache[key]) { setRuns(cache[key]); return; }
    setLoading(true);
    try {
      const r = await fetch(`/api/member/history-runs?${kind}=${id}&all=${showAll ? 1 : 0}`, { cache: "no-store" });
      const j = (await r.json()) as { runs?: HistoryRunRow[] };
      const rows = j.runs ?? [];
      setCache((c) => ({ ...c, [key]: rows }));
      setRuns(rows);
    } finally { setLoading(false); }
  }

  const title = kind === "kennel" ? `My runs for ${header?.KennelShortName ?? ""}` : `My runs for ${header?.CountryName ?? ""}`;
  // A kennel that moves around (EuroHash) shows each run's flag; one that
  // does not shows none — the app's behaviour.
  const flagsWanted = showFlag && new Set(runs.map((r) => r.flagFile ?? "")).size > 1;

  return (
    <div className="-mx-3 -mt-3 sm:-mt-4">
      {/* The app's sub-page bar: back + title */}
      <div className="flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href="/me/history" aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-lg font-semibold">{title}</h2>
        <span className="w-4" />
      </div>

      {/* Header card — kennel only, as the app */}
      {kind === "kennel" && header && (
        <div className="flex items-center gap-4 bg-white px-3 py-3 text-zinc-900">
          {header.KennelLogo?.startsWith("https://") ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={header.KennelLogo} alt="" className="h-20 w-20 shrink-0 object-contain" />
          ) : (
            <div className="flex h-20 w-20 shrink-0 items-center justify-center rounded-full text-2xl font-bold text-white" style={{ backgroundColor: HC_RED }}>{(header.KennelShortName ?? "?").charAt(0)}</div>
          )}
          <div className="min-w-0 leading-snug">
            <div className="text-[19px] font-bold">{header.KennelName}</div>
            <div className="text-[17px]">My verified run count: {header.HcRuns ?? 0}</div>
            <div className="text-[17px]">My verified haring count: {header.HcHaring ?? 0}</div>
            <div className="text-[17px]">Kennel credit: {money(header.KennelCredit ?? 0, header.CurrencySymbol, header.DigitsAfterDecimal ?? 2)}</div>
          </div>
        </div>
      )}

      <div className="px-3 pt-4">
        <div className="mx-auto mb-3 flex max-w-sm items-center justify-around">
          <Toggle active={!all} onClick={() => switchTo(false)}>My Runs</Toggle>
          <Toggle active={all} onClick={() => switchTo(true)}>All Runs</Toggle>
        </div>
      </div>

      {loading && <p className="py-4 text-center text-zinc-700">Loading…</p>}

      <ul className="divide-y divide-zinc-400/40">
        {runs.map((r, i) => <RunRow key={`${r.publicEventId}-${r.hemId ?? ""}-${i}`} r={r} showKennelLogo={showKennelLogo} showFlag={flagsWanted} />)}
        {!loading && runs.length === 0 && <li className="py-6 text-center text-zinc-700">No runs.</li>}
      </ul>
    </div>
  );
}

function Toggle({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick}
      className="rounded-full px-8 py-2 text-[22px] font-semibold transition-colors"
      style={active ? { backgroundColor: HC_RED, color: "#fff" } : { color: "#18181b" }}>
      {children}
    </button>
  );
}

function RunRow({ r, showKennelLogo, showFlag }: { r: HistoryRunRow; showKennelLogo: boolean; showFlag: boolean }) {
  const attended = r.attendenceState >= AT_HASH;
  const isHare = r.isHare !== 0;
  const netPayment = (r.creditAmount ?? 0) - (r.debitAmount ?? 0);
  const creditWasUsed = (r.debitAmount ?? 0) > 0 && (r.creditAmount ?? 0) === 0;
  const creditAvailable = r.creditAvailable ?? 0;
  const creditColor = creditAvailable > 0 ? HC_GREEN : creditAvailable < 0 ? HC_RED : "#a1a1aa";
  const paidColor = netPayment === 0 ? HC_GREEN : HC_RED;

  return (
    <li className="flex items-center gap-2 px-2 py-2">
      {/* State: the app's green tick or purple hare (empty circle on All Runs where I have no row) */}
      <div className="flex w-14 shrink-0 items-center justify-center">
        {isHare ? (
          <div className="flex h-12 w-12 items-center justify-center rounded-full" style={{ backgroundColor: HC_PURPLE }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/images/icons/hare_icon.png" alt="Hared" className="h-9 w-9" />
          </div>
        ) : attended ? (
          <div className="flex h-12 w-12 items-center justify-center rounded-full text-white" style={{ backgroundColor: "#43a047" }}>
            <svg viewBox="0 0 24 24" className="h-8 w-8" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><path d="M5 13l4 4L19 7" /></svg>
          </div>
        ) : (
          <div className="h-12 w-12 rounded-full border-2 border-zinc-400/60" />
        )}
      </div>
      {showKennelLogo && (
        <div className="h-16 w-16 shrink-0 overflow-hidden rounded-full bg-white">
          {r.kennelLogo?.startsWith("https://")
            // eslint-disable-next-line @next/next/no-img-element
            ? <img src={r.kennelLogo} alt="" className="h-full w-full object-cover" />
            : <div className="flex h-full w-full items-center justify-center font-bold" style={{ color: HC_RED }}>{r.kennelShortName.charAt(0)}</div>}
        </div>
      )}
      {showFlag && r.flagFile && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={`/images/flags/${r.flagFile}`} alt={r.countryName} className="h-12 w-12 shrink-0 rounded-full object-cover" />
      )}
      <div className="w-0.5 self-stretch bg-zinc-400/60" />
      <div className="font-condensed min-w-0 flex-1 leading-tight text-zinc-900" style={condensed}>
        <Link href={`/${r.kennelSlug}/${r.eventNumber}?back=/me/history`} className="block truncate text-[19px] hover:underline">{r.eventName}</Link>
        <div className="truncate text-[17px] font-semibold" suppressHydrationWarning>Run #{r.eventNumber} on {appDate(r.eventStartDatetime)}</div>
        {attended && r.totalRunsThisKennel ? (
          <div className="text-[17px] font-semibold">
            <span style={{ color: HC_GREEN }}>My {r.kennelShortName} run #{r.totalRunsThisKennel}</span>
            {isHare && r.totalHaringThisKennel ? <span style={{ color: HC_PURPLE }}> and #{r.totalHaringThisKennel} time haring</span> : null}
          </div>
        ) : null}

        {/* Payment strip — the app's, when there is a payment on this row */}
        {(r.doPayForExtras ?? 0) !== 0 && (
          <div className="mt-1 text-center text-[16px]" style={{ color: paidColor, fontWeight: 600 }}>
            {(r.extrasDescription ?? "Extra charge: ")}{money(r.extrasPrice ?? 0, r.currencySymbol, r.digitsAfterDecimal)}
          </div>
        )}
        {(r.debitAmount ?? 0) !== 0 && (
          <div className="mt-1 grid grid-cols-3 text-center text-[16px]" style={{ fontWeight: 600 }}>
            <div style={{ color: paidColor }}><div>Run fee</div><div>{money(r.debitAmount ?? 0, r.currencySymbol, r.digitsAfterDecimal)}</div></div>
            <div style={{ color: paidColor }}><div>{creditWasUsed ? "From credit" : "Paid"}</div><div>{money(creditWasUsed ? (r.debitAmount ?? 0) : (r.creditAmount ?? 0), r.currencySymbol, r.digitsAfterDecimal)}</div></div>
            <div style={{ color: creditColor }}><div>Credit left</div><div>{money(creditAvailable, r.currencySymbol, r.digitsAfterDecimal)}</div></div>
          </div>
        )}
      </div>
    </li>
  );
}

function money(v: number, symbol: string | null, digits: number): string {
  const amount = (Number(v) || 0).toFixed(Math.max(0, Math.min(4, digits)));
  const t = symbol && symbol.includes("^") ? symbol : `${symbol ?? ""}^`;
  return t.replace("^", amount);
}
