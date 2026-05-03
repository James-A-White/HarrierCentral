"use client";

import { useEffect, useRef, useState } from "react";
import { motion, useInView } from "framer-motion";
import { Trophy, Users, Camera, Hash } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import type { KennelContext } from "@/lib/types/kennel";

function useCountUp(target: number, duration = 1800, active: boolean) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (!active) return;
    let start = 0;
    const step = target / (duration / 16);
    const timer = setInterval(() => {
      start += step;
      if (start >= target) {
        setCount(target);
        clearInterval(timer);
      } else {
        setCount(Math.floor(start));
      }
    }, 16);
    return () => clearInterval(timer);
  }, [target, duration, active]);
  return count;
}

function StatRow({
  icon: Icon,
  label,
  value,
  suffix = "",
  active,
}: {
  icon: React.ElementType;
  label: string;
  value: number;
  suffix?: string;
  active: boolean;
}) {
  const count = useCountUp(value, 1600, active);
  const display = count >= 1000 ? `${(count / 1000).toFixed(1)}k` : count.toString();

  return (
    <div className="flex items-center justify-between rounded-2xl border dark:border-white/[0.08] dark:bg-black/[0.15] border-zinc-100 bg-zinc-50 px-4 py-4">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl dark:border-white/[0.08] dark:bg-white/[0.08] border border-zinc-200 bg-white">
          <Icon className="h-5 w-5" style={{ color: "var(--kennel-text-muted)" }} />
        </div>
        <span className="text-2xl font-medium" style={{ color: "var(--kennel-text-body)" }}>{label}</span>
      </div>
      <div className="text-3xl font-bold tabular-nums" style={{ color: "var(--kennel-text-body)" }}>
        {display}{suffix}
      </div>
    </div>
  );
}

export function StatsSection({ kennel }: { kennel: KennelContext }) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.7, ease: [0.19, 1, 0.22, 1] }}
    >
      <Card className="rounded-[2rem] dark:border-white/10 border-zinc-200 shadow-xl dark:shadow-black/30 dark:backdrop-blur-xl" style={{ backgroundColor: "var(--kennel-card-bg)" }}>
        <CardContent className="p-6 md:p-7">
          <div className="mb-5">
            <div className="text-xl uppercase tracking-[0.15em] mb-1" style={{ color: "var(--kennel-text-muted)" }}>
              By the numbers
            </div>
            <h2 className="text-3xl font-bold" style={{ color: "var(--kennel-text-title)" }}>
              {kennel.name}
            </h2>
            <p className="text-2xl mt-1" style={{ color: "var(--kennel-text-body)" }}>
              Est. {kennel.foundedYear} · {kennel.city}
            </p>
          </div>

          <div className="space-y-3">
            <StatRow icon={Hash} label="Total runs" value={kennel.stats.totalRuns} active={inView} />
            <StatRow icon={Users} label="Active members" value={kennel.stats.activeMembers} active={inView} />
            <StatRow icon={Camera} label="Photos uploaded" value={kennel.stats.photosUploaded} active={inView} />
            <StatRow icon={Trophy} label="Years running" value={kennel.stats.yearsRunning} suffix="yrs" active={inView} />
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
