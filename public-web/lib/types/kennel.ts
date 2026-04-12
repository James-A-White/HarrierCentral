export type KennelTheme = "light" | "dark";

export interface KennelContext {
  slug: string;
  name: string;
  shortName: string;
  tagline: string;
  city: string;
  foundedYear: number;
  primaryColor: string;
  primaryFg: string;
  accentColor: string;
  theme: KennelTheme;
  logoLetter: string;
  titleText?: string;            // KennelWebsite.TitleText — custom display name shown below logo
  titleTextColor?: string;       // KennelWebsite.TitleTextColor — CSS color; falls back to white/black per theme
  logoUrl?: string;              // https:// URL only — bundle:// refs are excluded
  backgroundImageUrl?: string;   // https:// URL only — WebsiteBackgroundImage field
  backgroundOverlayColor: string;      // CSS #RRGGBB hex color for scroll overlay
  backgroundOverlayMaxOpacity: number; // 0–1, max opacity reached at full scroll
  scrollBlur: number;                  // KennelWebsite.ScrollBlur — 0 = no blur, 100 = full blur (120px)
  menuBackgroundColor: string;         // CSS #RRGGBB hex color for sticky nav background
  menuBackgroundOpacity: number;       // 0–1, opacity of nav background at full scroll
  menuTextColor: string;               // CSS color string for sticky nav text (hex or any valid CSS color)
  socialLinks: {
    facebook?: string;
    instagram?: string;
    strava?: string;
    meetup?: string;
  };
  stats: {
    totalRuns: number;
    activeMembers: number;
    photosUploaded: number;
    yearsRunning: number;
  };
}
