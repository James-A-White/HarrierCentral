"use client";

import dynamic from "next/dynamic";
import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock, Users, ChevronRight } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";
import ViewerLocalTime from "@/components/ViewerLocalTime";

const FeaturedRunMap = dynamic(() => import("./FeaturedRunMap"), { ssr: false });

export interface FeaturedDisplayOptions {
  showRunNumber: boolean;
  showRunName: boolean;
  showDate: boolean;
  showTime: boolean;
  showLocation: boolean;
  showHares: boolean;
  showDescription: boolean;
  showTags: boolean;
  showMap: boolean;
  showImage: boolean;
}

const DEFAULT_DISPLAY: FeaturedDisplayOptions = {
  showRunNumber:  true,
  showRunName:    true,
  showDate:       true,
  showTime:       true,
  showLocation:   true,
  showHares:      true,
  showDescription: true,
  showTags:       false,
  showMap:        false,
  showImage:      true,
};

interface FeaturedRunCardProps {
  run: RunEvent;
  href: string;
  display?: Partial<FeaturedDisplayOptions>;
}

function formatDatetime(run: RunEvent): { longDate: string; time: string } {
  const gmt = run.EventStartDatetimeGmt;
  const tz  = run.KennelIANATimezone;
  const src = gmt && tz ? new Date(gmt) : new Date(run.EventStartDatetime);
  const displayTz = gmt && tz ? tz : "UTC";
  return {
    longDate: src.toLocaleDateString("en-GB", {
      weekday: "long", day: "numeric", month: "long", year: "numeric",
      timeZone: displayTz,
    }),
    time: src.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: displayTz }),
  };
}

export function FeaturedRunCard({ run, href, display: displayProp }: FeaturedRunCardProps) {
  const d = { ...DEFAULT_DISPLAY, ...displayProp };
  const { longDate, time } = formatDatetime(run);

  const showHeader = d.showRunName || d.showRunNumber;
  const showDatetimeRow = d.showDate || d.showTime;
  const datetimeParts: string[] = [];
  if (d.showDate) datetimeParts.push(longDate);
  if (d.showTime) datetimeParts.push(time);

  return (
    <motion.div
      className="min-w-0 w-full max-w-full"
      initial={{ opacity: 0, y: 32 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.7, ease: [0.19, 1, 0.22, 1] }}
    >
      <Card
        className="w-full max-w-full overflow-hidden rounded-[2.5rem] gap-0 py-0 dark:border-white/25 border-zinc-200 shadow-2xl dark:shadow-black/60 dark:backdrop-blur-2xl"
        style={{ backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))" }}
      >
        {/* Primary colour header */}
        {showHeader && (
          <div
            className="flex min-w-0 items-center justify-between gap-3 px-5 py-3"
            style={{ backgroundColor: "var(--kennel-primary)" }}
          >
            {d.showRunName && (
              <h2 className="min-w-0 text-2xl font-bold text-white leading-snug line-clamp-2">
                {run.EventName}
              </h2>
            )}
            {d.showRunNumber && (
              <span
                className="shrink-0 rounded-full px-3 py-1 text-xl font-bold"
                style={{
                  backgroundColor: "var(--kennel-accent, var(--kennel-primary))",
                  color: "var(--kennel-primary-fg)",
                }}
              >
                #{run.EventNumber}
              </span>
            )}
          </div>
        )}

        {/* Hero image */}
        {d.showImage && run.EventImage && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={run.EventImage} alt={run.EventName} className="w-full h-auto block" />
        )}

        <CardContent className="p-5 md:p-6">
          <div className="space-y-2.5 mb-5">
            {showDatetimeRow && (
              <div
                className="flex items-center gap-2.5 text-2xl"
                style={{ color: "var(--kennel-text-body)" }}
                suppressHydrationWarning
              >
                <Clock className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{datetimeParts.join(" · ")}</span>
                <ViewerLocalTime
                  gmt={run.EventStartDatetimeGmt}
                  kennelTz={run.KennelIANATimezone}
                  className="shrink-0 text-sm italic opacity-70"
                />
              </div>
            )}

            {d.showLocation && run.LocationCity && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <MapPin className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.LocationCity}</span>
              </div>
            )}
            {d.showLocation && run.LocationOneLineDesc && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <MapPin className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.LocationOneLineDesc}</span>
              </div>
            )}

            {d.showHares && run.Hares && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <Users className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.Hares}</span>
              </div>
            )}
          </div>

          {/* Tags */}
          {d.showTags && run.tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-5">
              {run.tags.map((tag) => (
                <span
                  key={tag}
                  className="rounded-full px-3 py-1 text-sm font-medium border dark:border-white/20 border-zinc-200"
                  style={{ color: "var(--kennel-text-body)" }}
                >
                  {tag}
                </span>
              ))}
            </div>
          )}

          {/* Description */}
          {d.showDescription && run.EventDescription && (
            <p
              className="text-2xl leading-9 mb-5 line-clamp-3 break-words"
              style={{ color: "var(--kennel-text-body)" }}
            >
              {run.EventDescription}
            </p>
          )}

          {/* Map */}
          {d.showMap && (
            <div className="rounded-2xl overflow-hidden mb-5" style={{ height: "280px" }}>
              <FeaturedRunMap run={run} />
            </div>
          )}

          {/* CTA */}
          <Link
            href={href}
            className="flex w-full min-w-0 items-center justify-center gap-1 rounded-full px-4 py-2.5 text-center text-xl font-semibold whitespace-normal transition-opacity hover:opacity-90 sm:text-2xl"
            style={{
              backgroundColor: "var(--kennel-btn-primary, var(--kennel-primary))",
              color: "var(--kennel-primary-fg)",
            }}
          >
            Full run details &amp; directions
            <ChevronRight className="ml-1 h-4 w-4" />
          </Link>
        </CardContent>
      </Card>
    </motion.div>
  );
}
