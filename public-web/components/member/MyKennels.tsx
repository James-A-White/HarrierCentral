"use client";

/**
 * The app's Kennels tab on the web (E9.F7.S9): the kennels I follow,
 * belong to, or have run with, with my counts there; a search of the
 * directory (names, places and the *SearchTags); follow / unfollow.
 */
import { useEffect, useState } from "react";
import Link from "next/link";
import type { KennelSearchRow, MyKennel } from "@/lib/member-api";
import { formatRunDate, relativeTime } from "@/lib/member-format";

export function MyKennels({ initialKennels }: { initialKennels: MyKennel[] }) {
  const [kennels, setKennels] = useState<MyKennel[]>(initialKennels);
  const [q, setQ] = useState("");
  const [results, setResults] = useState<KennelSearchRow[] | null>(null);
  const [searching, setSearching] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (q.trim().length < 2) { setResults(null); return; }
    const h = window.setTimeout(async () => {
      setSearching(true);
      try {
        const r = await fetch(`/api/member/kennel-search?q=${encodeURIComponent(q.trim())}`);
        const j = (await r.json()) as { kennels: KennelSearchRow[] };
        setResults(j.kennels ?? []);
      } finally { setSearching(false); }
    }, 300);
    return () => window.clearTimeout(h);
  }, [q]);

  const mine = new Map(kennels.map((k) => [k.PublicKennelId.toLowerCase(), k]));

  async function setFollowing(publicKennelId: string, following: boolean, fromSearch?: KennelSearchRow) {
    setBusy(publicKennelId); setError(null);
    try {
      const r = await fetch("/api/member/follow", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ publicKennelId: publicKennelId.toLowerCase(), following }),
      });
      const j = (await r.json()) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't update."); return; }
      setKennels((ks) => {
        const existing = ks.find((k) => k.PublicKennelId.toLowerCase() === publicKennelId.toLowerCase());
        if (existing) return ks.map((k) => k === existing ? { ...k, Following: following ? 1 : 0 } : k);
        if (!following || !fromSearch) return ks;
        return [...ks, {
          PublicKennelId: fromSearch.PublicKennelId, KennelSlug: fromSearch.KennelSlug, KennelShortName: fromSearch.KennelShortName,
          KennelName: fromSearch.KennelName, KennelLogo: fromSearch.KennelLogo, KennelStatus: fromSearch.KennelStatus,
          City: fromSearch.City, Region: fromSearch.Region, Country: fromSearch.Country, KennelWebsiteDomain: null,
          Following: 1, IsHomeKennel: 0, IsMember: 0, MembershipExpirationDate: null, MemberSince: null, DateOfLastRun: null,
          Runs: 0, Haring: 0, IsEstimate: 0, NextRunGmt: null, NextRunLocal: null, NextRunNumber: null, NextRunName: null, NextRunPublicEventId: null,
        }];
      });
    } finally { setBusy(null); }
  }

  const following = kennels.filter((k) => k.Following === 1 || k.IsHomeKennel === 1);
  const ranWith = kennels.filter((k) => !(k.Following === 1 || k.IsHomeKennel === 1));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Kennels</h1>
        <input
          className="mt-3 w-full rounded-xl border border-white/15 bg-black/30 px-4 py-2.5 text-base text-white placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-red-500"
          placeholder="Find a kennel — name, city, country, “Scotland”…"
          value={q} onChange={(e) => setQ(e.target.value)}
        />
      </div>

      {error && <p className="rounded-lg bg-red-500/20 px-3 py-2 text-sm text-red-200">{error}</p>}

      {results !== null && (
        <section>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">
            {searching ? "Searching…" : `${results.length} found`}
          </h2>
          <ul className="space-y-2">
            {results.map((k) => {
              const m = mine.get(k.PublicKennelId.toLowerCase());
              const isFollowing = !!m && (m.Following === 1 || m.IsHomeKennel === 1);
              return (
                <li key={k.PublicKennelId} className="flex items-center gap-3 rounded-2xl bg-black/30 p-3">
                  <Logo logo={k.KennelLogo} name={k.KennelName} />
                  <div className="min-w-0 flex-1">
                    <Link href={`/${k.KennelSlug}`} className="block truncate font-bold hover:underline">{k.KennelName}</Link>
                    <p className="truncate text-sm text-zinc-400">{[k.City, k.Region, k.Country].filter(Boolean).join(", ")}</p>
                  </div>
                  <FollowButton following={isFollowing} busy={busy === k.PublicKennelId} onClick={() => setFollowing(k.PublicKennelId, !isFollowing, k)} />
                </li>
              );
            })}
          </ul>
        </section>
      )}

      <section>
        <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">Following</h2>
        {following.length === 0 && <p className="text-zinc-300">You don&apos;t follow any kennel yet — search above.</p>}
        <ul className="space-y-2">
          {following.map((k) => <KennelCard key={k.PublicKennelId} k={k} busy={busy === k.PublicKennelId} onToggle={() => setFollowing(k.PublicKennelId, false)} />)}
        </ul>
      </section>

      {ranWith.length > 0 && (
        <section>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-zinc-400">Ran with</h2>
          <ul className="space-y-2">
            {ranWith.map((k) => <KennelCard key={k.PublicKennelId} k={k} busy={busy === k.PublicKennelId} onToggle={() => setFollowing(k.PublicKennelId, true)} />)}
          </ul>
        </section>
      )}
    </div>
  );
}

function Logo({ logo, name }: { logo: string | null; name: string }) {
  if (logo?.startsWith("https://")) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={logo} alt={name} className="h-12 w-12 shrink-0 object-contain" />;
  }
  return <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-red-600 text-lg font-bold text-white">{name.charAt(0).toUpperCase()}</div>;
}

function FollowButton({ following, busy, onClick }: { following: boolean; busy: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} disabled={busy}
      className="shrink-0 rounded-full px-4 py-1.5 text-sm font-semibold transition-opacity hover:opacity-85 disabled:opacity-50"
      style={following ? { backgroundColor: "rgba(255,255,255,0.12)", color: "#fff" } : { backgroundColor: "#dc2626", color: "#fff" }}>
      {following ? "Following" : "Follow"}
    </button>
  );
}

function KennelCard({ k, busy, onToggle }: { k: MyKennel; busy: boolean; onToggle: () => void }) {
  const isFollowing = k.Following === 1 || k.IsHomeKennel === 1;
  const next = k.NextRunGmt && k.NextRunLocal
    ? formatRunDate({ EventStartDatetime: k.NextRunLocal, EventStartDatetimeGmt: k.NextRunGmt, KennelIANATimezone: null })
    : null;
  return (
    <li className="rounded-2xl bg-black/30 p-4">
      <div className="flex items-start gap-3">
        <Logo logo={k.KennelLogo} name={k.KennelName} />
        <div className="min-w-0 flex-1">
          <Link href={`/${k.KennelSlug}`} className="block truncate text-base font-bold hover:underline">
            {k.KennelName}{k.IsHomeKennel === 1 && <span className="ml-2 rounded-full bg-white/15 px-2 py-0.5 text-xs font-semibold">Home</span>}
          </Link>
          <p className="truncate text-sm text-zinc-400">{[k.City, k.Country].filter(Boolean).join(", ")}</p>
          <p className="mt-1 text-sm text-zinc-300">
            {k.IsEstimate ? "~" : ""}{k.Runs} run{k.Runs === 1 ? "" : "s"}{k.Haring > 0 && `, hared ${k.Haring}`}
            {k.IsMember === 1 && " · member"}
          </p>
          {k.NextRunPublicEventId && next && (
            <p className="mt-1 text-sm text-zinc-400">
              Next: <Link href={`/${k.KennelSlug}/${k.NextRunNumber}?back=/me/kennels`} className="underline underline-offset-2">#{k.NextRunNumber} {k.NextRunName}</Link>
              {" "}· {next.short} <span className="text-zinc-500">({relativeTime(k.NextRunGmt!)})</span>
            </p>
          )}
        </div>
        {k.IsHomeKennel !== 1 && <FollowButton following={isFollowing} busy={busy} onClick={onToggle} />}
      </div>
    </li>
  );
}
