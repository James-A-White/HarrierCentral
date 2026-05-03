"use client";

import React, { useState } from "react";
import Link from "next/link";
import { motion } from "framer-motion";
import { Card } from "@/components/ui/card";

interface KennelWelcomeProps {
  bannerImage: string | null;
  welcomeText: string | null;
  slug: string;
}

type Orientation = "landscape" | "portrait" | "square";

function detectOrientation(w: number, h: number): Orientation {
  if (h === 0) return "landscape";
  const ratio = w / h;
  if (ratio > 1.3) return "landscape";
  if (ratio < 0.77) return "portrait";
  return "square";
}

const CARD =
  "rounded-[2.5rem] overflow-hidden dark:border-white/25 border-zinc-200 shadow-2xl dark:shadow-black/50 dark:backdrop-blur-xl";
const CARD_STYLE = { backgroundColor: "var(--kennel-card-bg)" } as React.CSSProperties;

const ENTRANCE = {
  initial: { opacity: 0, y: 24 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: "-60px" } as const,
  transition: { duration: 0.7, ease: [0.19, 1, 0.22, 1] as [number, number, number, number] },
};

const DIVIDER = "dark:border-white/[0.1] border-zinc-200/60";
const TEXT_BODY_CLASS = "text-lg leading-relaxed";
const TEXT_BODY_STYLE = { color: "var(--kennel-text-body)" } as React.CSSProperties;
const TEXT_PADDING = "px-6 py-5 md:px-8 md:py-6";

function AboutButton({ slug }: { slug: string }) {
  return (
    <Link
      href={`/${slug}/about`}
      className="mt-4 inline-flex items-center gap-2 rounded-full px-5 py-2.5 text-base font-semibold transition-opacity hover:opacity-90"
      style={{
        backgroundColor: "var(--kennel-btn-primary, var(--kennel-primary))",
        color: "var(--kennel-primary-fg)",
      }}
    >
      About us
    </Link>
  );
}

export function KennelWelcome({ bannerImage, welcomeText, slug }: KennelWelcomeProps) {
  const [orientation, setOrientation] = useState<Orientation>("landscape");

  if (!bannerImage && !welcomeText) return null;

  const handleLoad = (e: React.SyntheticEvent<HTMLImageElement>) => {
    const img = e.currentTarget;
    setOrientation(detectOrientation(img.naturalWidth, img.naturalHeight));
  };

  // Text only
  if (!bannerImage) {
    return (
      <motion.div className="mb-6" {...ENTRANCE}>
        <Card className={CARD} style={CARD_STYLE}>
          <div className={TEXT_PADDING}>
            <p className={TEXT_BODY_CLASS} style={TEXT_BODY_STYLE}>{welcomeText}</p>
            <AboutButton slug={slug} />
          </div>
        </Card>
      </motion.div>
    );
  }

  // Image only
  if (!welcomeText) {
    return (
      <motion.div className="mb-6" {...ENTRANCE}>
        <Card className={CARD} style={CARD_STYLE}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={bannerImage} alt="" className="w-full h-auto block" onLoad={handleLoad} />
          <div className={`${TEXT_PADDING} border-t ${DIVIDER}`}>
            <AboutButton slug={slug} />
          </div>
        </Card>
      </motion.div>
    );
  }

  // Landscape: image full-width on top, text + button below
  if (orientation === "landscape") {
    return (
      <motion.div className="mb-6" {...ENTRANCE}>
        <Card className={CARD} style={CARD_STYLE}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={bannerImage} alt="" className="w-full h-auto block" onLoad={handleLoad} />
          <div className={`${TEXT_PADDING} border-t ${DIVIDER}`}>
            <p className={TEXT_BODY_CLASS} style={TEXT_BODY_STYLE}>{welcomeText}</p>
            <AboutButton slug={slug} />
          </div>
        </Card>
      </motion.div>
    );
  }

  // Portrait: image left (40%), text + button right
  if (orientation === "portrait") {
    return (
      <motion.div className="mb-6" {...ENTRANCE}>
        <Card className={CARD} style={CARD_STYLE}>
          <div className="flex flex-col sm:flex-row">
            <div className="sm:w-2/5 shrink-0 sm:max-h-[480px] overflow-hidden">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={bannerImage}
                alt=""
                className="w-full h-full object-cover block"
                onLoad={handleLoad}
              />
            </div>
            <div className={`flex-1 flex flex-col justify-center ${TEXT_PADDING} border-t ${DIVIDER} sm:border-t-0 sm:border-l`}>
              <p className={TEXT_BODY_CLASS} style={TEXT_BODY_STYLE}>{welcomeText}</p>
              <AboutButton slug={slug} />
            </div>
          </div>
        </Card>
      </motion.div>
    );
  }

  // Square: text + button left, image right (40%)
  return (
    <motion.div className="mb-6" {...ENTRANCE}>
      <Card className={CARD}>
        <div className="flex flex-col sm:flex-row">
          <div className={`flex-1 flex flex-col justify-center ${TEXT_PADDING} border-b ${DIVIDER} sm:border-b-0 sm:border-r`}>
            <p className={TEXT_BODY_CLASS} style={TEXT_BODY_STYLE}>{welcomeText}</p>
            <AboutButton slug={slug} />
          </div>
          <div className="sm:w-2/5 shrink-0 sm:max-h-[480px] overflow-hidden">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={bannerImage}
              alt=""
              className="w-full h-full object-cover block"
              onLoad={handleLoad}
            />
          </div>
        </div>
      </Card>
    </motion.div>
  );
}
