import type { MockKennel } from "@/lib/mock/kennel";

interface KennelBackgroundProps {
  kennel: MockKennel;
}

/**
 * Fixed background for non-hero kennel pages (songs, about, run detail, etc.).
 *
 * Mirrors ScrollHero's visual but frozen at a "comfortable reading" state:
 *   - Sharp base image (like landing page at scroll=0)
 *   - Blurred layer at 70% opacity on top (partial blur)
 *   - Colour overlay at 50% of the kennel's configured max opacity
 *     so the image stays clearly visible — not the 0.88 wall of black
 *     you'd see on the fully-scrolled landing page.
 *
 * Falls back to the same gradient as ScrollHero when no image is set.
 */
export function KennelBackground({ kennel }: KennelBackgroundProps) {
  if (kennel.backgroundImageUrl) {
    return (
      <>
        {/* Layer 1 — sharp base image, always visible */}
        <div
          className="fixed inset-0 -z-10 scale-[1.08] bg-cover bg-center bg-no-repeat"
          style={{ backgroundImage: `url(${kennel.backgroundImageUrl})` }}
        />
        {/* Layer 2 — blurred image at full opacity (matches fully-scrolled landing page) */}
        <div
          className="fixed inset-0 -z-10 scale-[1.08] bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage: `url(${kennel.backgroundImageUrl})`,
            filter: "blur(14px)",
          }}
        />
        {/* Layer 3 — colour overlay at full configured opacity */}
        <div
          className="fixed inset-0 -z-[9]"
          style={{
            backgroundColor: kennel.backgroundOverlayColor,
            opacity: kennel.backgroundOverlayMaxOpacity,
          }}
        />
      </>
    );
  }

  return (
    <div className="fixed inset-0 -z-10">
      <div
        className="absolute inset-0 hidden dark:block"
        style={{
          background: `
            radial-gradient(circle at 50% 0%, color-mix(in srgb, var(--kennel-primary) 18%, transparent) 0%, transparent 55%),
            linear-gradient(180deg, rgba(255,255,255,0.04) 0%, transparent 40%),
            linear-gradient(135deg, #1c1917 0%, #18181b 35%, #09090b 100%)
          `,
        }}
      />
      <div
        className="absolute inset-0 block dark:hidden"
        style={{
          background: `
            radial-gradient(circle at 50% 0%, color-mix(in srgb, var(--kennel-primary) 8%, transparent) 0%, transparent 55%),
            linear-gradient(135deg, #fafafa 0%, #f4f4f5 100%)
          `,
        }}
      />
    </div>
  );
}
