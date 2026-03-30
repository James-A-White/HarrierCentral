"use client";

import { useState, useCallback } from "react";
import { ChevronUp, ChevronDown, ChevronsUpDown, Download, ClipboardCopy, Printer, BarChart3 } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { KennelStatRow } from "@/lib/api";

// ─── Types ────────────────────────────────────────────────────────────────────

type SortKey = keyof Pick<
  KennelStatRow,
  "DisplayName" | "TotalRuns" | "TotalHaring" | "YtdRuns" | "YtdHaring" | "RollingYearRuns" | "RollingYearHaring"
>;

interface SortState {
  key: SortKey;
  dir: "asc" | "desc";
}

// ─── Column definitions ───────────────────────────────────────────────────────

interface ColDef {
  key: SortKey;
  label: string;
  group: string;
}

const COLUMNS: ColDef[] = [
  { key: "DisplayName",       label: "Name",   group: ""              },
  { key: "TotalRuns",         label: "Runs",   group: "Lifetime"      },
  { key: "TotalHaring",       label: "Haring", group: "Lifetime"      },
  { key: "YtdRuns",           label: "Runs",   group: "This Year"     },
  { key: "YtdHaring",         label: "Haring", group: "This Year"     },
  { key: "RollingYearRuns",   label: "Runs",   group: "Last 365 Days" },
  { key: "RollingYearHaring", label: "Haring", group: "Last 365 Days" },
];

// Group header row — rank uses rowSpan=2 so is excluded here.
// Span counts must add up to COLUMNS.length (7).
const GROUPS = [
  { label: "",              span: 1 },  // Name
  { label: "Lifetime",      span: 2 },
  { label: "This Year",     span: 2 },
  { label: "Last 365 Days", span: 2 },
];

// ─── Sort helpers ─────────────────────────────────────────────────────────────

function sortRows(rows: KennelStatRow[], sort: SortState): KennelStatRow[] {
  return [...rows].sort((a, b) => {
    const av = a[sort.key];
    const bv = b[sort.key];
    if (typeof av === "string" && typeof bv === "string") {
      return sort.dir === "asc" ? av.localeCompare(bv) : bv.localeCompare(av);
    }
    const diff = (av as number) - (bv as number);
    return sort.dir === "asc" ? diff : -diff;
  });
}

// ─── Export helpers ───────────────────────────────────────────────────────────

function exportCSV(rows: KennelStatRow[], kennelName: string) {
  const headers = ["Rank", "Name", "Total Runs", "Total Haring", "YTD Runs", "YTD Haring", "Last 365 Days Runs", "Last 365 Days Haring"];
  const csv = [
    headers.join(","),
    ...rows.map((r, i) => [
      i + 1,
      `"${r.DisplayName.replace(/"/g, '""')}"`,
      r.TotalRuns,
      r.TotalHaring,
      r.YtdRuns,
      r.YtdHaring,
      r.RollingYearRuns,
      r.RollingYearHaring,
    ].join(",")),
  ].join("\n");

  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${kennelName.replace(/\s+/g, "_")}_stats.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

async function copyToClipboard(rows: KennelStatRow[]): Promise<void> {
  const headers = ["Rank", "Name", "Total Runs", "Total Haring", "YTD Runs", "YTD Haring", "Last 365 Days Runs", "Last 365 Days Haring"];
  const text = [
    headers.join("\t"),
    ...rows.map((r, i) => [
      i + 1,
      r.DisplayName,
      r.TotalRuns,
      r.TotalHaring,
      r.YtdRuns,
      r.YtdHaring,
      r.RollingYearRuns,
      r.RollingYearHaring,
    ].join("\t")),
  ].join("\n");
  await navigator.clipboard.writeText(text);
}

// ─── Sort icon ────────────────────────────────────────────────────────────────

function SortIcon({ col, sort }: { col: SortKey; sort: SortState }) {
  if (sort.key !== col) return <ChevronsUpDown className="h-3 w-3 opacity-30 shrink-0" />;
  return sort.dir === "asc"
    ? <ChevronUp className="h-3 w-3 shrink-0 text-white" />
    : <ChevronDown className="h-3 w-3 shrink-0 text-white" />;
}

// ─── Shared cell class helpers ────────────────────────────────────────────────

const BORDER_COLOR = "dark:border-white/10 border-zinc-200";
// Header cells: full border, opaque background so nothing bleeds through
const TH_BASE = `border ${BORDER_COLOR} px-3 py-2.5 text-xl font-semibold dark:bg-zinc-900/95 bg-zinc-50/95 backdrop-blur-sm`;
// Body cells: sides + bottom only (no top) — avoids a doubled border at the header/body table junction
const TD_BORDER = `border-b border-x ${BORDER_COLOR}`;
const TD_NUM = `${TD_BORDER} px-3 py-2.5 text-right tabular-nums text-2xl`;

// ─── Column group ─────────────────────────────────────────────────────────────
// Shared between the header table and the scrollable body table so columns align.
// table-fixed respects these widths; the name column (no explicit width) fills the rest.

function ColGroup() {
  return (
    <colgroup>
      <col className="w-12" />   {/* # */}
      <col />                     {/* Name — flexible */}
      <col className="w-20" />   {/* Lifetime Runs */}
      <col className="w-28" />   {/* Lifetime Haring */}
      <col className="w-20" />   {/* YTD Runs */}
      <col className="w-28" />   {/* YTD Haring */}
      <col className="w-20" />   {/* Rolling Year Runs */}
      <col className="w-28" />   {/* Rolling Year Haring */}
    </colgroup>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

interface StatsPageClientProps {
  rows: KennelStatRow[];
  kennelName: string;
  kennelShortName: string;
}

export function StatsPageClient({ rows, kennelName, kennelShortName }: StatsPageClientProps) {
  const [sort, setSort] = useState<SortState>({ key: "RollingYearRuns", dir: "desc" });
  const [copyState, setCopyState] = useState<"idle" | "copied">("idle");

  const sorted = sortRows(rows, sort);

  const handleSort = useCallback((key: SortKey) => {
    setSort((prev) =>
      prev.key === key
        ? { key, dir: prev.dir === "desc" ? "asc" : "desc" }
        : { key, dir: key === "DisplayName" ? "asc" : "desc" }
    );
  }, []);

  const handleCopy = useCallback(async () => {
    try {
      await copyToClipboard(sorted);
      setCopyState("copied");
      setTimeout(() => setCopyState("idle"), 2000);
    } catch {
      // Clipboard API unavailable — silently ignore
    }
  }, [sorted]);

  const handleExportCSV = useCallback(() => exportCSV(sorted, kennelName), [sorted, kennelName]);

  // ── Empty state ─────────────────────────────────────────────────────────────
  if (rows.length === 0) {
    return (
      <div className="mt-8 rounded-[2rem] border dark:border-white/[0.08] dark:bg-white/[0.04] border-zinc-200 bg-white p-12 flex flex-col items-center gap-3 text-center">
        <BarChart3 className="h-8 w-8 dark:text-white/20 text-zinc-300" />
        <p className="text-2xl dark:text-white text-zinc-900">No stats available yet.</p>
        <p className="text-xl dark:text-white/60 text-zinc-500">
          Stats will appear once members have runs recorded.
        </p>
      </div>
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-5">

      {/* Header + toolbar */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xl uppercase tracking-[0.15em] dark:text-white/50 text-zinc-500 mb-1">
            Run statistics
          </p>
          <h1 className="text-4xl font-black dark:text-white text-zinc-900 leading-tight">
            {kennelShortName}
          </h1>
          <p className="text-2xl dark:text-white/60 text-zinc-500 mt-1">
            {rows.length} {rows.length === 1 ? "hasher" : "hashers"}
          </p>
        </div>

        <div className="flex items-center gap-2 print:hidden">
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportCSV}
            className="rounded-full text-base gap-2 dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.12]"
          >
            <Download className="h-4 w-4" />
            CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleCopy}
            className="rounded-full text-base gap-2 dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.12]"
          >
            <ClipboardCopy className="h-4 w-4" />
            {copyState === "copied" ? "Copied!" : "Copy"}
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => window.print()}
            className="rounded-full text-base gap-2 dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/[0.12]"
          >
            <Printer className="h-4 w-4" />
            Print
          </Button>
        </div>
      </div>

      {/* Table container
           [overflow:clip]  — clips content to the rounded corners without creating
                              a scroll container (overflow:hidden would do both, which
                              would break the body's overflow-y-auto scrolling).
           overflow-x-auto  (inner) — lets narrow screens scroll header + body together,
                              keeping columns aligned.
           Two-table layout — header table is outside the scroll container so the
                              scrollbar track starts at the first data row and ends at
                              the last, with no bleed behind the header or at the corner. */}
      <div className="[overflow:clip] rounded-2xl border dark:border-white/10 border-zinc-200">
        <div className="overflow-x-auto">

          {/* Non-scrolling header */}
          <table className="w-full table-fixed border-collapse">
            <ColGroup />
            <thead>
              <tr>
                <th rowSpan={2} className={`${TH_BASE} text-center dark:text-white/50 text-zinc-400`}>
                  #
                </th>
                {GROUPS.map(({ label, span }) => (
                  <th
                    key={label || "__name__"}
                    colSpan={span}
                    className={`${TH_BASE} text-center uppercase tracking-[0.1em] dark:text-white/50 text-zinc-400`}
                  >
                    {label}
                  </th>
                ))}
              </tr>
              <tr>
                {COLUMNS.map((col) => (
                  <th
                    key={col.key}
                    onClick={() => handleSort(col.key)}
                    className={`${TH_BASE} cursor-pointer select-none whitespace-nowrap dark:text-white text-zinc-700 hover:dark:bg-white/[0.10] hover:bg-zinc-100 transition-colors ${
                      col.key === "DisplayName" ? "text-left" : "text-right"
                    } ${sort.key === col.key ? "dark:bg-white/[0.10] bg-zinc-100" : ""}`}
                  >
                    <span className={`inline-flex items-center gap-1 ${col.key !== "DisplayName" ? "flex-row-reverse" : ""}`}>
                      {col.label}
                      <SortIcon col={col.key} sort={sort} />
                    </span>
                  </th>
                ))}
              </tr>
            </thead>
          </table>

          {/* Scrollable body — stats-scroll class adds a bottom margin to the
               webkit scrollbar track so it clears the rounded corner */}
          <div className="stats-scroll overflow-y-auto [scrollbar-gutter:stable] max-h-[calc(100vh-32rem)] min-h-[16rem]">
            <table className="w-full table-fixed border-collapse">
              <ColGroup />
              <tbody>
                {sorted.map((row, idx) => (
                  <tr key={idx} className="dark:hover:bg-white/[0.04] hover:bg-zinc-50/50 transition-colors">
                    <td className={`${TD_BORDER} px-3 py-2.5 text-center tabular-nums text-2xl dark:text-white/40 text-zinc-400`}>
                      {idx + 1}
                    </td>
                    <td className={`${TD_BORDER} px-3 py-2.5 text-2xl font-semibold dark:text-white text-zinc-900`}>
                      {row.DisplayName}
                    </td>
                    <td className={`${TD_NUM} dark:text-white text-zinc-900`}>{row.TotalRuns}</td>
                    <td className={`${TD_NUM} dark:text-white/70 text-zinc-500`}>{row.TotalHaring}</td>
                    <td className={`${TD_NUM} dark:text-white text-zinc-900`}>{row.YtdRuns}</td>
                    <td className={`${TD_NUM} dark:text-white/70 text-zinc-500`}>{row.YtdHaring}</td>
                    <td className={`${TD_NUM} font-semibold dark:text-white text-zinc-900`}>{row.RollingYearRuns}</td>
                    <td className={`${TD_NUM} dark:text-white/70 text-zinc-500`}>{row.RollingYearHaring}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

        </div>
      </div>

      <p className="text-sm dark:text-white/30 text-zinc-400 text-center print:hidden">
        Click any column header to sort · {rows.length} members shown
      </p>
    </div>
  );
}
