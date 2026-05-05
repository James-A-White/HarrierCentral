"use client";

import { useKennelData } from "@/components/puck/KennelDataContext";
import { KennelWelcome } from "@/components/kennel/KennelWelcome";

export function WelcomeBlock() {
  const { kennelData, slug } = useKennelData();
  return (
    <KennelWelcome
      bannerImage={kennelData.OgImageUrl}
      welcomeText={kennelData.WelcomeText}
      slug={slug}
    />
  );
}
