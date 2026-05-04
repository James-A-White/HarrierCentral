import type { KennelLandingData } from "./api";
import type { KennelContext } from "./types/kennel";

/**
 * Normalises a DB colour value to 8-digit hex (#RRGGBBAA).
 * - 8-digit hex: returned as-is
 * - 6-digit hex: appended with FF (fully opaque)
 * - null / invalid: returns the provided fallback
 */
export function hexColor(raw: string | null | undefined, fallback: string): string {
  if (!raw) return fallback;
  if (/^#[0-9A-Fa-f]{8}$/.test(raw)) return raw;
  if (/^#[0-9A-Fa-f]{6}$/.test(raw)) return `${raw}FF`;
  return fallback;
}

export function parseOverlayColor(raw: string | null): {
  backgroundOverlayColor: string;
  backgroundOverlayMaxOpacity: number;
} {
  if (raw && /^#[0-9A-Fa-f]{8}$/.test(raw)) {
    const maxOpacity = parseInt(raw.slice(7, 9), 16) / 255;
    return { backgroundOverlayColor: `#${raw.slice(1, 7)}`, backgroundOverlayMaxOpacity: maxOpacity };
  }
  return {
    backgroundOverlayColor: raw && /^#[0-9A-Fa-f]{6}$/.test(raw) ? raw : "#000000",
    backgroundOverlayMaxOpacity: 0.88,
  };
}

export function clampScrollBlur(raw: number | null): number {
  return Math.min(100, Math.max(0, raw ?? 0));
}

export function parseMenuBackground(raw: string | null, theme: "dark" | "light"): {
  menuBackgroundColor: string;
  menuBackgroundOpacity: number;
} {
  const s = raw?.trim() ?? "";
  if (/^#[0-9A-Fa-f]{8}$/.test(s)) {
    const maxOpacity = parseInt(s.slice(7, 9), 16) / 255;
    return { menuBackgroundColor: `#${s.slice(1, 7)}`, menuBackgroundOpacity: maxOpacity };
  }
  if (/^#[0-9A-Fa-f]{6}$/.test(s)) {
    return { menuBackgroundColor: s, menuBackgroundOpacity: 1.0 };
  }
  return theme === "dark"
    ? { menuBackgroundColor: "#09090b", menuBackgroundOpacity: 0.8 }
    : { menuBackgroundColor: "#ffffff", menuBackgroundOpacity: 0.8 };
}

export function toKennelContext(data: KennelLandingData): KennelContext {
  const hasCustomBackground = data.WebsiteBackgroundImage?.startsWith("https://") ?? false;
  const theme = data.ThemeMode === "light" ? "light" : "dark";

  return {
    slug: data.KennelUniqueShortName,
    name: data.KennelName,
    shortName: data.KennelShortName,
    tagline: data.Tagline ?? "",
    city: "",
    foundedYear: 0,
    primaryColor: data.PrimaryColor ?? "#dc2626",
    primaryFg: "#ffffff",
    accentColor: data.AccentColor ?? "#eab308",
    textTitleColor: hexColor(data.TitleTextColor, "#FFFFFFFF"),
    textBodyColor:  hexColor(data.BodyTextColor,  "#FFFFFFFF"),
    textMutedColor: hexColor(data.TextMutedColor, "#FFFFFF80"),
    cardBackgroundColor: hexColor(data.CardBackgroundColor, theme === "dark" ? "#FFFFFF0A" : "#FFFFFFFF"),
    buttonPrimaryColor: data.ButtonPrimaryColor ? hexColor(data.ButtonPrimaryColor, "") : undefined,
    buttonCancelColor: data.ButtonCancelColor ? hexColor(data.ButtonCancelColor, "") : undefined,
    buttonSecondaryColor: data.ButtonSecondaryColor ? hexColor(data.ButtonSecondaryColor, "") : undefined,
    runCardBackgroundColor: data.RunCardColor ? hexColor(data.RunCardColor, "") : undefined,
    theme,
    titleText: data.WebsiteTitleText ?? undefined,
    titleTextColor: data.TitleTextColor ?? undefined,
    logoLetter: data.KennelShortName.charAt(0).toUpperCase(),
    logoUrl: data.KennelLogo?.startsWith("https://") ? data.KennelLogo : undefined,
    heroImageUrl: data.BannerImage?.startsWith("https://") ? data.BannerImage : undefined,
    backgroundImageUrl: hasCustomBackground
      ? data.WebsiteBackgroundImage!
      : "/images/jungle_background.jpg",
    ...parseOverlayColor(data.WebsiteBackgroundColor ?? "#00000080"),
    scrollBlur: clampScrollBlur(hasCustomBackground ? (data.ScrollBlur ?? 0) : (data.ScrollBlur || 5)),
    ...parseMenuBackground(data.MenuBackgroundColor ?? null, theme),
    menuTextColor: data.MenuTextColor ?? (theme === "light" ? "#18181b" : "#ffffff"),
    socialLinks: {},
    stats: { totalRuns: 0, activeMembers: 0, photosUploaded: 0, yearsRunning: 0 },
  };
}
