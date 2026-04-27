"use client";

// ─── Legacy URL shim ───────────────────────────────────────────────────────────
// The old hashruns.org site used a hash-based SPA URL scheme:
//
//   www.hashruns.org/#/RD?publicKennelIds=<uuid>[,<uuid>...]   (query string)
//   www.hashruns.org/#/RD/<uuid>                               (path in hash)
//
// This scheme is DEPRECATED. The new site uses path-based kennel run URLs:
//
//   www.hashruns.org/<slug>/runs
//
// For a single kennel, this component fetches the kennel + run data and renders
// the runs page inline at the legacy URL — no redirect, no navigation.
// For multiple kennels, it shows a modal so the user can pick one.
// Remove once no inbound legacy links remain in the wild.

import { useEffect, useState } from "react";
import type { KennelContext } from "@/lib/types/kennel";
import type { RunEvent } from "@/lib/api";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import { StickyNav } from "@/components/StickyNav";
import { RunsPageClient } from "@/components/kennel/RunsPageClient";

type KennelRuns = {
  slug: string;
  kennel: KennelContext;
  futureRuns: RunEvent[];
  pastRuns: RunEvent[];
};

type SelectorKennel = { slug: string; name: string; customDomain: string | null };

type State =
  | { kind: "runs"; data: KennelRuns }
  | { kind: "selector"; kennels: SelectorKennel[]; origin: string };

function extractUuid(hash: string): { single: string } | { multi: string } | null {
  // Path form: #/RD/<uuid>
  const pathMatch = hash.match(/^#\/RD\/([a-fA-F0-9\-]+)$/);
  if (pathMatch) return { single: pathMatch[1] };

  // Query string form: #/RD?publicKennelIds=<uuid>[,<uuid>...]
  if (!hash.startsWith("#/RD?")) return null;
  const params = new URLSearchParams(hash.slice("#/RD?".length));
  const ids = params.get("publicKennelIds")?.trim();
  if (!ids) return null;

  const parts = ids.split(",").map((s) => s.trim()).filter(Boolean);
  if (parts.length === 1) return { single: parts[0] };
  if (parts.length > 1) return { multi: ids };
  return null;
}

export function LegacyRedirectHandler() {
  const [state, setState] = useState<State | null>(null);

  useEffect(() => {
    const clearLegacy = () =>
      document.documentElement.removeAttribute("data-legacy");

    const parsed = extractUuid(window.location.hash);
    if (!parsed) {
      // Not a legacy URL — reveal the global page immediately.
      clearLegacy();
      return;
    }

    if ("single" in parsed) {
      fetch(`/api/legacy-runs?uuid=${encodeURIComponent(parsed.single)}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((data: KennelRuns | null) => {
          if (data) setState({ kind: "runs", data });
          else clearLegacy();
        })
        .catch(clearLegacy);
    } else {
      fetch(`/api/resolve-kennels?ids=${encodeURIComponent(parsed.multi)}`)
        .then((r) => r.json())
        .then((kennels: SelectorKennel[]) => {
          if (kennels.length === 1) {
            fetch(`/api/legacy-runs?uuid=${encodeURIComponent(parsed.multi)}`)
              .then((r) => (r.ok ? r.json() : null))
              .then((data: KennelRuns | null) => {
                if (data) setState({ kind: "runs", data });
                else clearLegacy();
              })
              .catch(clearLegacy);
          } else if (kennels.length > 1) {
            setState({ kind: "selector", kennels, origin: window.location.origin });
          } else {
            clearLegacy();
          }
        })
        .catch(clearLegacy);
    }
  }, []);

  if (!state) return null;

  // ── Multiple kennels: show picker ───────────────────────────────────────────
  if (state.kind === "selector") {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
        <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-8 max-w-md w-full mx-4">
          <h2 className="text-xl font-semibold text-zinc-100 mb-1">Multiple kennels found</h2>
          <p className="text-sm text-zinc-400 mb-6">Choose a kennel to continue</p>
          <ul className="space-y-2">
            {state.kennels.map((k) => {
              const dest = k.customDomain
                ? `https://${k.customDomain}/runs`
                : `${state.origin}/${k.slug}/runs`;
              return (
                <li key={k.slug}>
                  <a
                    href={dest}
                    className="block px-4 py-3 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-100 transition-colors"
                  >
                    {k.name}
                  </a>
                </li>
              );
            })}
          </ul>
        </div>
      </div>
    );
  }

  // ── Single kennel: render runs page inline ──────────────────────────────────
  const { slug, kennel, futureRuns, pastRuns } = state.data;

  return (
    <div
      className="fixed inset-0 z-50 overflow-auto"
      style={
        {
          "--color-primary": kennel.primaryColor,
          "--color-primary-fg": kennel.primaryFg,
          "--color-accent": kennel.accentColor,
        } as React.CSSProperties
      }
    >
      <KennelBackground kennel={kennel} />
      <StickyNav kennel={kennel} slug={slug} alwaysVisible />
      <div className="pt-20">
        <RunsPageClient
          futureRuns={futureRuns}
          pastRuns={pastRuns}
          kennel={kennel}
          slug={slug}
        />
      </div>
    </div>
  );
}
