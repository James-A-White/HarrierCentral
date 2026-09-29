"use client";

import { useSyncExternalStore } from "react";

// "10:45 your time" companion for a run start shown in kennel time, rendered
// only when the viewer's clock differs from the kennel's wall-clock. The run
// detail page has carried this (its `browserTime`) since launch; this shared
// version brings the same treatment to the run cards and lists.
//
// Read through useSyncExternalStore on purpose: these cards are server-rendered
// by ISR, where the viewer's timezone is unknowable. The server snapshot is
// null, so the server HTML and the hydration pass both render nothing and the
// label appears only once React is on the viewer's clock — no hydration
// mismatch. Kennel-local viewers (the normal case) never see it at all.
export default function ViewerLocalTime({
  gmt,
  kennelTz,
  className,
}: {
  gmt: string | null | undefined;
  kennelTz: string | null | undefined;
  className?: string;
}) {
  const label = useSyncExternalStore(
    subscribeNever,
    () => viewerLabel(gmt, kennelTz),
    () => null,
  );

  if (!label) return null;
  return <span className={className}>{label}</span>;
}

// The viewer's timezone never changes for the life of the page, so there is
// nothing to subscribe to; the store exists only to split server from client.
function subscribeNever() {
  return () => {};
}

function viewerLabel(
  gmt: string | null | undefined,
  kennelTz: string | null | undefined,
): string | null {
  if (!gmt || !kennelTz) return null;
  const d = new Date(gmt);
  if (isNaN(d.getTime())) return null;

  const wall = (tz?: string) =>
    new Intl.DateTimeFormat("en-GB", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      ...(tz ? { timeZone: tz } : {}),
    }).format(d);

  // Same wall-clock to the minute — viewer is effectively on kennel time.
  if (wall() === wall(kennelTz)) return null;

  const sameDate =
    d.toLocaleDateString("en-CA") ===
    d.toLocaleDateString("en-CA", { timeZone: kennelTz });
  const time = new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(d);
  // Cross-date conversions carry the weekday ("Sat 04:45 your time") so a
  // Tokyo evening run viewed from the US can't be misread as the same day.
  const day = sameDate
    ? ""
    : d.toLocaleDateString("en-GB", { weekday: "short" }) + " ";
  // Label the kennel time with its zone too ("JST · ...") — same
  // abbreviation technique as RunDetail: Intl short name, falling back to
  // the long name's initials when Intl only offers "GMT+9".
  const abbr = kennelAbbr(d, kennelTz);
  const prefix = abbr ? `${abbr} · ` : "";
  return `${prefix}${day}${time} your time`;
}

function kennelAbbr(date: Date, timeZone: string): string {
  const short =
    new Intl.DateTimeFormat("en", { timeZoneName: "short", timeZone })
      .formatToParts(date)
      .find((p) => p.type === "timeZoneName")?.value ?? "";
  if (/^GMT[+-]/.test(short)) {
    const long =
      new Intl.DateTimeFormat("en", { timeZoneName: "long", timeZone })
        .formatToParts(date)
        .find((p) => p.type === "timeZoneName")?.value ?? "";
    const abbr = long
      .split(/\s+/)
      .map((w) => w[0])
      .join("");
    if (abbr) return abbr;
  }
  return short;
}
