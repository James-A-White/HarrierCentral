export type KennelTheme = "light" | "dark";

export interface MockKennel {
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
