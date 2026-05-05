import type { Data } from "@measured/puck";

export type PageType = "home" | "runs" | "about" | "events" | "songs" | "stats";
export type PageLayoutBlob = Partial<Record<PageType, Data>>;

export const PAGE_TYPES: readonly PageType[] = ["home", "runs", "about", "events", "songs", "stats"];

export const PAGE_LABELS: Record<PageType, string> = {
  home:   "Home",
  runs:   "Runs",
  about:  "About",
  events: "Events",
  songs:  "Songs",
  stats:  "Stats",
};

export const defaultLayouts: Record<PageType, Data> = {
  home: {
    root: { props: {} },
    content: [
      { type: "WelcomeBlock",  props: { id: "welcome" } },
      { type: "NextRunBlock",  props: { id: "next-run" } },
      { type: "RunListBlock",  props: { id: "future-runs", isFuture: true,  count: 9 } },
      { type: "RunListBlock",  props: { id: "past-runs",   isFuture: false, count: 12 } },
    ],
  },
  runs: {
    root: { props: {} },
    content: [
      { type: "RunsPageBlock", props: { id: "runs-page" } },
    ],
  },
  about: {
    root: { props: {} },
    content: [
      { type: "AboutBlock", props: { id: "about" } },
    ],
  },
  events: {
    root: { props: {} },
    content: [
      { type: "EventsListBlock", props: { id: "events" } },
    ],
  },
  songs: {
    root: { props: {} },
    content: [
      { type: "SongsListBlock", props: { id: "songs" } },
    ],
  },
  stats: {
    root: { props: {} },
    content: [
      { type: "StatsListBlock", props: { id: "stats" } },
    ],
  },
};
