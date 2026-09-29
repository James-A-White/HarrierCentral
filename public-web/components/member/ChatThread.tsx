"use client";

/**
 * The app's chat page (chat_page.dart, flutter_chat_ui with the app's
 * theme): my bubbles blue with white text on the right, everyone else's
 * in slate on the left with their avatar and name, the time under each,
 * a composer at the bottom. No push on the web: the thread polls for
 * what is new every ten seconds, and posting appends at once.
 *
 * E9.F1.S11–S15 (2026-09-29): a message is text, a photo or a location
 * (messageKind); photos open a carousel of every photo in the chat; each
 * message has a menu — hover on a desktop, long-press or the ⋯ on a phone —
 * with Copy, and Delete where the SP says canDelete. Every fetch carries the
 * thread's removed ids, so a deletion made anywhere disappears here too.
 *
 * E9.F1.S16/S17: someone else's message also offers Block <name> — from
 * then on every chat reader hides them from me, so the thread is re-fetched
 * in full to drop what was already drawn — and Report, which sends the
 * message to Harrier Central's reviewers with an optional reason.
 *
 * E9.F1.S7/S19: someone else's message offers Message <name>, the only
 * door to a direct message — the server answers open (go there), requested,
 * refused or blocked. A DM is this same page with kind `dm`: the other
 * hasher's photo and name up top, a header menu (Mute, Block, End
 * conversation), and a composer that closes when the server says canSend
 * is 0 — which every poll re-checks, so an ending made elsewhere reaches
 * an open page.
 */
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import dynamic from "next/dynamic";
import { useRouter } from "next/navigation";
import { ImagePlus, Loader2, MapPin, MoreHorizontal, MoreVertical, Send } from "lucide-react";
import { CHAT_REPORT_REASON_MAX, type ChatKind, type ChatMessageRow, type DmThreadInfo } from "@/lib/member-api";
import type { KennelContext } from "@/lib/types/kennel";
import {
  CHAT_KIND_LOCATION, CHAT_KIND_PHOTO, CHAT_KIND_TEXT, chatKindOf, chatLocationUrl, formatChatLocation, parseChatLocation,
  type ChatMessageKind,
} from "@/lib/chat-content";
import { dmHref } from "@/lib/chat-links";
import { HC_BLUE, HC_RED } from "@/components/member/app-look";
import { ChatPhotoViewer, type ChatPhoto } from "@/components/member/ChatPhotoViewer";
import { HasherPhoto } from "@/components/member/HasherPhoto";

// Leaflet touches window at import time, so the pin picker is client-only.
const ChatPinPicker = dynamic(() => import("@/components/member/ChatPinPicker"), { ssr: false });

/** HC.EventMessage.MessageContent is NVARCHAR(4000); the SPs refuse more. */
const CHAT_MESSAGE_MAX = 4000;

const POLL_MS = 10000;
const LONG_PRESS_MS = 500;

/** A row on screen: the SP's row, or one of mine that the server has not confirmed yet. */
type Shown = ChatMessageRow & {
  /** Mine, drawn before the server had it. Its sequenceCount is a placeholder, never a watermark. */
  local?: boolean;
  /** A photo on its way up, or one that failed and can be retried. */
  pending?: "sending" | "failed";
  /** The picked file as an object URL, drawn while the upload runs. */
  preview?: string;
};

const upper = (id: string) => id.toUpperCase();

/** Someone to block or message: a message's author, or the other half of a DM. */
type Who = { authorId: string; authorFirstName: string };

/** What a poll or reload learns about a DM, applied on top of what the page opened with. */
type DmLive = Pick<DmThreadInfo, "canSend" | "muted">;

export function ChatThread({ kind, id, title, me, initial, back, kennel, dm }: {
  kind: ChatKind; id: string; title: string; me: string; initial: ChatMessageRow[]; back: string; kennel: KennelContext | null;
  /** The other hasher and my standing with them; set for kind "dm" only. */
  dm?: DmThreadInfo;
}) {
  const router = useRouter();
  // Oldest first on screen; the SP hands them newest first.
  const [messages, setMessages] = useState<Shown[]>(() => [...initial].sort((a, b) => a.sequenceCount - b.sequenceCount));
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<{ text: string; ms: number } | null>(null);
  const [menuFor, setMenuFor] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Shown | null>(null);
  const [confirmBlock, setConfirmBlock] = useState<Who | null>(null);
  const [blocking, setBlocking] = useState(false);
  // Direct messages (E9.F1.S7/S19).
  const [dmLive, setDmLive] = useState<DmLive>({ canSend: dm?.canSend ?? 1, muted: dm?.muted ?? 0 });
  const [headerMenu, setHeaderMenu] = useState(false);
  const [confirmEnd, setConfirmEnd] = useState(false);
  const [dmBusy, setDmBusy] = useState(false);
  /** The author being messaged, while the server decides. */
  const [messaging, setMessaging] = useState<string | null>(null);
  const applyDm = useCallback((d: Partial<DmLive> | undefined) => {
    if (!d || d.canSend == null) return;
    setDmLive({ canSend: Number(d.canSend) === 1 ? 1 : 0, muted: Number(d.muted) === 1 ? 1 : 0 });
  }, []);
  const other: Who | null = dm ? { authorId: dm.otherPublicHasherId, authorFirstName: dm.otherDisplayName } : null;
  const canSend = kind !== "dm" || dmLive.canSend === 1;
  const [reportFor, setReportFor] = useState<Shown | null>(null);
  const [reportReason, setReportReason] = useState("");
  const [reporting, setReporting] = useState(false);
  const [viewerAt, setViewerAt] = useState<number | null>(null);
  const [locationMenu, setLocationMenu] = useState(false);
  const [locating, setLocating] = useState(false);
  const [pinPicker, setPinPicker] = useState(false);
  const bottom = useRef<HTMLDivElement>(null);
  const fileInput = useRef<HTMLInputElement>(null);
  // Only server rows move the watermark. A local row's sequenceCount is
  // last + 0.5 so it sorts at the end, and `since=12.5` is not an INT —
  // the SP's parameter would refuse it and polling would stop.
  const lastSeq = useRef(initial.reduce((m, r) => Math.max(m, r.sequenceCount), 0));
  // Ids that must not come back: removed on the server, or being deleted here.
  const gone = useRef(new Set<string>());
  // Picked files by message id, so a failed photo can be retried.
  const files = useRef(new Map<string, Blob>());
  // Every object URL made for a preview, revoked when the page goes.
  const previews = useRef(new Set<string>());

  const merge = useCallback((rows: Shown[]) => {
    if (rows.length === 0) return;
    for (const r of rows) if (!r.local && Number.isInteger(r.sequenceCount)) lastSeq.current = Math.max(lastSeq.current, r.sequenceCount);
    setMessages((ms) => {
      const seen = new Set(ms.map((m) => upper(m.id)));
      const add = rows.filter((r) => !seen.has(upper(r.id)) && !gone.current.has(upper(r.id)));
      if (add.length === 0) return ms;
      return [...ms, ...add].sort((a, b) => a.sequenceCount - b.sequenceCount);
    });
  }, []);

  const drop = useCallback((ids: string[]) => {
    if (ids.length === 0) return;
    const set = new Set(ids.map(upper));
    for (const i of set) gone.current.add(i);
    setMessages((ms) => ms.some((m) => set.has(upper(m.id))) ? ms.filter((m) => !set.has(upper(m.id))) : ms);
  }, []);

  const patch = useCallback((messageId: string, p: Partial<Shown>) => {
    setMessages((ms) => ms.map((m) => upper(m.id) === upper(messageId) ? { ...m, ...p } : m));
  }, []);

  useEffect(() => {
    let stop = false;
    const tick = async () => {
      try {
        const r = await fetch(`/api/member/chat?kind=${kind}&id=${encodeURIComponent(id)}&since=${lastSeq.current}`, { cache: "no-store" });
        if (r.ok) {
          const j = (await r.json()) as { messages?: ChatMessageRow[]; removed?: string[]; dm?: Partial<DmLive> };
          if (stop) return;
          drop(j.removed ?? []);
          merge(j.messages ?? []);
          applyDm(j.dm);
        }
      } catch { /* next tick */ }
    };
    const h = window.setInterval(tick, POLL_MS);
    const onVisible = () => { if (document.visibilityState === "visible") tick(); };
    document.addEventListener("visibilitychange", onVisible);
    return () => { stop = true; window.clearInterval(h); document.removeEventListener("visibilitychange", onVisible); };
  }, [kind, id, merge, drop, applyDm]);

  // Object URLs outlive nothing: let them go with the page.
  useEffect(() => {
    const urls = previews.current;
    return () => { for (const u of urls) URL.revokeObjectURL(u); urls.clear(); };
  }, []);

  useEffect(() => { bottom.current?.scrollIntoView({ block: "end" }); }, [messages.length]);

  useEffect(() => {
    if (!notice) return;
    const h = window.setTimeout(() => setNotice(null), notice.ms);
    return () => window.clearTimeout(h);
  }, [notice]);

  /** A passing line under the messages: two seconds for "Copied", longer for something worth reading. */
  const say = (text: string, ms = 2000) => setNotice({ text, ms });

  /** POST one message. Null on success, else the reason to show. */
  async function post(messageId: string, content: string, messageKind: ChatMessageKind): Promise<string | null> {
    try {
      const r = await fetch("/api/member/chat", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ kind, id, messageId, text: content, messageKind }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      return r.ok && j.ok ? null : j.error ?? "Couldn't send.";
    } catch {
      return "Couldn't send. Check your connection.";
    }
  }

  function mine(messageId: string, content: string, messageKind: ChatMessageKind, extra: Partial<Shown> = {}): Shown {
    return {
      id: upper(messageId), type: "text", text: content, roomId: null, createdAt: Date.now(), authorId: me, authorFirstName: "",
      authorImageUrl: null, sequenceCount: lastSeq.current + 0.5, messageKind, canDelete: 1, local: true, ...extra,
    };
  }

  async function send() {
    const body = text.trim();
    if (!body || sending) return;
    setSending(true); setError(null);
    const messageId = crypto.randomUUID();
    try {
      const err = await post(messageId, body, CHAT_KIND_TEXT);
      if (err) { setError(err); return; }
      setText("");
      merge([mine(messageId, body, CHAT_KIND_TEXT)]);
    } finally { setSending(false); }
  }

  // ── Photos (E9.F1.S11) ─────────────────────────────────────────────────────

  async function uploadAndSend(messageId: string, file: Blob) {
    patch(messageId, { pending: "sending" });
    let reason: string | null = null;
    try {
      const form = new FormData();
      form.append("file", file, "photo.jpg");
      const r = await fetch("/api/member/chat/photo", { method: "POST", body: form });
      const j = (await r.json().catch(() => ({}))) as { blobUrl?: string; error?: string };
      if (!r.ok || !j.blobUrl) reason = j.error ?? "Couldn't upload the photo.";
      else {
        reason = await post(messageId, j.blobUrl, CHAT_KIND_PHOTO);
        if (!reason) {
          files.current.delete(messageId);
          patch(messageId, { text: j.blobUrl, pending: undefined });
          return;
        }
      }
    } catch {
      reason = "Couldn't upload the photo. Check your connection.";
    }
    patch(messageId, { pending: "failed" });
    setError(reason);
  }

  async function onPickPhoto(e: React.ChangeEvent<HTMLInputElement>) {
    const picked = e.target.files?.[0];
    e.target.value = "";   // picking the same file again must still fire
    if (!picked) return;
    if (!picked.type.startsWith("image/")) { setError("Only photos can be sent."); return; }
    setError(null);
    const messageId = upper(crypto.randomUUID());
    const file = await browserReadable(picked);
    if (file.size > 10 * 1024 * 1024) { setError("That photo is too big. Photos can be up to 10 MB."); return; }
    files.current.set(messageId, file);
    const preview = URL.createObjectURL(file);
    previews.current.add(preview);
    merge([mine(messageId, "", CHAT_KIND_PHOTO, { pending: "sending", preview })]);
    await uploadAndSend(messageId, file);
  }

  function retryPhoto(m: Shown) {
    const file = files.current.get(upper(m.id));
    if (file) { setError(null); void uploadAndSend(upper(m.id), file); }
  }

  function discardPhoto(m: Shown) {
    files.current.delete(upper(m.id));
    if (m.preview) { URL.revokeObjectURL(m.preview); previews.current.delete(m.preview); }
    setMessages((ms) => ms.filter((x) => upper(x.id) !== upper(m.id)));
  }

  // ── Locations (E9.F1.S12) ──────────────────────────────────────────────────

  async function sendLocation(lat: number, lng: number) {
    setError(null); setSending(true);
    const messageId = crypto.randomUUID();
    const content = chatLocationUrl(lat, lng);
    try {
      const err = await post(messageId, content, CHAT_KIND_LOCATION);
      if (err) { setError(err); return; }
      merge([mine(messageId, content, CHAT_KIND_LOCATION)]);
    } finally { setSending(false); }
  }

  function whereIAmNow() {
    setLocationMenu(false);
    if (!("geolocation" in navigator)) { setError("This browser can't share its location. Try dropping a pin."); return; }
    setLocating(true); setError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => { setLocating(false); void sendLocation(pos.coords.latitude, pos.coords.longitude); },
      (err) => {
        setLocating(false);
        setError(err.code === err.PERMISSION_DENIED
          ? "Location is turned off for this site. Allow it in your browser, or drop a pin instead."
          : "Couldn't find where you are just now. Try again, or drop a pin.");
      },
      { enableHighAccuracy: true, timeout: 15_000, maximumAge: 30_000 },
    );
  }

  // ── Copy and delete (E9.F1.S13–S15) ────────────────────────────────────────

  async function copy(m: Shown) {
    setMenuFor(null);
    try {
      // Text is the text; a photo or a location is its URL.
      await navigator.clipboard.writeText(m.text);
      say("Copied");
    } catch {
      setError("Couldn't copy on this browser.");
    }
  }

  async function reallyDelete(m: Shown) {
    setConfirmDelete(null);
    const key = upper(m.id);
    // Gone at once; back where it was if the server says no.
    gone.current.add(key);
    setMessages((ms) => ms.filter((x) => upper(x.id) !== key));
    let reason: string | null = null;
    try {
      const r = await fetch("/api/member/chat", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ messageId: m.id.toLowerCase() }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (r.ok && j.ok) return;
      reason = j.error ?? "That message could not be deleted.";
    } catch {
      reason = "Couldn't delete. Check your connection.";
    }
    gone.current.delete(key);
    setMessages((ms) => ms.some((x) => upper(x.id) === key) ? ms : [...ms, m].sort((a, b) => a.sequenceCount - b.sequenceCount));
    setError(reason);
  }

  // ── Block and report (E9.F1.S16/S17) ───────────────────────────────────────

  /**
   * The whole thread again, replacing what is drawn. A delta fetch only
   * adds, so after a block — which changes what the server will show me —
   * it is the only way the blocked hasher's messages leave the screen.
   * Photos still on their way up are mine and stay.
   */
  const reload = useCallback(async () => {
    const r = await fetch(`/api/member/chat?kind=${kind}&id=${encodeURIComponent(id)}`, { cache: "no-store" });
    if (!r.ok) return;
    const j = (await r.json()) as { messages?: ChatMessageRow[]; removed?: string[]; dm?: Partial<DmLive> };
    for (const x of j.removed ?? []) gone.current.add(upper(x));
    const rows: Shown[] = (j.messages ?? []).filter((m) => !gone.current.has(upper(m.id)));
    for (const m of rows) if (Number.isInteger(m.sequenceCount)) lastSeq.current = Math.max(lastSeq.current, m.sequenceCount);
    setMessages((ms) => [...rows, ...ms.filter((m) => m.pending)].sort((a, b) => a.sequenceCount - b.sequenceCount));
    applyDm(j.dm);
  }, [kind, id, applyDm]);

  async function reallyBlock(w: Who) {
    if (blocking) return;
    setBlocking(true); setError(null);
    try {
      const r = await fetch("/api/member/blocked", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ targetPublicHasherId: w.authorId.toLowerCase(), blocked: 1 }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "They could not be blocked."); return; }
      setConfirmBlock(null);
      await reload().catch(() => undefined);
      say(`${w.authorFirstName || "They"} blocked`);
    } catch {
      setError("Couldn't block them. Check your connection.");
    } finally {
      setBlocking(false);
    }
  }

  // ── Direct messages (E9.F1.S7/S19) ─────────────────────────────────────────

  /**
   * "Message <name>": the server decides. `open` goes to the thread; the
   * other three are answers, not errors, and each has its line. A refusal
   * says only what the target chose — a block by them looks like a request.
   */
  async function messageHasher(m: Shown) {
    setMenuFor(null); setError(null);
    if (messaging) return;
    const name = m.authorFirstName || "They";
    setMessaging(upper(m.authorId));
    try {
      const r = await fetch("/api/member/dm", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ targetPublicHasherId: m.authorId.toLowerCase() }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; outcome?: string; threadId?: string | null; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "That conversation could not be started."); return; }
      // Back from the DM is this chat, title and all.
      if (j.outcome === "open" && j.threadId) { router.push(dmHref(j.threadId, window.location.pathname + window.location.search)); return; }
      if (j.outcome === "requested") say(`${name} will be asked. You'll be told when they accept.`, 4000);
      else if (j.outcome === "refused") say(`${name} isn't accepting messages.`, 3500);
      else if (j.outcome === "blocked") say(`You've blocked ${name}.`, 3500);
      else setError("That conversation could not be started.");
    } catch {
      setError("Couldn't start that conversation. Check your connection.");
    } finally {
      setMessaging(null);
    }
  }

  async function setMute(mute: 0 | 1) {
    setHeaderMenu(false);
    if (dmBusy) return;
    setDmBusy(true); setError(null);
    try {
      const r = await fetch("/api/member/dm", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ threadId: id, mute }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; muted?: number; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "That could not be saved."); return; }
      setDmLive((d) => ({ ...d, muted: Number(j.muted) === 1 ? 1 : 0 }));
      say(Number(j.muted) === 1 ? "Muted — no notifications for this conversation" : "Unmuted", 3000);
    } catch {
      setError("Couldn't change that. Check your connection.");
    } finally {
      setDmBusy(false);
    }
  }

  async function reallyEnd() {
    if (dmBusy) return;
    setDmBusy(true); setError(null);
    try {
      const r = await fetch("/api/member/dm", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ threadId: id }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "That could not be saved."); return; }
      setConfirmEnd(false);
      setDmLive((d) => ({ ...d, canSend: 0 }));
      say("Conversation ended", 3000);
    } catch {
      setError("Couldn't end the conversation. Check your connection.");
    } finally {
      setDmBusy(false);
    }
  }

  function openReport(m: Shown) {
    setMenuFor(null); setError(null); setReportReason(""); setReportFor(m);
  }

  async function sendReport() {
    if (!reportFor || reporting) return;
    const reason = reportReason.trim();
    setReporting(true); setError(null);
    try {
      const r = await fetch("/api/member/chat/report", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ messageId: reportFor.id.toLowerCase(), reason: reason || undefined }) });
      const j = (await r.json().catch(() => ({}))) as { ok?: boolean; error?: string };
      if (!r.ok || !j.ok) { setError(j.error ?? "The report could not be sent."); return; }
      setReportFor(null);
      say("Reported — thank you.");
    } catch {
      setError("Couldn't send the report. Check your connection.");
    } finally {
      setReporting(false);
    }
  }

  // Every sent photo, in chat order, for the carousel.
  const photos: ChatPhoto[] = useMemo(() => messages
    .filter((m) => !m.pending && chatKindOf(m.messageKind, m.text) === CHAT_KIND_PHOTO)
    .map((m) => ({ id: m.id, url: m.text, createdAt: m.createdAt, author: upper(m.authorId) === me ? "You" : m.authorFirstName })), [messages, me]);

  return (
    <div className="-mx-3 -mt-3 flex flex-col sm:-mt-4" style={{ minHeight: "calc(100vh - 60px - 64px)" }}>
      <div className="sticky top-12 z-40 flex items-center gap-3 px-3 py-3 text-white" style={{ backgroundColor: "#580438" }}>
        <Link href={back} aria-label="Back" className="text-2xl leading-none">‹</Link>
        {dm ? (
          <>
            {/* A person, not a run: their photo beside their name. */}
            <div className="flex min-w-0 flex-1 items-center justify-center gap-2">
              <HasherPhoto url={dm.otherPhoto} className="h-8 w-8" />
              <h2 className="min-w-0 truncate text-[22px] font-medium">{title}</h2>
            </div>
            <div className="relative">
              <button type="button" aria-label="Conversation options" aria-expanded={headerMenu} disabled={dmBusy} onClick={() => setHeaderMenu((v) => !v)}
                className="flex h-8 w-8 items-center justify-center rounded-full hover:bg-white/15 disabled:opacity-60">
                {dmBusy ? <Loader2 className="h-5 w-5 animate-spin" /> : <MoreVertical className="h-6 w-6" />}
              </button>
              {headerMenu && (
                <>
                  <div className="fixed inset-0 z-40" onClick={() => setHeaderMenu(false)} />
                  <div role="menu" className="absolute right-0 top-full z-50 mt-1 min-w-[190px] overflow-hidden rounded-xl border border-zinc-200 bg-white text-[16px] text-zinc-900 shadow-xl">
                    <button type="button" role="menuitem" onClick={() => setMute(dmLive.muted === 1 ? 0 : 1)} className="block w-full px-4 py-2.5 text-left hover:bg-zinc-100">
                      {dmLive.muted === 1 ? "Unmute" : "Mute"}
                    </button>
                    <button type="button" role="menuitem" onClick={() => { setHeaderMenu(false); setError(null); setConfirmBlock(other); }} className="block w-full border-t border-zinc-200 px-4 py-2.5 text-left hover:bg-zinc-100">
                      Block {dm.otherDisplayName || "them"}
                    </button>
                    {dmLive.canSend === 1 && (
                      <button type="button" role="menuitem" onClick={() => { setHeaderMenu(false); setError(null); setConfirmEnd(true); }} className="block w-full border-t border-zinc-200 px-4 py-2.5 text-left font-semibold hover:bg-zinc-100" style={{ color: HC_RED }}>
                        End conversation
                      </button>
                    )}
                  </div>
                </>
              )}
            </div>
          </>
        ) : (
          <>
            <h2 className="min-w-0 flex-1 truncate text-center text-[22px] font-medium">{title}</h2>
            <span className="w-4" />
          </>
        )}
      </div>

      <div className="flex-1 bg-white px-3 py-3">
        {messages.length === 0 && <p className="py-10 text-center text-[17px] text-zinc-500">No messages yet. Say something!</p>}
        <ul className="space-y-3">
          {messages.map((m, i) => {
            const isMine = upper(m.authorId) === me;
            const showAuthor = !isMine && (i === 0 || upper(messages[i - 1].authorId) !== upper(m.authorId));
            const shownKind = m.pending ? CHAT_KIND_PHOTO : chatKindOf(m.messageKind, m.text);
            const canDelete = m.canDelete === 1 || (m.local === true && !m.pending);
            return (
              <MessageRow key={m.id} m={m} mine={isMine} showAuthor={showAuthor} kind={shownKind}
                menuOpen={menuFor === upper(m.id)} canMenu={!m.pending}
                onMenu={(open) => setMenuFor(open ? upper(m.id) : null)}
                onCopy={() => copy(m)} onDelete={canDelete ? () => { setMenuFor(null); setConfirmDelete(m); } : undefined}
                // Not inside a DM: the only other author there is the one you are already messaging.
                onMessage={!isMine && kind !== "dm" ? () => messageHasher(m) : undefined}
                messaging={messaging === upper(m.authorId)}
                onBlock={!isMine ? () => { setMenuFor(null); setError(null); setConfirmBlock(m); } : undefined}
                onReport={!isMine ? () => openReport(m) : undefined}
                onOpenPhoto={() => { const at = photos.findIndex((p) => upper(p.id) === upper(m.id)); if (at >= 0) setViewerAt(at); }}
                onRetry={() => retryPhoto(m)} onDiscard={() => discardPhoto(m)} />
            );
          })}
        </ul>
        <div ref={bottom} />
      </div>

      {error && <p className="bg-white px-3 py-1 text-center text-sm font-semibold" style={{ color: HC_RED }}>{error}</p>}
      {notice && <p className="bg-white px-3 py-1 text-center text-sm font-semibold text-zinc-600" role="status">{notice.text}</p>}

      {/* Composer — or, in a DM one side has ended or blocked, the reason there is none. */}
      {!canSend ? (
        <p className="sticky bottom-16 border-t border-zinc-200 bg-white px-3 py-4 text-center text-[16px] text-zinc-600" role="status">
          You can&apos;t message {dm?.otherDisplayName || "them"}.
        </p>
      ) : (
      <form className="sticky bottom-16 flex items-end gap-1.5 border-t border-zinc-200 bg-white px-3 py-2" onSubmit={(e) => { e.preventDefault(); send(); }}>
        <input ref={fileInput} type="file" accept="image/*" className="hidden" onChange={onPickPhoto} />
        <button type="button" aria-label="Send a photo" onClick={() => fileInput.current?.click()}
          className="flex h-11 w-9 shrink-0 items-center justify-center text-zinc-500 hover:text-zinc-800">
          <ImagePlus className="h-6 w-6" />
        </button>
        <button type="button" aria-label="Send a location" disabled={locating || sending} onClick={() => setLocationMenu(true)}
          className="flex h-11 w-9 shrink-0 items-center justify-center text-zinc-500 hover:text-zinc-800 disabled:opacity-40">
          {locating ? <Loader2 className="h-6 w-6 animate-spin" /> : <MapPin className="h-6 w-6" />}
        </button>
        <textarea
          value={text} onChange={(e) => setText(e.target.value)} rows={1} maxLength={CHAT_MESSAGE_MAX} placeholder="Message"
          onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); } }}
          className="max-h-32 min-h-[44px] min-w-0 flex-1 resize-y rounded-2xl border border-zinc-300 bg-zinc-50 px-4 py-2.5 text-[17px] text-zinc-900 focus:outline-none focus:ring-2 focus:ring-blue-700"
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
      )}

      {locationMenu && (
        <Sheet title="Send a location" onClose={() => setLocationMenu(false)}>
          <SheetButton onClick={whereIAmNow}>Where I am now</SheetButton>
          <SheetButton onClick={() => { setLocationMenu(false); setPinPicker(true); }}>Drop a pin</SheetButton>
        </Sheet>
      )}

      {pinPicker && <ChatPinPicker onClose={() => setPinPicker(false)} onPick={(p) => { setPinPicker(false); void sendLocation(p.lat, p.lng); }} />}

      {confirmDelete && (
        <Sheet title="Delete this message?" onClose={() => setConfirmDelete(null)}
          note={upper(confirmDelete.authorId) === me ? "It disappears for everyone in this chat." : `This is ${confirmDelete.authorFirstName || "someone else"}'s message. It disappears for everyone in this chat.`}>
          <SheetButton danger onClick={() => reallyDelete(confirmDelete)}>Delete</SheetButton>
        </Sheet>
      )}

      {confirmBlock && (
        <Sheet title={`Block ${confirmBlock.authorFirstName || "this hasher"}?`} onClose={() => { if (!blocking) setConfirmBlock(null); }}
          note="You won't see their messages in any chat, and they won't be told.">
          <SheetButton danger disabled={blocking} onClick={() => reallyBlock(confirmBlock)}>{blocking ? "Blocking…" : "Block"}</SheetButton>
        </Sheet>
      )}

      {confirmEnd && (
        <Sheet title="End this conversation?" onClose={() => { if (!dmBusy) setConfirmEnd(false); }}
          note={`You can still read it, but neither of you can send in it unless ${dm?.otherDisplayName || "they"} start${dm?.otherDisplayName ? "s" : ""} a new one. They won't be told.`}>
          <SheetButton danger disabled={dmBusy} onClick={reallyEnd}>{dmBusy ? "Ending…" : "End conversation"}</SheetButton>
        </Sheet>
      )}

      {reportFor && (
        <ReportDialog reason={reportReason} onReason={setReportReason} busy={reporting}
          onSend={sendReport} onClose={() => { if (!reporting) setReportFor(null); }} />
      )}

      {viewerAt != null && photos.length > 0 && (
        <ChatPhotoViewer photos={photos} start={viewerAt} kennel={kennel} title={title} onClose={() => setViewerAt(null)} />
      )}
    </div>
  );
}

function MessageRow({ m, mine, showAuthor, kind, menuOpen, canMenu, onMenu, onCopy, onDelete, onMessage, messaging, onBlock, onReport, onOpenPhoto, onRetry, onDiscard }: {
  m: Shown; mine: boolean; showAuthor: boolean; kind: ChatMessageKind; menuOpen: boolean; canMenu: boolean;
  onMenu: (open: boolean) => void; onCopy: () => void; onDelete?: () => void;
  /** Someone else's message in a run, kennel or room chat: Message <name> (E9.F1.S19), first in the menu. */
  onMessage?: () => void; messaging?: boolean;
  /** Someone else's message only: Block <name> and Report (E9.F1.S16/S17). */
  onBlock?: () => void; onReport?: () => void;
  onOpenPhoto: () => void; onRetry: () => void; onDiscard: () => void;
}) {
  const press = useRef<number | null>(null);
  const pressed = useRef(false);
  const touch = useRef(false);
  const cancelPress = () => { if (press.current != null) { window.clearTimeout(press.current); press.current = null; } };
  useEffect(() => cancelPress, []);

  const bubbleStyle = mine ? { backgroundColor: HC_BLUE, color: "#fff" } : { backgroundColor: "#E2E8F0", color: "#1E293B" };
  const menuButton = canMenu && (
    <button type="button" aria-label="Message options" aria-expanded={menuOpen} onClick={() => onMenu(!menuOpen)}
      className={`flex h-8 w-8 shrink-0 items-center justify-center self-center rounded-full text-zinc-500 transition hover:bg-zinc-100 focus-visible:opacity-100 ${menuOpen ? "opacity-100" : "opacity-60 [@media(hover:hover)]:opacity-0 [@media(hover:hover)]:group-hover:opacity-100"}`}>
      <MoreHorizontal className="h-5 w-5" />
    </button>
  );

  return (
    <li className={`group flex items-end gap-2 ${mine ? "justify-end" : "justify-start"}`}>
      {!mine && (
        <div className="h-8 w-8 shrink-0 overflow-hidden rounded-full bg-zinc-200">
          {m.authorImageUrl?.startsWith("http") && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={m.authorImageUrl} alt="" className="h-full w-full object-cover" />
          )}
        </div>
      )}
      {mine && menuButton}
      <div className="relative min-w-0 max-w-[78%]">
        {showAuthor && <div className="mb-0.5 pl-1 text-[13px] text-zinc-500">{m.authorFirstName}</div>}
        <div
          className={`rounded-2xl text-[17px] leading-snug [-webkit-touch-callout:none] [@media(hover:none)]:select-none ${kind === CHAT_KIND_PHOTO ? "p-1.5" : "px-4 py-2.5"}`}
          style={bubbleStyle}
          // Long-press on a phone opens the menu. A click that ends a long
          // press is swallowed, so it does not also open the photo or the map.
          onPointerDown={(e) => {
            touch.current = e.pointerType !== "mouse";
            if (!canMenu || !touch.current) return;
            pressed.current = false;
            cancelPress();
            press.current = window.setTimeout(() => { pressed.current = true; onMenu(true); }, LONG_PRESS_MS);
          }}
          onPointerUp={cancelPress} onPointerLeave={cancelPress} onPointerCancel={cancelPress}
          onClickCapture={(e) => { if (pressed.current) { e.preventDefault(); e.stopPropagation(); pressed.current = false; } }}
          // Android fires contextmenu for a long press at about the same
          // moment as the timer: take it as the long press, not the
          // browser's own menu. A mouse's right-click is left alone.
          onContextMenu={(e) => {
            if (!canMenu || !touch.current) return;
            e.preventDefault();
            cancelPress();
            pressed.current = true;
            onMenu(true);
          }}
        >
          <MessageBody m={m} kind={kind} onOpenPhoto={onOpenPhoto} />
          {m.pending === "failed" ? (
            <div className="mt-1 flex flex-wrap items-center justify-end gap-3 px-2 pb-1 text-[13px]">
              <span style={{ opacity: 0.8 }}>Not sent</span>
              <button type="button" onClick={onRetry} className="text-center font-semibold underline">Retry</button>
              <button type="button" onClick={onDiscard} className="text-center font-semibold underline">Remove</button>
            </div>
          ) : (
            <div className={`mt-1 text-right text-[13px] ${kind === CHAT_KIND_PHOTO ? "px-2" : ""}`} style={{ opacity: 0.7 }} suppressHydrationWarning>
              {m.pending === "sending" ? "Sending…" : hhmm(m.createdAt)}
            </div>
          )}
        </div>
        {menuOpen && (
          <>
            {/* Any tap outside closes it. */}
            <div className="fixed inset-0 z-40" onClick={() => onMenu(false)} />
            <div role="menu" className={`absolute top-full z-50 mt-1 min-w-[140px] overflow-hidden rounded-xl border border-zinc-200 bg-white text-[16px] text-zinc-900 shadow-xl ${mine ? "right-0" : "left-0"}`}>
              {onMessage && (
                <button type="button" role="menuitem" onClick={onMessage} disabled={messaging} className="flex w-full items-center gap-2 border-b border-zinc-200 px-4 py-2.5 text-left font-semibold hover:bg-zinc-100 disabled:opacity-60">
                  {messaging && <Loader2 className="h-4 w-4 animate-spin" />} Message {m.authorFirstName || "them"}
                </button>
              )}
              <button type="button" role="menuitem" onClick={onCopy} className="block w-full px-4 py-2.5 text-left hover:bg-zinc-100">Copy</button>
              {onReport && (
                <button type="button" role="menuitem" onClick={onReport} className="block w-full border-t border-zinc-200 px-4 py-2.5 text-left hover:bg-zinc-100">Report</button>
              )}
              {onBlock && (
                <button type="button" role="menuitem" onClick={onBlock} className="block w-full border-t border-zinc-200 px-4 py-2.5 text-left hover:bg-zinc-100">
                  Block {m.authorFirstName || "them"}
                </button>
              )}
              {onDelete && (
                <button type="button" role="menuitem" onClick={onDelete} className="block w-full border-t border-zinc-200 px-4 py-2.5 text-left font-semibold hover:bg-zinc-100" style={{ color: HC_RED }}>Delete</button>
              )}
            </div>
          </>
        )}
      </div>
      {!mine && menuButton}
    </li>
  );
}

function MessageBody({ m, kind, onOpenPhoto }: { m: Shown; kind: ChatMessageKind; onOpenPhoto: () => void }) {
  if (kind === CHAT_KIND_PHOTO) {
    const src = m.preview ?? m.text;
    const img = (
      // Whole, at its own aspect ratio: a cap on each edge, never a crop.
      // eslint-disable-next-line @next/next/no-img-element
      <img src={src} alt="Photo" loading="lazy" className="block h-auto max-h-72 w-auto max-w-full rounded-xl object-contain" />
    );
    if (m.pending) {
      return (
        <div className="relative">
          {img}
          {m.pending === "sending" && (
            <div className="absolute inset-0 flex items-center justify-center rounded-xl bg-black/30">
              <Loader2 className="h-8 w-8 animate-spin text-white" />
            </div>
          )}
        </div>
      );
    }
    return <button type="button" onClick={onOpenPhoto} aria-label="Open photo" className="block">{img}</button>;
  }
  if (kind === CHAT_KIND_LOCATION) {
    const p = parseChatLocation(m.text);
    return (
      <a href={m.text} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3">
        <MapPin className="h-8 w-8 shrink-0" />
        <span className="min-w-0">
          <span className="block font-semibold">Location</span>
          {p && <span className="block text-[14px] tabular-nums" style={{ opacity: 0.8 }}>{formatChatLocation(p)}</span>}
        </span>
      </a>
    );
  }
  return <div className="whitespace-pre-wrap break-words">{linkify(m.text)}</div>;
}

/** The app's white option sheet, as ChoicePopup draws it. */
function Sheet({ title, note, onClose, children }: { title: string; note?: string; onClose: () => void; children: React.ReactNode }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-6" onClick={onClose} role="dialog" aria-modal="true" aria-label={title}>
      <div className="w-full max-w-sm overflow-hidden rounded-2xl bg-white text-zinc-900 shadow-2xl" onClick={(e) => e.stopPropagation()}>
        <div className="border-b border-zinc-200 px-5 py-3 text-center text-[18px] font-bold">{title}</div>
        {note && <p className="px-5 pt-3 text-center text-[15px] text-zinc-600">{note}</p>}
        <div className="flex flex-col divide-y divide-zinc-200">{children}</div>
        <button type="button" onClick={onClose} className="w-full border-t border-zinc-200 px-5 py-3 text-center text-[17px] font-semibold text-zinc-600 hover:bg-zinc-100">Cancel</button>
      </div>
    </div>
  );
}

function SheetButton({ onClick, danger, disabled, children }: { onClick: () => void; danger?: boolean; disabled?: boolean; children: React.ReactNode }) {
  return (
    <button type="button" onClick={onClick} disabled={disabled} className="w-full px-5 py-3 text-center text-[18px] font-semibold hover:bg-zinc-100 disabled:opacity-50" style={danger ? { color: HC_RED } : undefined}>
      {children}
    </button>
  );
}

/**
 * Report a message (E9.F1.S17): an optional reason, capped where the SP
 * caps it, and one line that says where the report goes — the only time
 * anyone at Harrier Central sees a chat message.
 */
function ReportDialog({ reason, onReason, busy, onSend, onClose }: {
  reason: string; onReason: (s: string) => void; busy: boolean; onSend: () => void; onClose: () => void;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  const over = reason.length > CHAT_REPORT_REASON_MAX;
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-6" onClick={onClose} role="dialog" aria-modal="true" aria-label="Report this message">
      <form className="w-full max-w-sm overflow-hidden rounded-2xl bg-white text-zinc-900 shadow-2xl" onClick={(e) => e.stopPropagation()} onSubmit={(e) => { e.preventDefault(); onSend(); }}>
        <div className="border-b border-zinc-200 px-5 py-3 text-center text-[18px] font-bold">Report this message</div>
        <div className="px-5 pt-4">
          <label htmlFor="report-reason" className="block text-[15px] font-semibold">Why? <span className="font-normal text-zinc-500">(optional)</span></label>
          <textarea id="report-reason" value={reason} onChange={(e) => onReason(e.target.value)} rows={4} autoFocus disabled={busy}
            maxLength={CHAT_REPORT_REASON_MAX}
            className="mt-1.5 w-full resize-y rounded-xl border border-zinc-300 bg-zinc-50 px-3 py-2 text-[16px] text-zinc-900 focus:outline-none focus:ring-2 focus:ring-blue-700 disabled:opacity-60" />
          <div className={`mt-1 text-right text-xs tabular-nums ${over ? "font-semibold" : "text-zinc-500"}`} style={over ? { color: HC_RED } : undefined}>
            {reason.length.toLocaleString()}/{CHAT_REPORT_REASON_MAX.toLocaleString()}
          </div>
          <p className="mt-2 pb-4 text-center text-[14px] text-zinc-600">
            This sends the message to Harrier Central&apos;s reviewers. Nobody at Harrier Central reads chats otherwise.
          </p>
        </div>
        <div className="flex flex-col divide-y divide-zinc-200 border-t border-zinc-200">
          <button type="submit" disabled={busy || over} className="w-full px-5 py-3 text-center text-[18px] font-semibold hover:bg-zinc-100 disabled:opacity-50" style={{ color: HC_RED }}>
            {busy ? "Sending…" : "Report"}
          </button>
          <button type="button" onClick={onClose} disabled={busy} className="w-full px-5 py-3 text-center text-[17px] font-semibold text-zinc-600 hover:bg-zinc-100 disabled:opacity-50">Cancel</button>
        </div>
      </form>
    </div>
  );
}

/**
 * A photo the server can take as it is — or, when it is a format sharp may
 * not read (HEIC) or bigger than the 10 MB the route accepts, redrawn here
 * as a JPEG at most 2400 px on its long edge. createImageBitmap applies the
 * EXIF orientation, so the redraw comes out upright. Falls back to the
 * original when the browser cannot decode it either.
 */
async function browserReadable(file: File): Promise<Blob> {
  const easy = /^image\/(jpeg|png|webp|gif)$/.test(file.type);
  if (easy && file.size <= 8 * 1024 * 1024) return file;
  try {
    const bmp = await createImageBitmap(file);
    const scale = Math.min(1, 2400 / Math.max(bmp.width, bmp.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(bmp.width * scale);
    canvas.height = Math.round(bmp.height * scale);
    const ctx = canvas.getContext("2d");
    if (!ctx) return file;
    ctx.drawImage(bmp, 0, 0, canvas.width, canvas.height);
    bmp.close();
    return await new Promise<Blob>((resolve) => canvas.toBlob((b) => resolve(b ?? file), "image/jpeg", 0.9));
  } catch {
    return file;
  }
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
