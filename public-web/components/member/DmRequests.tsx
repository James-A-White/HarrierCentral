"use client";

/**
 * Direct-message requests waiting on me, at the top of the chat list
 * (E9.F1.S19). Accept opens the new thread; Decline drops the row and
 * says nothing to the requester — a decline is silent by design.
 */
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import type { DmRequest } from "@/lib/member-api";
import { dmHref } from "@/lib/chat-links";
import { HC_BLUE, HC_RED } from "@/components/member/app-look";
import { HasherPhoto } from "@/components/member/HasherPhoto";

export function DmRequests({ initial }: { initial: DmRequest[] }) {
  const router = useRouter();
  const [requests, setRequests] = useState<DmRequest[]>(initial);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function respond(r: DmRequest, accept: 0 | 1) {
    if (busy) return;
    setBusy(r.FromPublicHasherId); setError(null);
    try {
      const res = await fetch("/api/member/dm/requests", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fromPublicHasherId: r.FromPublicHasherId.toLowerCase(), accept }),
      });
      const j = (await res.json().catch(() => ({}))) as { ok?: boolean; threadId?: string | null; error?: string };
      if (!res.ok || !j.ok) { setError(j.error ?? (accept ? "Couldn't accept that." : "Couldn't decline that.")); return; }
      setRequests((rs) => rs.filter((x) => x.FromPublicHasherId !== r.FromPublicHasherId));
      if (accept === 1 && j.threadId) { router.push(dmHref(j.threadId)); return; }
    } catch {
      setError("Couldn't answer that just now. Check your connection.");
    } finally {
      setBusy(null);
    }
  }

  if (requests.length === 0) return null;
  return (
    <>
      <h3 className="px-3 pb-1 pt-4 text-[15px] font-bold uppercase tracking-wide text-white/90">Requests</h3>
      <ul className="space-y-2 px-2">
        {requests.map((r) => {
          const isBusy = busy === r.FromPublicHasherId;
          return (
            <li key={r.FromPublicHasherId} className="flex flex-wrap items-center gap-3 rounded-md bg-white px-3 py-2.5 text-zinc-900 shadow">
              <HasherPhoto url={r.Photo} className="h-12 w-12" />
              <div className="min-w-0 flex-1">
                <div className="truncate text-[18px] font-semibold">{r.DisplayName}</div>
                <div className="truncate text-[14px] text-zinc-500">wants to message you</div>
              </div>
              <div className="flex shrink-0 items-center gap-2">
                <button type="button" disabled={busy != null} onClick={() => respond(r, 1)}
                  className="inline-flex items-center gap-1.5 rounded-full px-4 py-1.5 text-[15px] font-semibold text-white disabled:opacity-50" style={{ backgroundColor: HC_BLUE }}>
                  {isBusy && <Loader2 className="h-4 w-4 animate-spin" />} Accept
                </button>
                <button type="button" disabled={busy != null} onClick={() => respond(r, 0)}
                  className="rounded-full border border-zinc-300 px-4 py-1.5 text-[15px] font-semibold text-zinc-700 hover:bg-zinc-100 disabled:opacity-50">
                  Decline
                </button>
              </div>
            </li>
          );
        })}
      </ul>
      {error && <p className="px-3 pt-2 text-center text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}
    </>
  );
}
