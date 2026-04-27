"use client";

import { useEffect, useState } from "react";

// ─── Legacy URL shim ───────────────────────────────────────────────────────────
// The old hashruns.org site used a hash-based SPA URL scheme:
//
//   www.hashruns.org/#/RD?publicKennelIds=<uuid>[,<uuid>...]
//
// This scheme is DEPRECATED. The new site uses path-based kennel URLs:
//
//   www.hashruns.org/<slug>
//
// This component runs client-side on every global page load. If it detects a
// legacy hash URL it resolves the UUID(s) to slug(s) and redirects silently.
// Remove once no inbound legacy links remain in the wild.

type Kennel = { slug: string; name: string; customDomain: string | null };
type RedirectState = { kennels: Kennel[]; baseDomain: string };

export function LegacyRedirectHandler() {
  const [state, setState] = useState<RedirectState | null>(null);

  useEffect(() => {
    const hash = window.location.hash;
    if (!hash.startsWith("#/RD")) return;

    const query = hash.slice("#/RD".length).replace(/^\?/, "");
    const params = new URLSearchParams(query);
    const ids = params.get("publicKennelIds");
    if (!ids?.trim()) return;

    fetch(`/api/resolve-kennels?ids=${encodeURIComponent(ids)}`)
      .then((r) => r.json())
      .then((kennels: Kennel[]) => {
        if (kennels.length === 1) {
          const { slug, customDomain } = kennels[0];
          // Custom domains get their own origin; otherwise use path-based URL
          // on the current origin (www.hashruns.org/slug — no wildcard cert needed).
          window.location.href = customDomain
            ? `https://${customDomain}`
            : `${window.location.origin}/${slug}`;
        } else if (kennels.length > 1) {
          setState({ kennels, baseDomain: window.location.origin });
        }
      })
      .catch(() => undefined);
  }, []);

  if (!state) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
      <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-8 max-w-md w-full mx-4">
        <h2 className="text-xl font-semibold text-zinc-100 mb-1">
          Multiple kennels found
        </h2>
        <p className="text-sm text-zinc-400 mb-6">Choose a kennel to continue</p>
        <ul className="space-y-2">
          {state.kennels.map((k) => {
            const dest = k.customDomain
              ? `https://${k.customDomain}`
              : `${state.baseDomain}/${k.slug}`;
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
