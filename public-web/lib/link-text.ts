/** Splits text into plain runs and https links — the app's Linkify, for the kennel description. */
export interface TextRun { text: string; url?: string }
const URL_RE = /https?:\/\/[^\s<>"]+/gi;
const TRAIL = ".,;:!?)]}'\"";
export function splitLinks(text: string): TextRun[] {
  const runs: TextRun[] = [];
  let last = 0;
  for (const m of text.matchAll(URL_RE)) {
    let raw = m[0]; let end = m.index! + raw.length;
    while (raw.length && TRAIL.includes(raw[raw.length - 1])) { raw = raw.slice(0, -1); end--; }
    if (m.index! > last) runs.push({ text: text.slice(last, m.index!) });
    runs.push({ text: raw, url: raw });
    last = end;
  }
  if (last < text.length) runs.push({ text: text.slice(last) });
  return runs;
}
