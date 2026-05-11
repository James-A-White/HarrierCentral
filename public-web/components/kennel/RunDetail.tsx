"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import { Navigation, ExternalLink, Copy, Check } from "lucide-react";

const RunDetailMap = dynamic(() => import("./RunDetailMap"), { ssr: false });

export interface RunDetailRun {
  PublicEventId: string;
  EventStartDatetime: string;
  EventStartDatetimeGmt: string | null;
  KennelIANATimezone: string | null;
  EventName: string;
  EventNumber: number;
  Hares: string | null;
  LocationOneLineDesc: string | null;
  LocationStreet: string | null;
  LocationPostCode: string | null;
  LocationCity: string | null;
  LocationRegion: string | null;
  LocationCountry: string | null;
  EventPriceForMembers: number | null;
  EventPriceForNonMembers: number | null;
  EventCurrencyType: string | null;
  EventTypeName: string | null;
  tags: string[];
  EventDescription: string | null;
  EventImage: string | null;
  EventUrl: string | null;
  Latitude: number | null;
  Longitude: number | null;
  w3wJson: string | null;
}

export interface RunDetailKennel {
  name: string;
  shortName: string;
  logoUrl?: string;
}

interface RunDetailProps {
  run: RunDetailRun;
  kennel: RunDetailKennel;
  /** Used to construct the "Copy link" URL when not at the run's own URL (e.g. embedded panel). */
  canonicalPath?: string;
  /** Extra buttons to render after the built-in action buttons (e.g. QR code button). */
  extraButtons?: React.ReactNode;
  /** Height of the embedded map in px. Defaults to 240. */
  mapHeight?: number;
}

function SectionDivider() {
  return (
    <div className="relative flex items-center justify-center py-3">
      <div className="absolute inset-x-0 top-1/2 h-px" style={{ backgroundColor: "var(--kennel-text-muted)", opacity: 0.3 }} />
      <div className="relative z-10 h-2 w-2 rounded-full" style={{ backgroundColor: "var(--kennel-text-muted)", opacity: 0.5 }} />
    </div>
  );
}

function SectionHeading({ children }: { children: React.ReactNode }) {
  return (
    <h3
      className="text-2xl font-semibold text-center mb-4"
      style={{ color: "var(--kennel-accent)" }}
    >
      {children}
    </h3>
  );
}

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex gap-4 py-1.5">
      <span className="w-28 shrink-0 text-right text-sm font-bold" style={{ color: "var(--kennel-accent)" }}>
        {label}:
      </span>
      <span className="text-sm font-bold min-w-0" style={{ color: "var(--kennel-text-body)" }}>{value}</span>
    </div>
  );
}

// Returns a timezone abbreviation for display.
// For the browser's own timezone (no explicit timeZone arg), en-GB already gives the
// correct local abbreviation (e.g. "BST"). For foreign timezones, en-GB gives "GMT+9"
// style offsets — we fall back to abbreviating the long English name instead
// ("Japan Standard Time" → "JST", "British Summer Time" → "BST").
function getTimezoneAbbr(date: Date, timeZone?: string): string {
  const locale = timeZone ? "en" : "en-GB";
  const opts: Intl.DateTimeFormatOptions = {
    timeZoneName: "short", ...(timeZone ? { timeZone } : {}),
  };
  const short = new Intl.DateTimeFormat(locale, opts)
    .formatToParts(date).find(p => p.type === "timeZoneName")?.value ?? "";

  if (/^GMT[+-]/.test(short)) {
    const long = new Intl.DateTimeFormat("en", { timeZoneName: "long", ...(timeZone ? { timeZone } : {}) })
      .formatToParts(date).find(p => p.type === "timeZoneName")?.value ?? "";
    const abbr = long.split(/\s+/).map(w => w[0]).join("");
    if (abbr) return abbr;
  }
  return short;
}

function fmtTimeWithTz(date: Date, timeZone?: string): string {
  const time = new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit", minute: "2-digit", ...(timeZone ? { timeZone } : {}),
  }).format(date);
  const abbr = getTimezoneAbbr(date, timeZone);
  return abbr ? `${time} ${abbr}` : time;
}

function fmtRunTime(run: RunDetailRun): { date: string; kennelTime: string; browserTime: string | null } {
  const gmt = run.EventStartDatetimeGmt;
  const tz  = run.KennelIANATimezone;

  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";

  const date = src.toLocaleDateString("en-GB", {
    weekday: "long", day: "numeric", month: "long",
    timeZone: displayTz,
  });

  // "en-GB" gives "GMT+9" for Asia/Tokyo; "en" gives "JST". Format time and
  // timezone abbreviation separately so we can use en-GB for 24h HH:mm ordering
  // and "en" for the abbreviation.
  const kennelTime = fmtTimeWithTz(src, displayTz);

  let browserTime: string | null = null;
  if (gmt) {
    const bt = fmtTimeWithTz(new Date(gmt));
    browserTime = bt !== kennelTime ? bt : null;
  }

  return { date, kennelTime, browserTime };
}

function formatFee(amount: number | null, currency: string | null): string {
  if (!amount || amount === 0) return "Free";
  return currency ? `${currency} ${amount.toFixed(2)}` : amount.toFixed(2);
}

function mapsUrl(lat: number | null, lon: number | null, label: string): string | null {
  if (!lat || !lon) return null;
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lon}&query_place_id=${encodeURIComponent(label)}`;
}

function parseW3w(json: string | null): string | null {
  if (!json) return null;
  try {
    const parsed = JSON.parse(json) as { map?: string; words?: string };
    return parsed.map ?? (parsed.words ? `https://what3words.com/${parsed.words}` : null);
  } catch { return null; }
}

export function RunDetail({ run, kennel, canonicalPath, extraButtons, mapHeight = 240 }: RunDetailProps) {
  const [copied, setCopied] = useState(false);
  const { date, kennelTime, browserTime } = fmtRunTime(run);
  const mapsLink = mapsUrl(run.Latitude, run.Longitude, run.LocationOneLineDesc ?? run.EventName);
  const w3wLink = parseW3w(run.w3wJson);

  function handleCopy() {
    const url = canonicalPath
      ? `${window.location.origin}${canonicalPath}`
      : window.location.href;
    navigator.clipboard.writeText(url).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  const actionBtnClass =
    "inline-flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-semibold transition-opacity hover:opacity-85";

  const hasLocation = !!(
    run.LocationOneLineDesc ||
    run.LocationStreet ||
    run.LocationPostCode ||
    run.LocationCity ||
    run.LocationRegion ||
    run.LocationCountry
  );

  const hasFees = run.EventPriceForMembers !== null || run.EventPriceForNonMembers !== null;

  const hasActions = !!(mapsLink || w3wLink || run.EventUrl || extraButtons);

  return (
    <div>
      {/* Header — kennel logo + run title */}
      <div className="flex items-center gap-4 pt-1 pb-5">
        {kennel.logoUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={kennel.logoUrl}
            alt={kennel.name}
            className="h-20 w-20 shrink-0 object-contain"
          />
        )}
        <div className="min-w-0">
          <h2 className="text-xl font-bold leading-snug" style={{ color: "var(--kennel-text-title)" }}>
            {run.EventName}
          </h2>
          <p className="text-sm mt-1" style={{ color: "var(--kennel-text-muted)" }}>
            {kennel.shortName} · Run #{run.EventNumber}
          </p>
        </div>
      </div>

      <SectionDivider />

      {/* Event details */}
      <div className="mb-2">
        <SectionHeading>Event details</SectionHeading>
        <Row label="Kennel" value={kennel.name} />
        <Row label="Run" value={`#${run.EventNumber}`} />
        <Row label="Date" value={<span suppressHydrationWarning>{date}</span>} />
        <Row
          label="Time"
          value={
            <span suppressHydrationWarning>
              {kennelTime}
              {browserTime && (
                <span className="block text-sm font-normal mt-0.5">
                  {browserTime} your time
                </span>
              )}
            </span>
          }
        />
        {run.Hares && <Row label="Hares" value={run.Hares} />}
        {run.EventTypeName && <Row label="Run type" value={run.EventTypeName} />}
        {hasFees && (
          <Row
            label="Run fees"
            value={
              <span>
                {run.EventPriceForMembers !== null && (
                  <span className="block">
                    {formatFee(run.EventPriceForMembers, run.EventCurrencyType)} (members)
                  </span>
                )}
                {run.EventPriceForNonMembers !== null && (
                  <span className="block">
                    {formatFee(run.EventPriceForNonMembers, run.EventCurrencyType)} (non-members)
                  </span>
                )}
              </span>
            }
          />
        )}
      </div>

      {/* Location section */}
      {hasLocation && (
        <>
          <SectionDivider />
          <div className="mb-2">
            <SectionHeading>Location</SectionHeading>
            {run.LocationOneLineDesc && <Row label="Place" value={run.LocationOneLineDesc} />}
            {run.LocationStreet && <Row label="Street" value={run.LocationStreet} />}
            {run.LocationPostCode && <Row label="Post code" value={run.LocationPostCode} />}
            {run.LocationCity && <Row label="City" value={run.LocationCity} />}
            {run.LocationRegion && <Row label="Region" value={run.LocationRegion} />}
            {run.LocationCountry && <Row label="Country" value={run.LocationCountry} />}
            {run.Latitude && run.Longitude && (
              <div className="mt-4 rounded-xl overflow-hidden" style={{ height: mapHeight }}>
                <RunDetailMap lat={run.Latitude} lon={run.Longitude} />
              </div>
            )}
          </div>
        </>
      )}

      {/* Action buttons */}
      {(hasActions || true) && (
        <>
          <SectionDivider />
          <div className="flex flex-wrap justify-center gap-2 pb-2">
            {mapsLink && (
              <a
                href={mapsLink}
                target="_blank"
                rel="noopener noreferrer"
                className={actionBtnClass}
                style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
              >
                <Navigation className="h-4 w-4" />
                Open in Maps
              </a>
            )}
            <button
              onClick={handleCopy}
              className={actionBtnClass}
              style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
            >
              {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
              {copied ? "Copied!" : "Copy link"}
            </button>
            {w3wLink && (
              <a
                href={w3wLink}
                target="_blank"
                rel="noopener noreferrer"
                className={actionBtnClass}
                style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
              >
                /// What3Words
              </a>
            )}
            {run.EventUrl && (
              <a
                href={run.EventUrl}
                target="_blank"
                rel="noopener noreferrer"
                className={actionBtnClass}
                style={{ backgroundColor: "var(--kennel-primary)", color: "var(--kennel-primary-fg)" }}
              >
                <ExternalLink className="h-4 w-4" />
                Event page
              </a>
            )}
            {extraButtons}
          </div>
        </>
      )}

      {/* Event tags */}
      {run.tags.length > 0 && (
        <>
          <SectionDivider />
          <div className="mb-2">
            <SectionHeading>Event tags</SectionHeading>
            <div className="flex flex-wrap justify-center gap-1.5">
              {run.tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex rounded-full border px-3 py-1 text-xs font-semibold"
                  style={{ color: "var(--kennel-accent)", borderColor: "var(--kennel-accent)", opacity: 0.8 }}
                >
                  {tag}
                </span>
              ))}
            </div>
          </div>
        </>
      )}

      {/* Description */}
      {run.EventDescription && (
        <>
          <SectionDivider />
          <div className="pb-2">
            <SectionHeading>About this run</SectionHeading>
            <p className="text-sm leading-6 whitespace-pre-wrap" style={{ color: "var(--kennel-text-body)" }}>
              {run.EventDescription}
            </p>
          </div>
        </>
      )}
    </div>
  );
}
