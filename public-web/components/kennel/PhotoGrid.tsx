"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Card, CardContent } from "@/components/ui/card";
import type { RunEvent } from "@/lib/api";
import type { MockKennel } from "@/lib/mock/kennel";
import { RunDetailModal } from "./RunDetailModal";

interface PhotoGridProps {
  runs: RunEvent[];
  kennel: MockKennel;
  slug: string;
}

function shortDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

export function PhotoGrid({ runs, kennel, slug }: PhotoGridProps) {
  const [selected, setSelected] = useState<RunEvent | null>(null);

  if (runs.length === 0) return null;

  return (
    <>
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

            <div className="columns-1 gap-2 sm:columns-2 lg:columns-3 [column-fill:_balance]">
              {runs.map((run, idx) => (
                <motion.button
                  key={run.PublicEventId}
                  className="relative mb-2 block w-full break-inside-avoid overflow-hidden rounded-xl group text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-white/50"
                  onClick={() => setSelected(run)}
                  initial={{ opacity: 0, y: 12 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{
                    duration: 0.45,
                    delay: idx * 0.03,
                    ease: [0.19, 1, 0.22, 1],
                  }}
                  whileHover={{ scale: 1.02 }}
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
                      <div className="absolute inset-0 bg-gradient-to-t from-black/75 via-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none" />
                      <div className="absolute bottom-0 left-0 right-0 p-2.5 translate-y-1 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-200 pointer-events-none">
                        <div className="text-base text-white">#{run.EventNumber}</div>
                        <div className="text-xl font-semibold text-white truncate leading-snug">{run.EventName}</div>
                      </div>
                    </>
                  ) : (
                    <div
                      className="p-3 flex flex-col justify-between dark:bg-white/[0.06] bg-zinc-50 dark:group-hover:bg-white/[0.10] group-hover:bg-zinc-100 transition-colors duration-200"
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
                </motion.button>
              ))}
            </div>
          </CardContent>
        </Card>
      </motion.div>

      <AnimatePresence>
        {selected && (
          <RunDetailModal
            run={selected}
            kennel={kennel}
            slug={slug}
            onClose={() => setSelected(null)}
          />
        )}
      </AnimatePresence>
    </>
  );
}
