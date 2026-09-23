"use client";

/**
 * The app's chat page (chat_page.dart, flutter_chat_ui with the app's
 * theme): my bubbles blue with white text on the right, everyone else's
 * in slate on the left with their avatar and name, the time under each,
 * a composer at the bottom. No push on the web: the thread polls for
 * what is new every ten seconds, and posting appends at once.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Send } from "lucide-react";
import type { ChatKind, ChatMessageRow } from "@/lib/member-api";
import { HC_BLUE, HC_RED } from "@/components/member/app-look";

/** HC.EventMessage.MessageContent is NVARCHAR(4000); the SPs refuse more. */
const CHAT_MESSAGE_MAX = 4000;

const POLL_MS = 10000;

export function ChatThread({ kind, id, title, me, initial, back }: {
  kind: ChatKind; id: string; title: string; me: string; initial: ChatMessageRow[]; back: string;
}) {
  // Oldest first on screen; the SP hands them newest first.
  const [messages, setMessages] = useState<ChatMessageRow[]>(() => [...initial].sort((a, b) => a.sequenceCount - b.sequenceCount));
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const bottom = useRef<HTMLDivElement>(null);
  const lastSeq = useRef(messages.length ? messages[messages.length - 1].sequenceCount : 0);

  const merge = useCallback((rows: ChatMessageRow[]) => {
    if (rows.length === 0) return;
    setMessages((ms) => {
      const seen = new Set(ms.map((m) => m.id.toUpperCase()));
      const add = rows.filter((r) => !seen.has(r.id.toUpperCase()));
      if (add.length === 0) return ms;
      const next = [...ms, ...add].sort((a, b) => a.sequenceCount - b.sequenceCount);
      lastSeq.current = Math.max(lastSeq.current, ...next.map((m) => m.sequenceCount));
      return next;
    });
  }, []);

  useEffect(() => {
    let stop = false;
    const tick = async () => {
      try {
        const r = await fetch(`/api/member/chat?kind=${kind}&id=${encodeURIComponent(id)}&since=${lastSeq.current}`, { cache: "no-store" });
        if (r.ok) { const j = (await r.json()) as { messages?: ChatMessageRow[] }; if (!stop) merge(j.messages ?? []); }
      } catch { /* next tick */ }
    };
    const h = window.setInterval(tick, POLL_MS);
    const onVisible = () => { if (document.visibilityState === "visible") tick(); };
    document.addEventListener("visibilitychange", onVisible);
    return () => { stop = true; window.clearInterval(h); document.removeEventListener("visibilitychange", onVisible); };
  }, [kind, id, merge]);

  useEffect(() => { bottom.current?.scrollIntoView({ block: "end" }); }, [messages.length]);

  async function send() {
    const body = text.trim();
    if (!body || sending) return;
    setSending(true); setError(null);
    const messageId = crypto.randomUUID();
    try {
      const r = await fetch("/api/member/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ kind, id, messageId, text: body }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "Couldn't send."); return; }
      setText("");
      merge([{ id: messageId.toUpperCase(), type: "text", text: body, roomId: null, createdAt: Date.now(), authorId: me, authorFirstName: "", authorImageUrl: null, sequenceCount: lastSeq.current + 0.5 }]);
    } finally { setSending(false); }
  }

  return (
    <div className="-mx-3 -mt-3 flex flex-col sm:-mt-4" style={{ minHeight: "calc(100vh - 60px - 64px)" }}>
      <div className="sticky top-12 z-40 flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href={back} aria-label="Back" className="text-2xl leading-none">‹</Link>
        <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">{title}</h2>
        <span className="w-4" />
      </div>

      <div className="flex-1 bg-white px-3 py-3">
        {messages.length === 0 && <p className="py-10 text-center text-[17px] text-zinc-500">No messages yet. Say something!</p>}
        <ul className="space-y-3">
          {messages.map((m, i) => {
            const mine = m.authorId.toUpperCase() === me;
            const showAuthor = !mine && (i === 0 || messages[i - 1].authorId.toUpperCase() !== m.authorId.toUpperCase());
            return (
              <li key={m.id} className={`flex items-end gap-2 ${mine ? "justify-end" : "justify-start"}`}>
                {!mine && (
                  <div className="h-8 w-8 shrink-0 overflow-hidden rounded-full bg-zinc-200">
                    {m.authorImageUrl?.startsWith("http") && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={m.authorImageUrl} alt="" className="h-full w-full object-cover" />
                    )}
                  </div>
                )}
                <div className="max-w-[78%]">
                  {showAuthor && <div className="mb-0.5 pl-1 text-[13px] text-zinc-500">{m.authorFirstName}</div>}
                  <div className="rounded-2xl px-4 py-2.5 text-[17px] leading-snug"
                    style={mine ? { backgroundColor: HC_BLUE, color: "#fff" } : { backgroundColor: "#E2E8F0", color: "#1E293B" }}>
                    <div className="whitespace-pre-wrap break-words">{linkify(m.text)}</div>
                    <div className="mt-1 text-right text-[13px]" style={{ opacity: 0.7 }} suppressHydrationWarning>{hhmm(m.createdAt)}</div>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
        <div ref={bottom} />
      </div>

      {error && <p className="bg-white px-3 py-1 text-center text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}

      {/* Composer */}
      <form className="sticky bottom-16 flex items-end gap-2 border-t border-zinc-200 bg-white px-3 py-2" onSubmit={(e) => { e.preventDefault(); send(); }}>
        <textarea
          value={text} onChange={(e) => setText(e.target.value)} rows={1} maxLength={CHAT_MESSAGE_MAX} placeholder="Message"
          onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); } }}
          className="max-h-32 min-h-[44px] flex-1 resize-y rounded-2xl border border-zinc-300 bg-zinc-50 px-4 py-2.5 text-[17px] text-zinc-900 focus:outline-none focus:ring-2 focus:ring-blue-700"
        />
        {/* Only once it matters: a permanent "0/4000" is noise on a chat box. */}
        {text.length > CHAT_MESSAGE_MAX - 400 && (
          <span className="shrink-0 self-center text-xs tabular-nums text-zinc-500">{text.length.toLocaleString()}/{CHAT_MESSAGE_MAX.toLocaleString()}</span>
        )}
        <button type="submit" disabled={sending || !text.trim()} aria-label="Send"
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-white disabled:opacity-40" style={{ backgroundColor: HC_BLUE }}>
          <Send className="h-5 w-5" />
        </button>
      </form>
    </div>
  );
}

function hhmm(ms: number): string {
  return new Date(Number(ms)).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
}

function linkify(text: string): React.ReactNode {
  const parts = text.split(/(https?:\/\/[^\s]+)/g);
  return parts.map((p, i) => /^https?:\/\//.test(p)
    ? <a key={i} href={p} target="_blank" rel="noopener noreferrer" className="underline">{p}</a>
    : <span key={i}>{p}</span>);
}
