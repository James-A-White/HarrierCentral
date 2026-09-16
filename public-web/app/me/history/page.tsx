import type { Metadata } from "next";
import Link from "next/link";
import { getMyHistory } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { nextMilestone } from "@/lib/member-format";
import { HC_BLUE, HC_GREEN, HC_PURPLE, HC_RED, appDate, card, mutedText, titleText } from "@/components/member/app-look";

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
      <section className={`${card} p-5`}>
        <h1 className={titleText}>{name}</h1>
        <div className="mt-3 grid grid-cols-3 gap-3 text-center">
          <Stat label="runs" value={`${tilde}${h.totals.Runs}`} />
          <Stat label="hared" value={`${tilde}${h.totals.Haring}`} />
          <Stat label="kennels" value={String(h.totals.Kennels)} />
        </div>
      </section>

      {h.kennels.length > 0 && (
        <section>
          <h2 className="mb-2 text-sm font-bold uppercase tracking-wide text-white/90">By kennel</h2>
          <ul className="space-y-2">
            {h.kennels.map((k) => {
              const next = nextMilestone(k.Runs);
              const away = next - k.Runs;
              return (
                <li key={k.PublicKennelId} className={`${card} flex items-center gap-3 p-3`}>
                  {k.KennelLogo?.startsWith("https://") ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={k.KennelLogo} alt="" className="h-12 w-12 shrink-0 object-contain" />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg text-lg font-bold text-white" style={{ backgroundColor: HC_RED }}>{k.KennelShortName.charAt(0)}</div>
                  )}
                  <div className="min-w-0 flex-1">
                    <Link href={`/${k.KennelSlug}`} className={`${titleText} block truncate hover:underline`}>
                      {k.KennelName}{k.IsHomeKennel === 1 && <span className="ml-2 rounded-full bg-zinc-200 px-2 py-0.5 text-xs font-semibold text-zinc-700">Home</span>}
                    </Link>
                    <p className="text-[15px] font-semibold" style={{ color: HC_BLUE }}>
                      Runs: {k.IsEstimate ? "~" : ""}{k.Runs}, Times hared: {k.Haring}
                    </p>
                    {k.DateOfLastRun && <p className="text-[15px] font-semibold" style={{ color: HC_BLUE }}>Last run: {appDate(k.DateOfLastRun).replace(/ at .*$/, "")}</p>}
                    <p className="mt-0.5 text-sm" style={{ color: away <= 3 ? HC_RED : "#52525b" }}>
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
        <h2 className="mb-2 text-sm font-bold uppercase tracking-wide text-white/90">Every run · {h.runs.length}</h2>
        {h.runs.length === 0 && (
          <p className="text-white/80">No runs recorded yet. Your kennel&apos;s check-in puts them here.</p>
        )}
        <ul className={`${card} divide-y divide-zinc-300`}>
          {h.runs.map((r) => (
            <li key={r.PublicEventId} className="flex items-center gap-3 px-3 py-3">
              {r.KennelLogo?.startsWith("https://") ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={r.KennelLogo} alt="" className="h-11 w-11 shrink-0 object-contain" />
              ) : (
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg text-base font-bold text-white" style={{ backgroundColor: HC_RED }}>{r.KennelShortName.charAt(0)}</div>
              )}
              <div className="min-w-0 flex-1">
                <Link href={`/${r.KennelSlug}/${r.EventNumber}?back=/me/history`} className={`${titleText} block truncate hover:underline`}>
                  {r.EventName}
                </Link>
                <p className="text-[15px] text-zinc-800">
                  Run #{r.EventNumber} on {appDate(r.EventStartDatetime)}
                </p>
                <p className="text-[15px] font-semibold">
                  {r.MyRunNumber
                    ? <span style={{ color: HC_GREEN }}>My {r.KennelShortName} run #{r.MyRunNumber}</span>
                    : <span className={mutedText}>{r.IsCountedRun !== 1 ? "Not a counted run" : "Hared, not run"}</span>}
                  {r.IsHare === 1 && <span style={{ color: HC_PURPLE }}> · haring</span>}
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
      <div className="text-3xl font-bold" style={{ color: HC_BLUE }}>{value}</div>
      <div className="text-xs uppercase tracking-wide text-zinc-500">{label}</div>
    </div>
  );
}
