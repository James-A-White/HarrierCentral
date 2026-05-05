import type { Config } from "@measured/puck";
import { WelcomeBlock } from "@/components/blocks/WelcomeBlock";
import { NextRunBlock } from "@/components/blocks/NextRunBlock";
import { RunListBlock } from "@/components/blocks/RunListBlock";
import { RunsPageBlock } from "@/components/blocks/RunsPageBlock";
import { AboutBlock } from "@/components/blocks/AboutBlock";
import { EventsListBlock } from "@/components/blocks/EventsListBlock";
import { SongsListBlock } from "@/components/blocks/SongsListBlock";
import { StatsListBlock } from "@/components/blocks/StatsListBlock";

type BlockProps = {
  WelcomeBlock: Record<string, never>;
  NextRunBlock: Record<string, never>;
  RunListBlock: { isFuture: boolean; count: number };
  RunsPageBlock: Record<string, never>;
  AboutBlock: Record<string, never>;
  EventsListBlock: Record<string, never>;
  SongsListBlock: Record<string, never>;
  StatsListBlock: Record<string, never>;
};

export const puckConfig: Config<BlockProps> = {
  components: {
    WelcomeBlock: {
      label: "Welcome",
      fields: {},
      defaultProps: {},
      render: () => <WelcomeBlock />,
    },
    NextRunBlock: {
      label: "Next Run",
      fields: {},
      defaultProps: {},
      render: () => <NextRunBlock />,
    },
    RunListBlock: {
      label: "Run List",
      fields: {
        isFuture: {
          type: "radio",
          label: "Which runs",
          options: [
            { label: "Upcoming", value: true },
            { label: "Past",     value: false },
          ],
        },
        count: {
          type: "number",
          label: "How many to show",
          min: 1,
          max: 20,
        },
      },
      defaultProps: { isFuture: true, count: 9 },
      render: ({ isFuture, count }) => <RunListBlock isFuture={isFuture} count={count} />,
    },
    RunsPageBlock: {
      label: "Runs Page",
      fields: {},
      defaultProps: {},
      render: () => <RunsPageBlock />,
    },
    AboutBlock: {
      label: "About",
      fields: {},
      defaultProps: {},
      render: () => <AboutBlock />,
    },
    EventsListBlock: {
      label: "Events List",
      fields: {},
      defaultProps: {},
      render: () => <EventsListBlock />,
    },
    SongsListBlock: {
      label: "Songs List",
      fields: {},
      defaultProps: {},
      render: () => <SongsListBlock />,
    },
    StatsListBlock: {
      label: "Stats List",
      fields: {},
      defaultProps: {},
      render: () => <StatsListBlock />,
    },
  },
};
