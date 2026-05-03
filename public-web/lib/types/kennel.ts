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
  // Style tokens — all 8-digit hex (#RRGGBBAA); opacity encoded in the value
  textTitleColor: string;        // heading / event-name text; default #FFFFFFFF
  textBodyColor: string;         // body / row-value text; default #FFFFFFFF
  textMutedColor: string;        // label / secondary text; default #FFFFFF80
  cardBackgroundColor: string;   // card / panel surface; default #FFFFFF0A
  theme: KennelTheme;
  logoLetter: string;
  titleText?: string;            // KennelWebsite.TitleText — custom display name shown below logo
  titleTextColor?: string;       // KennelWebsite.TitleTextColor — CSS color for hero title text
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
