"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { MapPin, Clock, Users, ChevronRight } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";

interface FeaturedRunCardProps {
  run: RunEvent;
  href: string;
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

export function FeaturedRunCard({ run, href }: FeaturedRunCardProps) {
  const { longDate, time } = formatDatetime(run);
  const heroUrl = run.EventImage ?? null;

  return (
    <motion.div
      className="min-w-0 w-full max-w-full"
      initial={{ opacity: 0, y: 32 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.7, ease: [0.19, 1, 0.22, 1] }}
    >
      <Card className="w-full max-w-full overflow-hidden rounded-[2.5rem] gap-0 py-0 dark:border-white/25 border-zinc-200 shadow-2xl dark:shadow-black/60 dark:backdrop-blur-2xl" style={{ backgroundColor: "var(--kennel-run-card-bg, var(--kennel-card-bg))" }}>

        {/* Header bar — primary colour strip with title + run number */}
        <div
          className="flex min-w-0 items-center justify-between gap-3 px-5 py-3"
          style={{ backgroundColor: "var(--kennel-primary)" }}
        >
          <h2 className="min-w-0 text-2xl font-bold text-white leading-snug line-clamp-2">
            {run.EventName}
          </h2>
          <span
            className="shrink-0 rounded-full px-3 py-1 text-xl font-bold"
            style={{
              backgroundColor: "var(--kennel-accent, var(--kennel-primary))",
              color: "var(--kennel-primary-fg)",
            }}
          >
            #{run.EventNumber}
          </span>
        </div>

        {/* Image — only rendered when one exists */}
        {heroUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={heroUrl} alt={run.EventName} className="w-full h-auto block" />
        )}

        <CardContent className="p-5 md:p-6">
          {/* Detail rows */}
          <div className="space-y-2.5 mb-5">
            <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }} suppressHydrationWarning>
              <Clock className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
              <span className="min-w-0 truncate">{longDate} · {time}</span>
            </div>
            {run.LocationCity && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <MapPin className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.LocationCity}</span>
              </div>
            )}
            {run.LocationOneLineDesc && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <MapPin className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.LocationOneLineDesc}</span>
              </div>
            )}
            {run.Hares && (
              <div className="flex items-center gap-2.5 text-2xl" style={{ color: "var(--kennel-text-body)" }}>
                <Users className="h-4 w-4 shrink-0" style={{ color: "var(--kennel-accent, var(--kennel-primary))" }} />
                <span className="min-w-0 truncate">{run.Hares}</span>
              </div>
            )}
          </div>

          {/* Description */}
          {run.EventDescription && (
            <p className="text-2xl leading-9 mb-5 line-clamp-3 break-words" style={{ color: "var(--kennel-text-body)" }}>
              {run.EventDescription}
            </p>
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
