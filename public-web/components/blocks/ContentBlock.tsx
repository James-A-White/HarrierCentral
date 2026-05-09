"use client";

import { ICON_MAP } from "@/components/puck/icons";
import type { PaddingValue } from "@/components/puck/PaddingCrossField";

type Props = {
  imageUrl: string;
  imageAlt: string;
  heading: string;
  headingColor: string;
  headingAlign: "left" | "center" | "right";
  body: string;
  bodyColor: string;
  bodyAlign: "left" | "center" | "right" | "justify";
  imagePosition: "left" | "right";
  imageWidth: number;
  padding: PaddingValue;
  imagePadding: PaddingValue;
  textPadding: PaddingValue;
  textGap: number;
  blockBg: string;
  hasBorder: boolean;
  borderColor: string;
  borderWidth: number;
  borderRadius: number;
  buttonPosition: string;
  buttonHref: string;
  buttonText: string;
  buttonTextColor: string;
  buttonTextAlign: "left" | "center" | "right";
  buttonColor: string;
  buttonIcon: string;
  buttonIconPosition: "before" | "after" | "only";
  buttonPadding: PaddingValue;
};

export function ContentBlock({ imageUrl, imageAlt, heading, headingColor, headingAlign, body, bodyColor, bodyAlign, imagePosition, imageWidth, padding, imagePadding, textPadding, textGap, blockBg, hasBorder, borderColor, borderWidth, borderRadius, buttonPosition, buttonHref, buttonText, buttonTextColor, buttonTextAlign, buttonColor, buttonIcon, buttonIconPosition, buttonPadding }: Props) {
  const resolvedHeadingColor = headingColor || "var(--kennel-text-title)";
  const resolvedBodyColor    = bodyColor    || "var(--kennel-text-body)";

  // Stacked layouts (-1 = image above text, -2 = text above image)
  const isStacked  = imageWidth < 0;
  const imageAbove = imageWidth === -1;

  // Side-by-side visibility (0 = text only, 100 = image only)
  const showImage = imageWidth !== 0;
  const showText  = imageWidth !== 100;

  const imageEl = showImage && (
    <div
      className="w-full min-w-0"
      style={{
        ...(!isStacked && showText ? { flex: imageWidth } : {}),
        paddingTop:    `${imagePadding?.top    ?? 0}px`,
        paddingBottom: `${imagePadding?.bottom ?? 0}px`,
        paddingLeft:   `${imagePadding?.left   ?? 0}px`,
        paddingRight:  `${imagePadding?.right  ?? 0}px`,
      }}
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
      className="w-full min-w-0 flex flex-col"
      style={{
        ...( (!isStacked && showImage) ? { flex: 100 - imageWidth } : {} ),
        paddingTop:    `${textPadding?.top    ?? 0}px`,
        paddingBottom: `${textPadding?.bottom ?? 0}px`,
        paddingLeft:   `${textPadding?.left   ?? 0}px`,
        paddingRight:  `${textPadding?.right  ?? 0}px`,
      }}
    >
      {heading && (
        <h2
          className="text-3xl font-black md:text-4xl"
          style={{ color: resolvedHeadingColor, textAlign: headingAlign || "left" }}
        >
          {heading}
        </h2>
      )}
      {body && (
        <p
          className="text-lg leading-relaxed whitespace-pre-wrap"
          style={{ color: resolvedBodyColor, textAlign: bodyAlign || "left", marginTop: `${textGap ?? 16}px` }}
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

  const ButtonIcon = buttonIcon ? ICON_MAP[buttonIcon] : null;
  const showButton = !!buttonPosition && (buttonIconPosition === "only" ? !!buttonIcon : !!buttonText);

  const buttonHAlign =
    buttonPosition.includes("right")  ? "flex-end"  :
    buttonPosition.includes("center") ? "center"    : "flex-start";

  const buttonEl = showButton && (
    <div style={{
      display: "flex",
      justifyContent: buttonHAlign,
      paddingTop:    `${buttonPadding?.top    ?? 0}px`,
      paddingBottom: `${buttonPadding?.bottom ?? 0}px`,
      paddingLeft:   `${buttonPadding?.left   ?? 0}px`,
      paddingRight:  `${buttonPadding?.right  ?? 0}px`,
    }}>
      <a
        href={buttonHref || "#"}
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: "8px",
          padding: "12px 24px",
          borderRadius: "8px",
          backgroundColor: buttonColor || "var(--kennel-primary)",
          color: buttonTextColor || "var(--kennel-primary-fg)",
          textDecoration: "none",
          fontWeight: 600,
          fontSize: "1rem",
          justifyContent: buttonTextAlign === "right" ? "flex-end" : buttonTextAlign === "center" ? "center" : "flex-start",
        }}
      >
        {buttonIconPosition !== "after"  && ButtonIcon && <ButtonIcon size={18} />}
        {buttonIconPosition !== "only"   && buttonText && <span>{buttonText}</span>}
        {buttonIconPosition === "after"  && ButtonIcon && <ButtonIcon size={18} />}
      </a>
    </div>
  );

  const isButtonTop = buttonPosition.startsWith("top");

  return (
    <div
      className="relative z-10 w-full"
      style={{
        paddingTop: `${padding?.top ?? 0}px`,
        paddingBottom: `${padding?.bottom ?? 0}px`,
        paddingLeft: `${padding?.left ?? 0}%`,
        paddingRight: `${padding?.right ?? 0}%`,
        backgroundColor: blockBg || undefined,
      }}
    >
      <div className="flex flex-col gap-4 max-w-6xl mx-auto">
        {isButtonTop && buttonEl}
        <div
          className={`flex items-center ${
            isStacked ? "flex-col" : `flex-col ${rowDirection}`
          }`}
          style={borderStyle}
        >
          {isStacked
            ? (imageAbove ? <>{imageEl}{textEl}</> : <>{textEl}{imageEl}</>)
            : <>{imageEl}{textEl}</>
          }
        </div>
        {!isButtonTop && buttonEl}
      </div>
    </div>
  );
}
