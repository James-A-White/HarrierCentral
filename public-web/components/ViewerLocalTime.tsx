"use client";

import { useEffect, useState } from "react";

// "10:45 your time" companion for a run start shown in kennel time, rendered
// only when the viewer's clock differs from the kennel's wall-clock. The run
// detail page has carried this (its `browserTime`) since launch; this shared
// version brings the same treatment to the run cards and lists.
//
// Computed in useEffect on purpose: these cards are server-rendered by ISR,
// where the viewer's timezone is unknowable — rendering nothing until mount
// avoids a hydration mismatch. Kennel-local viewers (the normal case) never
// see it at all.
export default function ViewerLocalTime({
  gmt,
  kennelTz,
  className,
}: {
  gmt: string | null | undefined;
  kennelTz: string | null | undefined;
  className?: string;
}) {
  const [label, setLabel] = useState<string | null>(null);

  useEffect(() => {
    if (!gmt || !kennelTz) return;
    const d = new Date(gmt);
    if (isNaN(d.getTime())) return;

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
    if (wall() === wall(kennelTz)) return;

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
    setLabel(`${prefix}${day}${time} your time`);
  }, [gmt, kennelTz]);

  if (!label) return null;
  return <span className={className}>{label}</span>;
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
