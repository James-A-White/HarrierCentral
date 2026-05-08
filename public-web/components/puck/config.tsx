import type { Config } from "@measured/puck";
import { NextRunBlock } from "@/components/blocks/NextRunBlock";
import { RunListBlock } from "@/components/blocks/RunListBlock";
import { RunsPageBlock } from "@/components/blocks/RunsPageBlock";
import { AboutBlock } from "@/components/blocks/AboutBlock";
import { EventsListBlock } from "@/components/blocks/EventsListBlock";
import { SongsListBlock } from "@/components/blocks/SongsListBlock";
import { StatsListBlock } from "@/components/blocks/StatsListBlock";
import { ImageTextBlock } from "@/components/blocks/ImageTextBlock";
import { ButtonBlock } from "@/components/blocks/ButtonBlock";
import { ImageUploadField } from "@/components/puck/ImageUploadField";

type BlockProps = {
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
    textAlign: "left" | "center" | "right" | "justify";
    paddingTop: number;
    paddingBottom: number;
    paddingLeft: number;
    paddingRight: number;
    blockBg: string;
    hasBorder: boolean;
    borderColor: string;
    borderWidth: number;
    borderRadius: number;
  };
  ButtonBlock: {
    label: string;
    href: string;
    buttonStyle: "primary" | "outline" | "ghost";
    align: "left" | "center" | "right";
    paddingTop: number;
    paddingBottom: number;
  };
};

export interface NavPage {
  label: string;
  href: string;
}

export function createPuckConfig(slug: string, navPages: NavPage[] = []): Config<BlockProps> {
  return {
    components: {
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
          textAlign: {
            type: "radio",
            label: "Text alignment",
            options: [
              { label: "Left",    value: "left"    },
              { label: "Center",  value: "center"  },
              { label: "Right",   value: "right"   },
              { label: "Full",    value: "justify" },
            ],
          },
          hasBorder: {
            type: "radio",
            label: "Border",
            options: [
              { label: "None", value: false },
              { label: "Show", value: true  },
            ],
          },
          borderColor: {
            type: "select",
            label: "Border colour",
            options: [
              { label: "Primary",      value: "var(--kennel-primary)"     },
              { label: "On primary",   value: "var(--kennel-primary-fg)"  },
              { label: "Accent",       value: "var(--kennel-accent)"      },
              { label: "Title colour", value: "var(--kennel-text-title)"  },
              { label: "Body colour",  value: "var(--kennel-text-body)"   },
              { label: "Muted",        value: "var(--kennel-text-muted)"  },
              { label: "White",        value: "#ffffff"                   },
              { label: "Black",        value: "#000000"                   },
            ],
          },
          borderWidth: {
            type: "select",
            label: "Border width",
            options: [
              { label: "Thin (1px)",    value: 1 },
              { label: "Regular (2px)", value: 2 },
              { label: "Thick (4px)",   value: 4 },
              { label: "Heavy (8px)",   value: 8 },
            ],
          },
          borderRadius: {
            type: "select",
            label: "Corner radius",
            options: [
              { label: "None (0px)",    value: 0  },
              { label: "Small (8px)",   value: 8  },
              { label: "Medium (16px)", value: 16 },
              { label: "Large (32px)",  value: 32 },
              { label: "XL (48px)",     value: 48 },
              { label: "Full (64px)",   value: 64 },
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
          textAlign: "left",
          hasBorder: false,
          borderColor: "var(--kennel-primary)",
          borderWidth: 2,
          borderRadius: 0,
        },
        render: ({ imageUrl, imageAlt, heading, body, imagePosition, imageWidth, textColor, textAlign, paddingTop, paddingBottom, paddingLeft, paddingRight, blockBg, hasBorder, borderColor, borderWidth, borderRadius }) => (
          <ImageTextBlock
            imageUrl={imageUrl}
            imageAlt={imageAlt}
            heading={heading}
            body={body}
            imagePosition={imagePosition}
            imageWidth={imageWidth}
            textColor={textColor}
            textAlign={textAlign}
            paddingTop={paddingTop}
            paddingBottom={paddingBottom}
            paddingLeft={paddingLeft}
            paddingRight={paddingRight}
            blockBg={blockBg}
            hasBorder={hasBorder}
            borderColor={borderColor}
            borderWidth={borderWidth}
            borderRadius={borderRadius}
          />
        ),
      },
      ButtonBlock: {
        label: "Button",
        fields: {
          label: { type: "text", label: "Button label" },
          href: {
            type: "select",
            label: "Target page",
            options: navPages.length > 0
              ? navPages.map(p => ({ label: p.label, value: p.href }))
              : [{ label: "No active pages", value: "#" }],
          },
          buttonStyle: {
            type: "radio",
            label: "Style",
            options: [
              { label: "Primary", value: "primary" },
              { label: "Outline", value: "outline" },
              { label: "Ghost",   value: "ghost"   },
            ],
          },
          align: {
            type: "radio",
            label: "Alignment",
            options: [
              { label: "Left",   value: "left"   },
              { label: "Center", value: "center" },
              { label: "Right",  value: "right"  },
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
            ],
          },
        },
        defaultProps: {
          label: "Learn more",
          href: `/${slug}`,
          buttonStyle: "primary",
          align: "left",
          paddingTop: 16,
          paddingBottom: 16,
        },
        render: ({ label, href, buttonStyle, align, paddingTop, paddingBottom }) => (
          <ButtonBlock
            label={label}
            href={href}
            buttonStyle={buttonStyle}
            align={align}
            paddingTop={paddingTop}
            paddingBottom={paddingBottom}
          />
        ),
      },
    },
  };
}
