"use client";

/**
 * Adventure-movie style title (solid orange fill, thick dark outline, drop
 * shadow) whose baseline follows a curved arc — the letters sweep along a
 * banner-style curve rather than a straight line, matching the "Welcome to
 * Harrier Central 2.0" promo artwork. Rendered as inline SVG so the stroke
 * sits *behind* the fill (paint-order), it scales crisply at any size, and it
 * reads the same in light and dark themes.
 *
 * Note: the promo artwork uses a bespoke serif adventure font (made in
 * Logoist). We don't have that font file in the web project, so this uses a
 * heavy web-safe stack — same treatment, close but not pixel-identical. Drop a
 * webfont into `public`/`lib` and swap `FONT_STACK` to match exactly.
 */

const FONT_STACK =
  '"Arial Black", "Arial Narrow", "Helvetica Neue", Impact, sans-serif';

// Solid fill matching the 2.0 artwork's orange (no metallic gradient).
const FILL = "#f5941d";
const OUTLINE = "#2b1a02";

// Curved baseline the letters ride along: rises from the low left, arcs up
// over the middle, and eases down to the right — a dynamic banner sweep.
const CURVE = "M 20 140 Q 410 46 800 96";

interface AdventureTitleProps {
  /** Single line of title text, laid along the curve. */
  text?: string;
  className?: string;
}

export function AdventureTitle({
  text = "HARRIER CENTRAL 3.0",
  className,
}: AdventureTitleProps) {
  return (
    <svg
      viewBox="0 0 820 170"
      overflow="visible"
      className={className}
      style={{ width: "100%", height: "auto", display: "block" }}
      aria-label={text}
      role="img"
    >
      <defs>
        <path id="hc-title-curve" d={CURVE} fill="none" />
        <filter id="hc-title-shadow" x="-15%" y="-25%" width="130%" height="160%">
          <feDropShadow
            dx="0"
            dy="3"
            stdDeviation="2.5"
            floodColor="#000"
            floodOpacity="0.55"
          />
        </filter>
      </defs>

      <g filter="url(#hc-title-shadow)">
        <text
          fontFamily={FONT_STACK}
          fontStyle="italic"
          fontWeight={900}
          fontSize={56}
          letterSpacing="-1"
          fill={FILL}
          stroke={OUTLINE}
          strokeWidth={6}
          paintOrder="stroke"
          strokeLinejoin="round"
        >
          <textPath href="#hc-title-curve" startOffset="50%" textAnchor="middle">
            {text}
          </textPath>
        </text>
      </g>
    </svg>
  );
}
