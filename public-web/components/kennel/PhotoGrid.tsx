"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";
import type { KennelContext } from "@/lib/types/kennel";

interface PhotoGridProps {
  runs: RunEvent[];
  kennel: KennelContext;
  slug: string;
}

function shortDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

function shortTime(iso: string) {
  return new Date(iso).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
}

export function PhotoGrid({ runs, kennel: _kennel, slug }: PhotoGridProps) {
  if (runs.length === 0) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.7, ease: [0.19, 1, 0.22, 1] }}
    >
      <Card className="rounded-[2.5rem] gap-0 py-0 dark:border-white/25 dark:bg-white/[0.12] border-zinc-200 bg-white shadow-2xl dark:shadow-black/50 dark:backdrop-blur-xl">
        <CardContent className="p-5 md:p-6">
          <div className="mb-5 flex items-center justify-between">
            <div>
              <div className="text-xl uppercase tracking-[0.15em] dark:text-white text-zinc-900 mb-1">
                Past runs
              </div>
              <h2 className="text-2xl font-bold dark:text-white text-zinc-900">Recent runs</h2>
            </div>
            <span className="text-xl font-medium dark:text-white text-zinc-900">
              {runs.length} {runs.length === 1 ? "run" : "runs"}
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
            {runs.map((run, idx) => (
              <motion.div
                key={run.PublicEventId}
                initial={{ opacity: 0, y: 12 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.45, delay: idx * 0.03, ease: [0.19, 1, 0.22, 1] }}
              >
                <Link
                  href={`/${slug}/${run.EventNumber}?back=${encodeURIComponent(`/${slug}`)}`}
                  className="block w-full overflow-hidden rounded-xl text-left border dark:border-white/[0.1] border-zinc-200/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
                >
                  {run.EventImage ? (
                    <>
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={run.EventImage}
                        alt={run.EventName}
                        className="w-full h-auto block"
                        loading="lazy"
                      />
                      <div className="px-2.5 py-1.5 dark:bg-white/[0.07] bg-zinc-100 border-t dark:border-white/[0.08] border-zinc-200/60">
                        <p className="text-sm font-semibold dark:text-white text-zinc-900 truncate leading-snug">
                          {run.EventName}
                          {run.IsCountedRun ? (
                            <span className="ml-1.5 font-normal dark:text-white/50 text-zinc-500">#{run.EventNumber}</span>
                          ) : null}
                        </p>
                        <p className="text-xs dark:text-white/50 text-zinc-500 truncate mt-0.5" suppressHydrationWarning>
                          {shortDate(run.EventStartDatetime)} · {shortTime(run.EventStartDatetime)}
                        </p>
                      </div>
                    </>
                  ) : (
                    <div
                      className="p-3 flex flex-col justify-between dark:bg-white/[0.06] bg-zinc-50"
                      style={{ minHeight: "80px" }}
                    >
                      <span className="text-base font-semibold dark:text-white text-zinc-900">
                        #{run.EventNumber}
                      </span>
                      <div>
                        <div className="text-xl font-bold dark:text-white text-zinc-900 line-clamp-2 leading-snug">
                          {run.EventName}
                        </div>
                        <div className="text-base dark:text-white text-zinc-900 mt-1" suppressHydrationWarning>
                          {shortDate(run.EventStartDatetime)}
                        </div>
                      </div>
                    </div>
                  )}
                </Link>
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
