import type { MockKennel } from "@/lib/mock/kennel";

interface KennelBackgroundProps {
  kennel: MockKennel;
}

/** Platform default background — used when a kennel has no image configured. */
const DEFAULT_BG = "/images/default-background.png";

/**
 * Blur applied to the default background tile. 0 = no blur (the tile is
 * already dark and low-contrast). Increase slightly if a softening effect
 * is ever desired (e.g. 4 for subtle, 14 for full match with kennel images).
 */
const DEFAULT_BG_BLUR_PX = 0;

/**
 * Fixed background for non-hero kennel pages (songs, about, run detail, etc.).
 *
 * When the kennel has a background image: mirrors ScrollHero's visual frozen at
 * a "comfortable reading" state — sharp base + blurred layer + colour overlay.
 *
 * When no kennel image is set: uses the platform default seamless tile
 * (DEFAULT_BG) with the same layering, so every kennel has a rich backdrop.
 */
export function KennelBackground({ kennel }: KennelBackgroundProps) {
  const usingDefault = !kennel.backgroundImageUrl;
  const imageUrl = kennel.backgroundImageUrl ?? DEFAULT_BG;
  const blurPx = usingDefault ? DEFAULT_BG_BLUR_PX : 14;
  const overlayColor = usingDefault ? "#000000" : kennel.backgroundOverlayColor;
  const overlayOpacity = usingDefault ? 0.55 : kennel.backgroundOverlayMaxOpacity;

  return (
    <>
      {/* Layer 1 — sharp base image */}
      <div
        className="fixed inset-0 -z-10 scale-[1.08] bg-repeat"
        style={{ backgroundImage: `url(${imageUrl})`, backgroundSize: kennel.backgroundImageUrl ? "cover" : "512px 512px", backgroundPosition: "center" }}
      />
      {/* Layer 2 — blurred image */}
      <div
        className="fixed inset-0 -z-10 scale-[1.08] bg-repeat"
        style={{
          backgroundImage: `url(${imageUrl})`,
          backgroundSize: kennel.backgroundImageUrl ? "cover" : "512px 512px",
          backgroundPosition: "center",
          filter: "blur(14px)",
        }}
      />
      {/* Layer 3 — colour overlay */}
      <div
        className="fixed inset-0 -z-[9]"
        style={{ backgroundColor: overlayColor, opacity: overlayOpacity }}
      />
    </>
  );
}
