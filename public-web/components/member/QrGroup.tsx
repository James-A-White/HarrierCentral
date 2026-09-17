"use client";

/**
 * The app's QrGroup (qr_group.dart): a title, then a row of the info
 * button, the copy icon, the QR code on white, the share icon and the
 * open-in-browser icon. Used by the kennel page's "Show <kennel> Links".
 */
import { useState } from "react";
import QRCode from "react-qr-code";
import { Copy, Share2, ExternalLink } from "lucide-react";

export function QrGroup({ title, description, url, helpTitle, helpText }: {
  title: string; description: string; url: string; helpTitle: string; helpText: string;
}) {
  const [toast, setToast] = useState<string | null>(null);
  const [help, setHelp] = useState(false);

  function say(msg: string) { setToast(msg); window.setTimeout(() => setToast(null), 2500); }

  async function copy() {
    try { await navigator.clipboard.writeText(url); say(`A link to ${description} has been copied to your clipboard`); }
    catch { say("Couldn't copy the link"); }
  }

  async function share() {
    if (navigator.share) { try { await navigator.share({ text: url, url }); } catch { /* cancelled */ } }
    else await copy();
  }

  return (
    <div className="flex flex-col items-center gap-3 py-4">
      <h3 className="text-center text-[24px] font-semibold text-white">{title}</h3>
      <div className="flex items-center gap-4">
        <button type="button" onClick={() => setHelp(true)} aria-label="What is this link?">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/images/icons/info_button.png" alt="" className="h-9 w-9" />
        </button>
        <button type="button" onClick={copy} aria-label="Copy link" className="text-white"><Copy className="h-9 w-9" /></button>
        <a href={url} target="_blank" rel="noopener noreferrer" className="rounded-md bg-white p-2" aria-label={description}>
          <QRCode value={url} size={140} />
        </a>
        <button type="button" onClick={share} aria-label="Share link" className="text-white"><Share2 className="h-9 w-9" /></button>
        <a href={url} target="_blank" rel="noopener noreferrer" aria-label="Open link" className="text-white"><ExternalLink className="h-9 w-9" /></a>
      </div>
      <div className="max-w-full truncate text-center text-[15px] text-white/80">{url}</div>

      {toast && <div className="fixed bottom-24 left-1/2 z-[70] -translate-x-1/2 rounded-full bg-black/80 px-4 py-2 text-center text-[15px] text-white shadow-lg">{toast}</div>}
      {help && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 p-6" onClick={() => setHelp(false)}>
          <div className="w-full max-w-sm rounded-2xl bg-white p-5 text-zinc-900 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h4 className="mb-2 text-[20px] font-bold">{helpTitle}</h4>
            <p className="whitespace-pre-line text-[17px]">{helpText.replace(/\r\n/g, "\n")}</p>
            <button type="button" onClick={() => setHelp(false)} className="mt-4 w-full rounded-full py-2 text-[17px] font-semibold text-white" style={{ backgroundColor: "#B71C1C" }}>OK</button>
          </div>
        </div>
      )}
    </div>
  );
}
