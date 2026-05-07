import type { Config } from "@measured/puck";
import { WelcomeBlock } from "@/components/blocks/WelcomeBlock";
import { NextRunBlock } from "@/components/blocks/NextRunBlock";
import { RunListBlock } from "@/components/blocks/RunListBlock";
import { RunsPageBlock } from "@/components/blocks/RunsPageBlock";
import { AboutBlock } from "@/components/blocks/AboutBlock";
import { EventsListBlock } from "@/components/blocks/EventsListBlock";
import { SongsListBlock } from "@/components/blocks/SongsListBlock";
import { StatsListBlock } from "@/components/blocks/StatsListBlock";
import { ImageTextBlock } from "@/components/blocks/ImageTextBlock";
import { ImageUploadField } from "@/components/puck/ImageUploadField";

type BlockProps = {
  WelcomeBlock: Record<string, never>;
  NextRunBlock: Record<string, never>;
  RunListBlock: { isFuture: boolean; count: number };
  RunsPageBlock: Record<string, never>;
  AboutBlock: Record<string, never>;
  EventsListBlock: Record<string, never>;
  SongsListBlock: Record<string, never>;
  StatsListBlock: Record<string, never>;
  ImageTextBlock: {
    imageUrl: string;
    imageAlt: string;
    heading: string;
    body: string;
    imagePosition: "left" | "right";
    imageWidth: number;
    textColor: string;
    paddingTop: number;
    paddingBottom: number;
    paddingLeft: number;
    paddingRight: number;
    blockBg: string;
  };
};

export function createPuckConfig(slug: string): Config<BlockProps> {
  return {
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
      ImageTextBlock: {
        label: "Image + Text",
        fields: {
          imageUrl: {
            type: "custom",
            label: "Image",
            render: ({ value, onChange }) => (
              <ImageUploadField value={value as string} onChange={onChange} slug={slug} />
            ),
          },
          imageAlt: { type: "text", label: "Image alt text" },
          heading: { type: "text", label: "Heading" },
          body: { type: "textarea", label: "Body text" },
          imagePosition: {
            type: "radio",
            label: "Image side",
            options: [
              { label: "Left", value: "left" },
              { label: "Right", value: "right" },
            ],
          },
          imageWidth: {
            type: "select",
            label: "Layout",
            options: [
              ...[10, 20, 30, 40, 50, 60, 70, 80, 90].map((n) => ({
                label: `${n}% image / ${100 - n}% text`,
                value: n,
              })),
              { label: "Image only",       value: 100 },
              { label: "Text only",        value: 0   },
              { label: "Image above text", value: -1  },
              { label: "Text above image", value: -2  },
            ],
          },
          paddingTop: {
            type: "select",
            label: "Top padding",
            options: [
              { label: "None",   value: 0   },
              { label: "Small",  value: 16  },
              { label: "Medium", value: 40  },
              { label: "Large",  value: 80  },
              { label: "XL",     value: 128 },
            ],
          },
          paddingBottom: {
            type: "select",
            label: "Bottom padding",
            options: [
              { label: "None",   value: 0   },
              { label: "Small",  value: 16  },
              { label: "Medium", value: 40  },
              { label: "Large",  value: 80  },
              { label: "XL",     value: 128 },
            ],
          },
          paddingLeft: {
            type: "select",
            label: "Left padding",
            options: [0, 5, 10, 15, 20, 25, 30].map((n) => ({
              label: n === 0 ? "None" : `${n}%`,
              value: n,
            })),
          },
          paddingRight: {
            type: "select",
            label: "Right padding",
            options: [0, 5, 10, 15, 20, 25, 30].map((n) => ({
              label: n === 0 ? "None" : `${n}%`,
              value: n,
            })),
          },
          blockBg: {
            type: "select",
            label: "Block background",
            options: [
              { label: "Transparent",      value: ""                         },
              { label: "Card background",  value: "var(--kennel-card-bg)"    },
              { label: "Primary",          value: "var(--kennel-primary)"    },
              { label: "On primary",       value: "var(--kennel-primary-fg)" },
              { label: "Accent",           value: "var(--kennel-accent)"     },
              { label: "White",            value: "#ffffff"                  },
              { label: "Black",            value: "#000000"                  },
            ],
          },
          textColor: {
            type: "select",
            label: "Text colour",
            options: [
              { label: "Default",      value: ""                          },
              { label: "Title colour", value: "var(--kennel-text-title)"  },
              { label: "Body colour",  value: "var(--kennel-text-body)"   },
              { label: "Muted",        value: "var(--kennel-text-muted)"  },
              { label: "Primary",      value: "var(--kennel-primary)"     },
              { label: "On primary",   value: "var(--kennel-primary-fg)"  },
              { label: "Accent",       value: "var(--kennel-accent)"      },
              { label: "White",        value: "#ffffff"                   },
              { label: "Black",        value: "#000000"                   },
            ],
          },
        },
        defaultProps: {
          imageUrl: "",
          imageAlt: "",
          heading: "",
          body: "",
          imagePosition: "left",
          imageWidth: 60,
          paddingTop: 40,
          paddingBottom: 40,
          paddingLeft: 5,
          paddingRight: 5,
          blockBg: "",
          textColor: "",
        },
        render: ({ imageUrl, imageAlt, heading, body, imagePosition, imageWidth, textColor, paddingTop, paddingBottom, paddingLeft, paddingRight, blockBg }) => (
          <ImageTextBlock
            imageUrl={imageUrl}
            imageAlt={imageAlt}
            heading={heading}
            body={body}
            imagePosition={imagePosition}
            imageWidth={imageWidth}
            textColor={textColor}
            paddingTop={paddingTop}
            paddingBottom={paddingBottom}
            paddingLeft={paddingLeft}
            paddingRight={paddingRight}
            blockBg={blockBg}
          />
        ),
      },
    },
  };
}
