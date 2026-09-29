"use client";

// ─── Legacy URL shim — multi-kennel picker ────────────────────────────────────
// The inline <script> in layout.tsx handles single-UUID legacy URLs by calling
// window.location.replace('/rd/<uuid>') before first paint. This component only
// runs when there are multiple comma-separated UUIDs — it shows a picker so the
// user can choose which kennel to navigate to.
// Remove once no inbound legacy links remain in the wild.

import { useEffect, useState } from "react";

type SelectorKennel = { slug: string; name: string; customDomain: string | null };
type SelectorChoice = { slug: string; name: string; dest: string };

export function LegacyRedirectHandler() {
  const [kennels, setKennels] = useState<SelectorChoice[] | null>(null);

  useEffect(() => {
    const h = window.location.hash;
    if (!h.startsWith("#/RD?")) return;

    const ids = new URLSearchParams(h.slice("#/RD?".length)).get("publicKennelIds")?.trim();
    if (!ids) return;

    const parts = ids.split(",").map((s) => s.trim()).filter(Boolean);
    if (parts.length <= 1) return; // single UUID handled by inline script redirect

    // The destination hrefs need the page origin, which is only knowable in the
    // browser — resolved here, alongside the kennels, in the one setState.
    const origin = window.location.origin;
    fetch(`/api/resolve-kennels?ids=${encodeURIComponent(ids)}`)
      .then((r) => r.json())
      .then((resolved: SelectorKennel[]) => {
        if (resolved.length > 0) {
          setKennels(resolved.map((k) => ({
            slug: k.slug,
            name: k.name,
            dest: k.customDomain
              ? `https://${k.customDomain}/runs`
              : `${origin}/${k.slug}/runs`,
          })));
        }
      })
      .catch(() => {});
  }, []);

  if (!kennels) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm">
      <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-8 max-w-md w-full mx-4">
        <h2 className="text-xl font-semibold text-zinc-100 mb-1">Multiple kennels found</h2>
        <p className="text-sm text-zinc-400 mb-6">Choose a kennel to continue</p>
        <ul className="space-y-2">
          {kennels.map((k) => (
            <li key={k.slug}>
              <a
                href={k.dest}
                className="block px-4 py-3 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-100 transition-colors"
              >
                {k.name}
              </a>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
