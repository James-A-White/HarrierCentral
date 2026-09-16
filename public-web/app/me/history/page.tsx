import type { Metadata } from "next";
import Link from "next/link";
import { getMyHistory } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { formatLocalDate, nextMilestone } from "@/lib/member-format";

export const metadata: Metadata = { title: "My history" };

/**
 * The app's History tab on the web (E9.F7.S5): totals, per-kennel counts
 * with the next milestone, and every run attended — newest first, each
 * with the number it was for me at that kennel. This is the page that
 * turns a WhatsApp tap into a returning member.
 */
export default async function MyHistoryPage() {
  const s = await requireMember();
  const h = await getMyHistory(s).catch(() => null);
  if (!h) return <p className="text-zinc-300">Couldn&apos;t load your history just now.</p>;

  const name = s.hashName || s.displayName || "you";
  const tilde = h.totals.IsEstimate ? "~" : "";

  return (
    <div className="space-y-8">
      <section className="rounded-2xl bg-black/30 p-5">
        <h1 className="text-xl font-bold">{name}</h1>
        <div className="mt-3 grid grid-cols-3 gap-3 text-center">
          <Stat label="runs" value={`${tilde}${h.totals.Runs}`} />
          <Stat label="hared" value={`${tilde}${h.totals.Haring}`} />
          <Stat label="kennels" value={String(h.totals.Kennels)} />
        </div>
      </section>

      {h.kennels.length > 0 && (
        <section>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">By kennel</h2>
          <ul className="space-y-2">
            {h.kennels.map((k) => {
              const next = nextMilestone(k.Runs);
              const away = next - k.Runs;
              return (
                <li key={k.PublicKennelId} className="flex items-center gap-3 rounded-2xl bg-black/30 p-4">
                  {k.KennelLogo?.startsWith("https://") ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={k.KennelLogo} alt="" className="h-12 w-12 shrink-0 object-contain" />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-red-600 text-lg font-bold">{k.KennelShortName.charAt(0)}</div>
                  )}
                  <div className="min-w-0 flex-1">
                    <Link href={`/${k.KennelSlug}`} className="block truncate font-bold hover:underline">
                      {k.KennelName}{k.IsHomeKennel === 1 && <span className="ml-2 rounded-full bg-white/15 px-2 py-0.5 text-xs font-semibold">Home</span>}
                    </Link>
                    <p className="text-sm text-zinc-300">
                      {k.IsEstimate ? "~" : ""}{k.Runs} run{k.Runs === 1 ? "" : "s"}{k.Haring > 0 && `, hared ${k.Haring}`}
                      {k.DateOfLastRun && <span className="text-zinc-500"> · last {formatLocalDate(k.DateOfLastRun)}</span>}
                    </p>
                    <p className="mt-1 text-sm" style={{ color: away <= 3 ? "#fbbf24" : "#a1a1aa" }}>
                      {away === 0 ? `🏅 Run ${next} — that's a milestone` : `🏅 ${away} to your ${next}th`}
                    </p>
                  </div>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      <section>
        <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">Every run · {h.runs.length}</h2>
        {h.runs.length === 0 && (
          <p className="text-zinc-300">No runs recorded yet. Your kennel&apos;s check-in puts them here.</p>
        )}
        <ul className="divide-y divide-white/10 rounded-2xl bg-black/30">
          {h.runs.map((r) => (
            <li key={r.PublicEventId} className="flex items-center gap-3 px-4 py-3">
              <div className="w-12 shrink-0 text-center">
                {r.MyRunNumber ? (
                  <span className="rounded-full bg-white/10 px-2 py-0.5 text-xs font-bold">#{r.MyRunNumber}</span>
                ) : (
                  <span className="text-xs text-zinc-500">—</span>
                )}
              </div>
              <div className="min-w-0 flex-1">
                <Link href={`/${r.KennelSlug}/${r.EventNumber}?back=/me/history`} className="block truncate font-semibold hover:underline">
                  {r.EventName}
                </Link>
                <p className="truncate text-sm text-zinc-400">
                  {formatLocalDate(r.EventStartDatetime)} · {r.KennelShortName} #{r.EventNumber}
                  {r.IsHare === 1 && " · 🐰 hared"}
                  {r.IsCountedRun !== 1 && " · not counted"}
                </p>
              </div>
              <div className="shrink-0 text-xs text-zinc-500">
                {(r.TrackRunnerCount ?? 0) > 0 && <span title="Trails">🥾 </span>}
                {(r.PhotoCount ?? 0) > 0 && <span title="Photos">📷</span>}
              </div>
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-3xl font-bold">{value}</div>
      <div className="text-xs uppercase tracking-wide text-zinc-400">{label}</div>
    </div>
  );
}
