"use client";

interface BrowserLocalTimeProps {
  gmtIso: string;
  kennelFormatted: string;
  className?: string;
}

/**
 * Renders the run start time converted to the viewer's browser timezone.
 * Renders nothing when the browser time matches the kennel-local time
 * (i.e. the viewer is already in the kennel's timezone).
 */
export function BrowserLocalTime({ gmtIso, kennelFormatted, className }: BrowserLocalTimeProps) {
  const browserFormatted = new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  }).format(new Date(gmtIso));

  if (browserFormatted === kennelFormatted) return null;

  return (
    <span className={className}>
      {browserFormatted} your time
    </span>
  );
}
