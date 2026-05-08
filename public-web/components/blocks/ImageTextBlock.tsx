"use client";

type Props = {
  imageUrl: string;
  imageAlt: string;
  heading: string;
  body: string;
  imagePosition: "left" | "right";
  imageWidth: number;
  textColor: string;
  textAlign: "left" | "center" | "right" | "justify";
  paddingLeft: number;
  paddingRight: number;
  paddingTop: number;
  paddingBottom: number;
  blockBg: string;
  hasBorder: boolean;
  borderColor: string;
  borderWidth: number;
  borderRadius: number;
};

export function ImageTextBlock({ imageUrl, imageAlt, heading, body, imagePosition, imageWidth, textColor, textAlign, paddingLeft, paddingRight, paddingTop, paddingBottom, blockBg, hasBorder, borderColor, borderWidth, borderRadius }: Props) {
  const headingColor = textColor || "var(--kennel-text-title)";
  const bodyColor    = textColor || "var(--kennel-text-body)";

  // Stacked layouts (-1 = image above text, -2 = text above image)
  const isStacked      = imageWidth < 0;
  const imageAbove     = imageWidth === -1;

  // Side-by-side visibility (0 = text only, 100 = image only)
  const showImage = imageWidth !== 0;
  const showText  = imageWidth !== 100;

  const imageEl = showImage && (
    <div
      className="w-full min-w-0"
      style={!isStacked && showText ? { flex: imageWidth } : undefined}
    >
      {imageUrl ? (
        <img
          src={imageUrl}
          alt={imageAlt || ""}
          className="w-full h-auto rounded-2xl object-cover"
        />
      ) : (
        <div
          className="w-full aspect-video rounded-2xl flex items-center justify-center text-sm"
          style={{ background: "var(--kennel-primary)", color: "var(--kennel-text-muted)" }}
        >
          No image set
        </div>
      )}
    </div>
  );

  const textEl = showText && (
    <div
      className="w-full min-w-0 flex flex-col gap-4"
      style={{
        ...((!isStacked && showImage) ? { flex: 100 - imageWidth } : {}),
        textAlign: textAlign || "left",
      }}
    >
      {heading && (
        <h2
          className="text-3xl font-black md:text-4xl"
          style={{ color: headingColor }}
        >
          {heading}
        </h2>
      )}
      {body && (
        <p
          className="text-lg leading-relaxed whitespace-pre-wrap"
          style={{ color: bodyColor }}
        >
          {body}
        </p>
      )}
    </div>
  );

  const isLeft = imagePosition !== "right";
  const rowDirection = isLeft ? "md:flex-row" : "md:flex-row-reverse";

  const borderStyle = hasBorder
    ? {
        border: `${borderWidth}px solid ${borderColor || "var(--kennel-primary)"}`,
        borderRadius: borderRadius > 0 ? `${borderRadius}px` : undefined,
        padding: "1.5rem",
      }
    : undefined;

  return (
    <div
      className="relative z-10 w-full"
      style={{
        paddingTop: `${paddingTop}px`,
        paddingBottom: `${paddingBottom}px`,
        paddingLeft: `${paddingLeft}%`,
        paddingRight: `${paddingRight}%`,
        backgroundColor: blockBg || undefined,
      }}
    >
      <div
        className={`flex gap-6 md:gap-8 items-center max-w-6xl mx-auto ${
          isStacked ? "flex-col" : `flex-col ${rowDirection}`
        }`}
        style={borderStyle}
      >
        {isStacked
          ? (imageAbove ? <>{imageEl}{textEl}</> : <>{textEl}{imageEl}</>)
          : <>{imageEl}{textEl}</>
        }
      </div>
    </div>
  );
}
