import type { Data } from "@measured/puck";

export type PageStatus = "draft" | "url-only" | "menu";

export interface PageConfig {
  id: string;
  name: string;
  slug: string;       // "" for home, "runs" for /[slug]/runs, "my-page" for custom
  isDefault: boolean;
  status: PageStatus;
  order: number;
  layout: Data | null;
}

export interface SiteConfig {
  version: 1;
  pages: PageConfig[];
}

const DEFAULT_LAYOUTS: Record<string, Data> = {
  home: {
    root: { props: {} },
    content: [
      { type: "NextRunBlock",  props: { id: "next-run" } },
      { type: "RunListBlock",  props: { id: "future-runs", isFuture: true,  count: 9  } },
      { type: "RunListBlock",  props: { id: "past-runs",   isFuture: false, count: 12 } },
    ],
  },
  runs: {
    root: { props: {} },
    content: [{ type: "RunsPageBlock", props: { id: "runs-page" } }],
  },
  about: {
    root: { props: {} },
    content: [],
  },
  events: {
    root: { props: {} },
    content: [{ type: "EventsListBlock", props: { id: "events" } }],
  },
  songs: {
    root: { props: {} },
    content: [{ type: "SongsListBlock", props: { id: "songs" } }],
  },
  stats: {
    root: { props: {} },
    content: [{ type: "StatsListBlock", props: { id: "stats" } }],
  },
};

const INITIAL_DEFAULT_PAGES: Omit<PageConfig, "status" | "order" | "layout">[] = [
  { id: "home",   name: "Home",   slug: "",       isDefault: true },
  { id: "runs",   name: "Runs",   slug: "runs",   isDefault: true },
  { id: "about",  name: "About",  slug: "about",  isDefault: true },
  { id: "events", name: "Events", slug: "events", isDefault: true },
  { id: "songs",  name: "Songs",  slug: "songs",  isDefault: true },
  { id: "stats",  name: "Stats",  slug: "stats",  isDefault: true },
];

export function createDefaultSiteConfig(): SiteConfig {
  return {
    version: 1,
    pages: INITIAL_DEFAULT_PAGES.map((def, i) => ({
      ...def,
      status: "menu",
      order: i,
      layout: DEFAULT_LAYOUTS[def.id] ?? null,
    })),
  };
}

export function parseSiteConfig(json: string | null | undefined): SiteConfig {
  if (!json) return createDefaultSiteConfig();
  try {
    const parsed = JSON.parse(json);
    if (parsed.version === 1 && Array.isArray(parsed.pages)) {
      return parsed as SiteConfig;
    }
    return createDefaultSiteConfig();
  } catch {
    return createDefaultSiteConfig();
  }
}

export function getDefaultLayout(pageId: string): Data {
  return DEFAULT_LAYOUTS[pageId] ?? { root: { props: {} }, content: [] };
}

export function deriveNavItems(
  siteConfigOrJson: SiteConfig | string | null | undefined,
  slug: string
): { label: string; href: string }[] {
  const config = typeof siteConfigOrJson === "string" || siteConfigOrJson == null
    ? parseSiteConfig(siteConfigOrJson)
    : siteConfigOrJson;
  return [...config.pages]
    .filter(p => p.status === "menu")
    .sort((a, b) => a.order - b.order)
    .map(p => ({
      label: p.name,
      href: `/${slug}${p.slug ? `/${p.slug}` : ""}`,
    }));
}
