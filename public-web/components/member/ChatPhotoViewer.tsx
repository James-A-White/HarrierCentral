"use client";

/**
 * Every photo in this chat, one at a time, opened at the one tapped
 * (E9.F1.S11). CLAUDE.md's photo rules, all three:
 *
 *  - a carousel, not a terminus: arrows, swipe, ←/→, and a strip of
 *    thumbnails to jump with;
 *  - shown whole at its own aspect ratio, thumbnails too (object-contain,
 *    one height, width by aspect — a thumbnail that does not fit the strip
 *    drops out whole rather than being cut);
 *  - on the kennel's own artwork via KennelBackground, the jungle where
 *    there is no kennel (a room), with the photo on a dark translucent pane
 *    so the backdrop reads at the edges.
 *
 * Download goes through /api/photo-download — the ONE route that re-serves
 * a blob from our origin, which is what makes `download` work cross-origin.
 *
 * Not RunPhotoCarousel: that one is a script-free page section built for
 * WhatsApp's in-app browser, driven by #fragment links. This is an overlay
 * inside an already-scripted chat, so it is driven by state instead.
 */
import { useCallback, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { ChevronLeft, ChevronRight, Download, X } from "lucide-react";
import { KennelBackground } from "@/components/kennel/KennelBackground";
import type { KennelContext } from "@/lib/types/kennel";

export interface ChatPhoto { id: string; url: string; author: string; createdAt: number }

/** Thumbnails either side of the current one; the rest are a tap on an arrow away. */
const STRIP_REACH = 4;

export function ChatPhotoViewer({ photos, start, kennel, title, onClose }: {
  photos: ChatPhoto[]; start: number; kennel: KennelContext | null; title: string; onClose: () => void;
}) {
  const last = photos.length - 1;
  const [rawIndex, setIndex] = useState(() => Math.max(0, start));
  // Clamped on every render: a photo deleted while the viewer is open
  // shortens the list under it.
  const index = Math.min(rawIndex, Math.max(0, last));
  const touchX = useRef<number | null>(null);
  const go = useCallback((d: number) => setIndex((i) => Math.min(Math.max(0, Math.min(i, last) + d), last)), [last]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
      else if (e.key === "ArrowLeft") go(-1);
      else if (e.key === "ArrowRight") go(1);
    };
    window.addEventListener("keydown", onKey);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { window.removeEventListener("keydown", onKey); document.body.style.overflow = overflow; };
  }, [go, onClose]);

  const photo = photos[index];
  if (!photo) return null;

  const downloadHref = `/api/photo-download?u=${encodeURIComponent(photo.url)}&name=${encodeURIComponent(`${title} ${index + 1}.jpg`)}`;
  const from = Math.max(0, index - STRIP_REACH), to = Math.min(photos.length, index + STRIP_REACH + 1);

  return createPortal(
    <div className="fixed inset-0 isolate z-[80] flex flex-col text-white" role="dialog" aria-modal="true" aria-label="Chat photos">
      {kennel ? <KennelBackground kennel={kennel} /> : (
        <>
          <div className="fixed inset-0 -z-10 bg-repeat" style={{ backgroundImage: "url(/images/jungle_background.jpg)", backgroundSize: "1024px 1024px" }} />
          <div className="fixed inset-0 -z-[9]" style={{ backgroundColor: "#000000", opacity: 0.55 }} />
        </>
      )}

      <div className="flex items-center justify-between gap-3 px-3 py-3">
        <span className="min-w-0 truncate text-[15px] text-white/85">{photo.author}</span>
        <span className="flex shrink-0 items-center gap-3">
          <span className="tabular-nums text-sm text-white/60">{index + 1} / {photos.length}</span>
          <button type="button" onClick={onClose} aria-label="Close"
            className="flex h-11 w-11 items-center justify-center rounded-full border border-white/25 bg-black/55 backdrop-blur-sm transition hover:bg-black/75">
            <X className="h-6 w-6" />
          </button>
        </span>
      </div>

      <div className="flex min-h-0 flex-1 items-center justify-center px-3"
        onTouchStart={(e) => { touchX.current = e.touches[0]?.clientX ?? null; }}
        onTouchEnd={(e) => {
          const x0 = touchX.current, x1 = e.changedTouches[0]?.clientX;
          touchX.current = null;
          if (x0 != null && x1 != null && Math.abs(x1 - x0) > 50) go(x1 < x0 ? 1 : -1);
        }}>
        <figure className="relative flex h-full max-h-full w-full max-w-5xl items-center justify-center rounded-2xl border border-white/15 bg-black/30 p-3 backdrop-blur-sm">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img key={photo.id} src={photo.url} alt={`Photo from ${photo.author || "the chat"}`}
            className="max-h-full max-w-full rounded-xl object-contain" />
          {index > 0 && (
            <button type="button" onClick={() => go(-1)} aria-label="Previous photo"
              className="absolute left-3 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full border border-white/25 bg-black/55 backdrop-blur-sm transition hover:bg-black/75">
              <ChevronLeft className="h-6 w-6" />
            </button>
          )}
          {index < last && (
            <button type="button" onClick={() => go(1)} aria-label="Next photo"
              className="absolute right-3 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full border border-white/25 bg-black/55 backdrop-blur-sm transition hover:bg-black/75">
              <ChevronRight className="h-6 w-6" />
            </button>
          )}
        </figure>
      </div>

      <div className="flex flex-col items-center gap-3 px-3 pb-4 pt-3">
        <a href={downloadHref} download
          className="flex items-center gap-1.5 rounded-full border border-white/25 bg-black/45 px-4 py-2 text-center text-sm text-white/90 transition hover:bg-black/70">
          <Download className="h-4 w-4" />
          Download
        </a>
        {photos.length > 1 && (
          // One height, each width by its own aspect ratio; flex-wrap inside
          // a fixed-height, overflow-hidden row drops a thumbnail that does
          // not fit whole onto a hidden line instead of cropping it.
          <ol className="flex h-14 max-w-full flex-wrap justify-center gap-2 overflow-hidden">
            {photos.slice(from, to).map((p, i) => (
              <li key={p.id} className="h-14 shrink-0">
                <button type="button" onClick={() => setIndex(from + i)} aria-label={`Photo ${from + i + 1} of ${photos.length}`}
                  className={`h-full rounded-lg ring-1 transition ${from + i === index ? "ring-2 ring-white" : "ring-white/20 hover:ring-white/60"}`}>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={p.url} alt="" loading="lazy" className="h-full w-auto rounded-lg object-contain" />
                </button>
              </li>
            ))}
          </ol>
        )}
      </div>
    </div>,
    document.body,
  );
}
