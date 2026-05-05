import type { Config } from "@measured/puck";
import { WelcomeBlock } from "@/components/blocks/WelcomeBlock";
import { NextRunBlock } from "@/components/blocks/NextRunBlock";
import { RunListBlock } from "@/components/blocks/RunListBlock";

// Block prop types
type WelcomeBlockProps = Record<string, never>;
type NextRunBlockProps = Record<string, never>;
type RunListBlockProps = { isFuture: boolean; count: number };

type BlockProps = {
  WelcomeBlock: WelcomeBlockProps;
  NextRunBlock: NextRunBlockProps;
  RunListBlock: RunListBlockProps;
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
  },
};
