"use client";

/**
 * A kennel's social and chat links (E12.F4.S4): a row of brand icons, each a
 * link out. WeChat has no group links, so a WeChat entry without a url opens
 * a small dialog with the WeChat ID and the QR image instead.
 *
 * Two looks:
 *   - "icons" — round icon buttons, for the footer and the nav menu.
 *   - "chips" — icon + name pills, for the signed-in kennel page, where a
 *               members-only entry carries a small "members" tag.
 * Both wrap, so a long list never scrolls sideways on a phone. Colours come
 * from currentColor, so the caller's text colour (the kennel's nav text, the
 * footer's muted text) themes them.
 *
 * Brand marks: simple-icons (pinned exact in package.json), named imports so
 * only these paths ship. Mailing list and "other" have no brand: lucide.
 */
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { Check, Copy, Link as LinkIcon, Mail, X } from "lucide-react";
import {
  siBluesky, siDiscord, siFacebook, siGooglecalendar, siInstagram, siKakaotalk, siLine, siMeetup, siReddit,
  siSignal, siStrava, siTelegram, siThreads, siTiktok, siViber, siWechat, siWhatsapp, siX,
  siYoutube, siZalo,
} from "simple-icons";
import { socialLinkTitle, type SocialLink, type SocialPlatform } from "@/lib/social-links";

const BRAND: Partial<Record<SocialPlatform, { path: string }>> = {
  facebook: siFacebook, instagram: siInstagram, whatsapp: siWhatsapp, signal: siSignal,
  telegram: siTelegram, wechat: siWechat, line: siLine, kakaotalk: siKakaotalk, zalo: siZalo,
  viber: siViber, discord: siDiscord, strava: siStrava, meetup: siMeetup, x: siX, tiktok: siTiktok,
  youtube: siYoutube, threads: siThreads, bluesky: siBluesky, reddit: siReddit,
  googlecalendar: siGooglecalendar,
};

export function SocialIcon({ platform, className }: { platform: SocialPlatform; className?: string }) {
  const brand = BRAND[platform];
  if (brand) {
    return (
      <svg viewBox="0 0 24 24" className={className} fill="currentColor" aria-hidden="true" focusable="false">
        <path d={brand.path} />
      </svg>
    );
  }
  return platform === "mailinglist"
    ? <Mail className={className} aria-hidden="true" />
    : <LinkIcon className={className} aria-hidden="true" />;
}

export function SocialLinksRow({ links, variant = "icons", className = "" }: {
  links: SocialLink[];
  variant?: "icons" | "chips";
  className?: string;
}) {
  const [wechat, setWechat] = useState<SocialLink | null>(null);
  if (links.length === 0) return null;

  return (
    <>
      <ul className={`flex min-w-0 flex-wrap items-center gap-2 ${variant === "chips" ? "justify-center" : ""} ${className}`}>
        {links.map((link, i) => {
          const title = socialLinkTitle(link);
          const members = link.audience === "members";
          const label = members ? `${title} (members only)` : title;
          const look = variant === "icons"
            ? "flex h-10 w-10 items-center justify-center rounded-full border border-current/25 transition-opacity opacity-80 hover:opacity-100"
            : "flex min-w-0 max-w-full items-center gap-2 rounded-full border border-white/30 bg-black/30 px-3 py-2 text-[16px] font-semibold text-white transition-opacity hover:opacity-90";
          const body = variant === "icons"
            ? <SocialIcon platform={link.platform} className="h-5 w-5" />
            : (
              <>
                <SocialIcon platform={link.platform} className="h-5 w-5 shrink-0" />
                <span className="min-w-0 truncate">{title}</span>
                {members && (
                  <span className="shrink-0 rounded-full bg-white/15 px-1.5 py-0.5 text-[11px] font-medium uppercase tracking-wide text-white/80">
                    members
                  </span>
                )}
              </>
            );
          return (
            <li key={`${link.platform}-${i}`} className="min-w-0 max-w-full">
              {link.url && !opensDialog(link) ? (
                <a href={link.url} target="_blank" rel="noopener noreferrer" aria-label={label} title={label} className={look}>
                  {body}
                </a>
              ) : (
                <button type="button" onClick={() => setWechat(link)} aria-label={label} title={label} className={look}>
                  {body}
                </button>
              )}
            </li>
          );
        })}
      </ul>
      {/* Portalled to <body>: the row sits inside the sticky nav, whose
          backdrop-filter would otherwise trap a fixed dialog inside the bar. */}
      {wechat && createPortal(<WeChatDialog link={wechat} onClose={() => setWechat(null)} />, document.body)}
    </>
  );
}

/** A WeChat entry with an ID or a QR image opens the dialog (which still offers its url, if any). */
function opensDialog(link: SocialLink): boolean {
  return link.platform === "wechat" && (!!link.handle || !!link.qrImageUrl || !link.url);
}

/** The WeChat ID (with a copy button) and the QR image, shown whole. */
function WeChatDialog({ link, onClose }: { link: SocialLink; onClose: () => void }) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  async function copy() {
    if (!link.handle) return;
    try {
      await navigator.clipboard.writeText(link.handle);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard refused (insecure context, permissions): the ID is selectable text anyway.
    }
  }

  const title = socialLinkTitle(link);
  return (
    <div data-social-dialog className="fixed inset-0 z-[70] flex items-center justify-center bg-black/60 p-4" onClick={onClose} role="dialog" aria-modal="true" aria-label={title}>
      <div
        className="relative flex max-h-[90vh] w-full max-w-sm flex-col items-center gap-3 overflow-y-auto rounded-2xl bg-white p-5 text-zinc-900 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <button type="button" onClick={onClose} aria-label="Close" className="absolute right-3 top-3 rounded-md p-1 text-zinc-500 hover:bg-zinc-100">
          <X className="h-5 w-5" />
        </button>
        <div className="flex items-center gap-2 pr-6 text-lg font-bold">
          <SocialIcon platform="wechat" className="h-6 w-6 shrink-0" />
          <span className="min-w-0 break-words">{link.label ? `${link.label} (WeChat)` : "WeChat"}</span>
        </div>
        {link.handle && (
          <div className="flex w-full min-w-0 items-center justify-center gap-2">
            <span className="text-sm text-zinc-500">WeChat ID:</span>
            <span className="min-w-0 select-all break-all font-mono text-base font-semibold">{link.handle}</span>
            <button type="button" onClick={copy} aria-label="Copy WeChat ID" title="Copy"
              className="shrink-0 rounded-md p-1 text-zinc-600 hover:bg-zinc-100">
              {copied ? <Check className="h-4 w-4 text-green-600" /> : <Copy className="h-4 w-4" />}
            </button>
          </div>
        )}
        {link.qrImageUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={link.qrImageUrl} alt={`${title} QR code`} className="h-auto max-h-[60vh] w-full object-contain" />
        )}
        {link.url && (
          <a href={link.url} target="_blank" rel="noopener noreferrer" className="text-sm font-semibold text-green-700 underline underline-offset-2">
            Open in WeChat
          </a>
        )}
        <p className="text-center text-xs text-zinc-500">Scan the code or search for the ID in WeChat.</p>
      </div>
    </div>
  );
}
