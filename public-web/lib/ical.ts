/**
 * iCalendar (RFC 5545) for a kennel's runs feed, `/<slug>/runs.ics`
 * (E3.F6.S8). A subscribed calendar app re-reads the whole file every
 * hour or so; each run keeps its UID, so an edited run updates in place and
 * a deleted one disappears on the next read.
 *
 * Server only. Times are written in UTC from EventStartDatetimeGmt (the true
 * instant, /hc-event-datetimes): the raw EventStartDatetime often carries a
 * spurious +00:00, so it is never turned into an instant here.
 */
import type { FeedRun } from "@/lib/api";

const CRLF = "\r\n";
const DEFAULT_DURATION_MS = 3 * 60 * 60 * 1000; // a run with no end: gather + 3 h
const MAX_DESCRIPTION = 2000;

export interface FeedKennel {
  name: string;
  shortName: string;
  timeZone: string | null;
  /** Where run pages live: https://www.hashruns.org/<slug> or the custom domain. */
  baseUrl: string;
}

/** TEXT value escaping (RFC 5545 3.3.11). */
function escapeText(s: string): string {
  return s
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r\n|\r|\n/g, "\\n");
}

/** Lines longer than 75 octets are folded: CRLF + one space (RFC 5545 3.1). */
function fold(line: string): string {
  const enc = new TextEncoder();
  if (enc.encode(line).length <= 75) return line;
  const parts: string[] = [];
  let cur = "";
  let curBytes = 0;
  for (const ch of line) {
    const b = enc.encode(ch).length;
    // The first line may hold 75 octets; continuations 74 after the space.
    if (curBytes + b > (parts.length === 0 ? 75 : 74)) {
      parts.push(cur);
      cur = "";
      curBytes = 0;
    }
    cur += ch;
    curBytes += b;
  }
  parts.push(cur);
  return parts.join(CRLF + " ");
}

/** 2026-10-17T20:00:00Z → 20261017T200000Z */
function utcStamp(d: Date): string {
  return d.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
}

/** Wall-clock string with no offset, read as UTC so two of them subtract to a duration. */
function wallClockMs(s: string | null): number | null {
  if (!s) return null;
  const t = Date.parse(s.replace(/([+-]\d{2}:\d{2}|Z)$/, "") + "Z");
  return Number.isNaN(t) ? null : t;
}

function plainText(s: string): string {
  return s
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function localTime(d: Date, timeZone: string | null): string {
  try {
    return new Intl.DateTimeFormat("en-GB", {
      hour: "2-digit",
      minute: "2-digit",
      timeZone: timeZone ?? "UTC",
    }).format(d);
  } catch {
    return "";
  }
}

/** The run's page; `from=cal` marks arrivals from a calendar (E3.F6.S9 counts them). */
export function runUrl(kennel: FeedKennel, run: FeedRun): string {
  return `${kennel.baseUrl}/${run.EventNumber}?from=cal`;
}

function summary(kennel: FeedKennel, run: FeedRun): string {
  const head = run.EventNumber ? `${kennel.shortName} #${run.EventNumber}` : kennel.shortName;
  const name = (run.EventName ?? "").trim();
  // Imported runs are often named "Run 1683": the number is already in the head.
  if (!name || /^run\s*#?\s*\d+$/i.test(name)) return head;
  return `${head}: ${name}`;
}

function location(run: FeedRun): string | null {
  const one = run.LocationOneLineDesc?.trim();
  if (one) return one;
  const parts = [run.LocationStreet, run.LocationCity, run.LocationPostCode, run.LocationCountry]
    .map((p) => p?.trim())
    .filter(Boolean);
  return parts.length ? parts.join(", ") : null;
}

function vevent(kennel: FeedKennel, run: FeedRun, stamp: string, note?: string): string[] | null {
  if (!run.EventStartDatetimeGmt) return null;
  const start = new Date(run.EventStartDatetimeGmt);
  if (Number.isNaN(start.getTime())) return null;

  // EventEndDatetime is wall clock like EventStartDatetime: their difference is
  // the length of the run whatever the offsets say.
  const s = wallClockMs(run.EventStartLocal);
  const e = wallClockMs(run.EventEndLocal);
  const span = s !== null && e !== null && e > s && e - s <= 24 * 60 * 60 * 1000 ? e - s : DEFAULT_DURATION_MS;
  const end = new Date(start.getTime() + span);

  const url = runUrl(kennel, run);
  const lines: string[] = [];
  // The link first, so it is the one thing every calendar app shows.
  lines.push(url);
  const gather = localTime(start, kennel.timeZone);
  if (gather) {
    const packOff = run.PackOffMinutes ? new Date(start.getTime() + run.PackOffMinutes * 60_000) : null;
    lines.push(packOff ? `Gather ${gather} · pack off ${localTime(packOff, kennel.timeZone)}` : `Gather ${gather}`);
  }
  if (run.Hares?.trim()) lines.push(`Hares: ${run.Hares.trim()}`);
  if (run.EventDescription?.trim()) {
    lines.push("");
    let text = plainText(run.EventDescription);
    if (text.length > MAX_DESCRIPTION) text = text.slice(0, MAX_DESCRIPTION).trimEnd() + "…";
    lines.push(text);
  }
  if (note) lines.push("", note);

  const out = [
    "BEGIN:VEVENT",
    `UID:${run.PublicEventId.toLowerCase()}@hashruns.org`,
    `DTSTAMP:${stamp}`,
    ...(run.UpdatedAt && !Number.isNaN(Date.parse(run.UpdatedAt)) ? [`LAST-MODIFIED:${utcStamp(new Date(run.UpdatedAt))}`] : []),
    `DTSTART:${utcStamp(start)}`,
    `DTEND:${utcStamp(end)}`,
    `SUMMARY:${escapeText(summary(kennel, run))}`,
    `DESCRIPTION:${escapeText(lines.join("\n"))}`,
    `URL:${url}`,
  ];
  const loc = location(run);
  if (loc) out.push(`LOCATION:${escapeText(loc)}`);
  const lat = Number(run.Latitude);
  const lon = Number(run.Longitude);
  if (run.Latitude != null && run.Longitude != null && Math.abs(lat) <= 90 && Math.abs(lon) <= 180 && !(lat === 0 && lon === 0)) {
    out.push(`GEO:${lat.toFixed(6)};${lon.toFixed(6)}`);
  }
  out.push("END:VEVENT");
  return out;
}

/**
 * The whole calendar. `stamp` is the DTSTAMP every event carries; pass a value
 * that only changes with the data (the latest UpdatedAt, not "now"), so an
 * unchanged feed has an unchanged body and its ETag lets a calendar app skip
 * the download.
 */
export function buildCalendar(kennel: FeedKennel, runs: FeedRun[], stamp: Date): string {
  const st = utcStamp(stamp);
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Harrier Central//hashruns.org runs feed//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${escapeText(`${kennel.name} runs`)}`,
    `X-WR-CALDESC:${escapeText(`Runs of ${kennel.name}, from Harrier Central — ${kennel.baseUrl}`)}`,
    ...(kennel.timeZone ? [`X-WR-TIMEZONE:${kennel.timeZone}`] : []),
    // Ask for an hourly re-read. Apple and Outlook honour it; Google decides for itself.
    "REFRESH-INTERVAL;VALUE=DURATION:PT1H",
    "X-PUBLISHED-TTL:PT1H",
  ];
  for (const run of runs) {
    const ev = vevent(kennel, run, st);
    if (ev) lines.push(...ev);
  }
  lines.push("END:VCALENDAR");
  return lines.map(fold).join(CRLF) + CRLF;
}

/**
 * ONE run as a calendar file, for "This run only" on a run page (James,
 * 2026-10-17, as the app). It is a snapshot: the description says so and
 * gives the kennel's feed for updates. Same event builder as the feed, so the
 * entry reads the same; no refresh interval, as nothing re-reads it.
 */
export function buildSingleRun(kennel: FeedKennel, run: FeedRun, stamp: Date, feedUrl: string): string | null {
  const ev = vevent(kennel, run, utcStamp(stamp),
    `Added once from hashruns.org: later changes to this run will not update here. ` +
    `For updates, subscribe to ${kennel.shortName}'s calendar: ${feedUrl}`);
  if (!ev) return null;
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Harrier Central//hashruns.org single run//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    ...ev,
    "END:VCALENDAR",
  ];
  return lines.map(fold).join(CRLF) + CRLF;
}
