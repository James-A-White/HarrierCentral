import type { Config } from "@measured/puck";
import { NextRunBlock } from "@/components/blocks/NextRunBlock";
import { RunListBlock } from "@/components/blocks/RunListBlock";
import { RunsPageBlock } from "@/components/blocks/RunsPageBlock";
import { EventsListBlock } from "@/components/blocks/EventsListBlock";
import { SongsListBlock } from "@/components/blocks/SongsListBlock";
import { StatsListBlock } from "@/components/blocks/StatsListBlock";
import { AboutBlock } from "@/components/blocks/AboutBlock";
import { ContentBlock } from "@/components/blocks/ContentBlock";
import { RichTextBlock } from "@/components/blocks/RichTextBlock";
import { ButtonBlock } from "@/components/blocks/ButtonBlock";
import { RowBlock } from "@/components/blocks/RowBlock";
import { RowLayoutField } from "@/components/puck/RowLayoutField";
import type { RowLayout } from "@/components/puck/RowLayoutField";
import { ImageUploadField } from "@/components/puck/ImageUploadField";
import { ButtonPositionField } from "@/components/puck/ButtonPositionField";
import { IconPickerField } from "@/components/puck/IconPickerField";
import { StepCycleField } from "@/components/puck/StepCycleField";
import { PaddingCrossField, BLOCK_V, BLOCK_H, SPACING_V, SPACING_H } from "@/components/puck/PaddingCrossField";
import type { PaddingValue } from "@/components/puck/PaddingCrossField";

type BlockProps = {
  AboutBlock: { padding: PaddingValue; blockBg: string };
  RichTextBlock: {
    content: string;
    textColor: string;
    align: "left" | "center" | "right";
    maxWidth: boolean;
    padding: PaddingValue;
    blockBg: string;
  };
  NextRunBlock: {
    offset: number;
    hideWhenNoRun: boolean;
    noRunText: string;
    showRunNumber: boolean;
    showRunName: boolean;
    showDate: boolean;
    showTime: boolean;
    showLocation: boolean;
    showHares: boolean;
    showDescription: boolean;
    showTags: boolean;
    showMap: boolean;
    showImage: boolean;
    padding: PaddingValue;
    blockBg: string;
  };
  RunListBlock: {
    viewType: string;
    isFuture: boolean;
    skipNextRun: boolean;
    showEmptyDays: boolean;
    count: number;
    days: number;
    otherKennelSlugs: string;
    showRunNumber: boolean;
    showRunName: boolean;
    showDate: boolean;
    showTime: boolean;
    showLocation: boolean;
    showHares: boolean;
    showImage: boolean;
    kennelLogoDisplay: string;
    kennelLogoSize: string;
    kennelNameDisplay: string;
    padding: PaddingValue;
    blockBg: string;
  };
  RunsPageBlock: { padding: PaddingValue; blockBg: string };
  EventsListBlock: { padding: PaddingValue; blockBg: string };
  SongsListBlock: { padding: PaddingValue; blockBg: string };
  StatsListBlock: { padding: PaddingValue; blockBg: string };
  ContentBlock: {
    imageUrl: string;
    imageAlt: string;
    heading: string;
    headingColor: string;
    headingAlign: "left" | "center" | "right";
    body: string;
    bodyColor: string;
    bodyAlign: "left" | "center" | "right" | "justify";
    imagePosition: "left" | "right";
    imageWidth: number;
    padding: PaddingValue;
    imagePadding: PaddingValue;
    textPadding: PaddingValue;
    textGap: number;
    blockBg: string;
    hasBorder: boolean;
    borderColor: string;
    borderWidth: number;
    borderRadius: number;
    buttonPosition: string;
    buttonHref: string;
    buttonText: string;
    buttonTextColor: string;
    buttonTextAlign: "left" | "center" | "right";
    buttonColor: string;
    buttonIcon: string;
    buttonIconPosition: "before" | "after" | "only";
    buttonPadding: PaddingValue;
  };
  ButtonBlock: {
    label: string;
    href: string;
    buttonStyle: "primary" | "outline" | "ghost";
    align: "left" | "center" | "right";
    paddingTop: number;
    paddingBottom: number;
    blockBg: string;
  };
  RowBlock: {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    "column-0": any; "column-1": any; "column-2": any; "column-3": any;
    layout: RowLayout;
    gap: number;
    verticalAlign: "flex-start" | "center" | "stretch";
    collapseBelow: string;
    padding: PaddingValue;
    blockBg: string;
  };
};

export interface NavPage {
  label: string;
  href: string;
}

// ─── Shared field options ────────────────────────────────────────────────────

const TEXT_GAP_OPTIONS = [
  { label: "—",  value: 0  },
  { label: "S",  value: 4  },
  { label: "M",  value: 8  },
  { label: "L",  value: 16 },
  { label: "XL", value: 24 },
];

const BG_OPTIONS = [
  { label: "Transparent",     value: ""                         },
  { label: "Card background", value: "var(--kennel-card-bg)"    },
  { label: "Primary",         value: "var(--kennel-primary)"    },
  { label: "On primary",      value: "var(--kennel-primary-fg)" },
  { label: "Accent",          value: "var(--kennel-accent)"     },
  { label: "White",           value: "#ffffff"                  },
  { label: "Black",           value: "#000000"                  },
];

const DEFAULT_PADDING: PaddingValue = { top: 0, right: 0, bottom: 0, left: 0 };

// ─── Shared render helpers ───────────────────────────────────────────────────

function blockStyle(padding: PaddingValue | undefined, blockBg: string | undefined): React.CSSProperties {
  return {
    padding: `${padding?.top ?? 0}px ${padding?.right ?? 0}px ${padding?.bottom ?? 0}px ${padding?.left ?? 0}px`,
    ...(blockBg ? { background: blockBg } : {}),
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function markdownField(label: string): any {
  return {
    type: "custom",
    label,
    render: ({ value, onChange }: { value: string; onChange: (v: string) => void }) => (
      <textarea
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value)}
        rows={10}
        placeholder={"Supports markdown:\n# Heading 1\n## Heading 2\n**bold**, *italic*\n[link text](https://example.com)\n- bullet item"}
        style={{
          width: "100%",
          padding: "8px 10px",
          fontSize: "12px",
          fontFamily: "ui-monospace, monospace",
          lineHeight: 1.6,
          border: "1px solid #d1d5db",
          borderRadius: "6px",
          resize: "vertical",
          background: "#fff",
          color: "#111827",
          outline: "none",
          boxSizing: "border-box",
        }}
      />
    ),
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function checkboxField(label: string): any {
  return {
    type: "custom",
    label: "",
    render: ({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) => (
      <label style={{ display: "flex", alignItems: "center", gap: "8px", cursor: "pointer", padding: "2px 0", userSelect: "none" }}>
        <input
          type="checkbox"
          checked={!!value}
          onChange={(e) => onChange(e.target.checked)}
          style={{ width: "14px", height: "14px", cursor: "pointer", accentColor: "#818cf8", flexShrink: 0 }}
        />
        <span style={{ fontSize: "12px", color: "#18181b" }}>{label}</span>
      </label>
    ),
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function paddingField(): any {
  return {
    type: "custom",
    label: "Padding",
    render: ({ value, onChange }: { value: PaddingValue; onChange: (v: PaddingValue) => void }) => (
      <PaddingCrossField
        label="Padding"
        value={value}
        onChange={onChange}
        verticalOptions={BLOCK_V}
        horizontalOptions={BLOCK_H}
      />
    ),
  };
}

// ─── Config ─────────────────────────────────────────────────────────────────

export function createPuckConfig(slug: string, navPages: NavPage[] = []): Config<BlockProps> {
  return {
    components: {

      // ── AboutBlock (compatibility shim — not shown in editor, kept so existing layouts render)
      AboutBlock: {
        label: "About (deprecated — replace with Content Block)",
        fields: {
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: { blockBg: "", padding: DEFAULT_PADDING },
        render: ({ blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <AboutBlock />
          </div>
        ),
      },

      // ── RichTextBlock ─────────────────────────────────────────────────────
      RichTextBlock: {
        label: "Rich Text",
        fields: {
          content: markdownField("Content (markdown)"),
          textColor: {
            type: "select",
            label: "Text colour",
            options: [
              { label: "Default (body)",  value: ""                         },
              { label: "Title colour",    value: "var(--kennel-text-title)" },
              { label: "Muted",           value: "var(--kennel-text-muted)" },
              { label: "Primary",         value: "var(--kennel-primary)"    },
              { label: "On primary",      value: "var(--kennel-primary-fg)" },
              { label: "White",           value: "#ffffff"                  },
              { label: "Black",           value: "#000000"                  },
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
          maxWidth: checkboxField("Constrain to readable width (~640px)"),
          blockBg:  { type: "select", label: "Background", options: BG_OPTIONS },
          padding:  paddingField(),
        },
        defaultProps: {
          content:   "",
          textColor: "",
          align:     "left",
          maxWidth:  false,
          blockBg:   "",
          padding:   DEFAULT_PADDING,
        },
        render: ({ content, textColor, align, maxWidth, blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <RichTextBlock
              content={content}
              textColor={textColor}
              align={align}
              maxWidth={maxWidth}
              padding={{ top: 0, right: 0, bottom: 0, left: 0 }}
              blockBg=""
            />
          </div>
        ),
      },

      // ── NextRunBlock ──────────────────────────────────────────────────────
      NextRunBlock: {
        label: "Next Run",
        fields: {
          // ── Which run ────────────────────────────────────────────────────
          offset: {
            type: "number",
            label: "Run offset (0 = next run, 1 = run after, -1 = most recent past, etc.)",
            min: -5,
            max: 10,
          },
          // ── When no run exists ───────────────────────────────────────────
          hideWhenNoRun: checkboxField("Hide block when no run exists"),
          noRunText: {
            type: "text",
            label: "Text to show when no run (if not hiding)",
          },
          // ── Display options ──────────────────────────────────────────────
          showRunNumber:   checkboxField("Run number"),
          showRunName:     checkboxField("Run name"),
          showDate:        checkboxField("Date"),
          showTime:        checkboxField("Time"),
          showLocation:    checkboxField("Location"),
          showHares:       checkboxField("Hares"),
          showDescription: checkboxField("Description"),
          showTags:        checkboxField("Tags"),
          showMap:         checkboxField("Map"),
          showImage:       checkboxField("Run image"),
          // ── Layout ───────────────────────────────────────────────────────
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: {
          offset:          0,
          hideWhenNoRun:   true,
          noRunText:       "",
          showRunNumber:   true,
          showRunName:     true,
          showDate:        true,
          showTime:        true,
          showLocation:    true,
          showHares:       true,
          showDescription: true,
          showTags:        false,
          showMap:         false,
          showImage:       true,
          blockBg:         "",
          padding:         DEFAULT_PADDING,
        },
        render: ({
          offset, hideWhenNoRun, noRunText,
          showRunNumber, showRunName, showDate, showTime,
          showLocation, showHares, showDescription, showTags, showMap, showImage,
          blockBg, padding,
        }) => (
          <div style={blockStyle(padding, blockBg)}>
            <NextRunBlock
              offset={offset}
              hideWhenNoRun={hideWhenNoRun}
              noRunText={noRunText}
              showRunNumber={showRunNumber}
              showRunName={showRunName}
              showDate={showDate}
              showTime={showTime}
              showLocation={showLocation}
              showHares={showHares}
              showDescription={showDescription}
              showTags={showTags}
              showMap={showMap}
              showImage={showImage}
            />
          </div>
        ),
      },

      // ── RunListBlock ──────────────────────────────────────────────────────
      RunListBlock: {
        label: "Run List",
        fields: {
          // ── View & data ──────────────────────────────────────────────────
          viewType: {
            type: "select",
            label: "View type",
            options: [
              { label: "Card",     value: "card"     },
              { label: "Calendar", value: "calendar" },
            ],
          },
          isFuture: {
            type: "radio",
            label: "Which runs",
            options: [
              { label: "Upcoming", value: true  },
              { label: "Past",     value: false },
            ],
          },
          skipNextRun: checkboxField("Skip next run (avoids duplicate with Next Run block)"),
          // ── Filters ──────────────────────────────────────────────────────
          count: {
            type: "number",
            label: "Max runs to show (0 = all)",
            min: 0,
          },
          days: {
            type: "number",
            label: "Max days to show (0 = all)",
            min: 0,
          },
          otherKennelSlugs: {
            type: "text",
            label: "Other kennel slugs (comma-separated, e.g. lh3,sh3)",
          },
          // ── Display — what each run shows ────────────────────────────────
          showRunNumber: checkboxField("Run number"),
          showRunName:   checkboxField("Run name"),
          showDate:      checkboxField("Date"),
          showTime:      checkboxField("Time"),
          showLocation:  checkboxField("Location"),
          showHares:     checkboxField("Hares"),
          showImage:     checkboxField("Run image"),
          kennelLogoDisplay: {
            type: "radio",
            label: "Kennel logo",
            options: [
              { label: "Multi-kennel only", value: "multi"  },
              { label: "Always",            value: "always" },
              { label: "Never",             value: "never"  },
            ],
          },
          kennelLogoSize: {
            type: "select",
            label: "Logo size",
            options: [
              { label: "Small",       value: "sm" },
              { label: "Medium",      value: "md" },
              { label: "Large",       value: "lg" },
              { label: "Extra large", value: "xl" },
            ],
          },
          kennelNameDisplay: {
            type: "radio",
            label: "Kennel name",
            options: [
              { label: "Multi-kennel only", value: "multi"  },
              { label: "Always",            value: "always" },
              { label: "Never",             value: "never"  },
            ],
          },
          // ── Calendar-specific ────────────────────────────────────────────
          showEmptyDays: checkboxField("Show empty days (calendar view only)"),
          // ── Layout ───────────────────────────────────────────────────────
          blockBg:  { type: "select", label: "Background", options: BG_OPTIONS },
          padding:  paddingField(),
        },
        defaultProps: {
          viewType:          "card",
          isFuture:          true,
          skipNextRun:       true,
          showEmptyDays:     false,
          count:             0,
          days:              0,
          otherKennelSlugs:  "",
          showRunNumber:     true,
          showRunName:       true,
          showDate:          true,
          showTime:          true,
          showLocation:      true,
          showHares:         true,
          showImage:         false,
          kennelLogoDisplay: "multi",
          kennelLogoSize:    "md",
          kennelNameDisplay: "multi",
          blockBg:           "",
          padding:           DEFAULT_PADDING,
        },
        render: ({
          viewType, isFuture, skipNextRun, showEmptyDays,
          count, days, otherKennelSlugs,
          showRunNumber, showRunName, showDate, showTime, showLocation, showHares, showImage,
          kennelLogoDisplay, kennelLogoSize, kennelNameDisplay,
          blockBg, padding,
        }) => (
          <div style={blockStyle(padding, blockBg)}>
            <RunListBlock
              viewType={viewType}
              isFuture={isFuture}
              skipNextRun={skipNextRun}
              showEmptyDays={showEmptyDays}
              count={count}
              days={days}
              otherKennelSlugs={otherKennelSlugs}
              showRunNumber={showRunNumber}
              showRunName={showRunName}
              showDate={showDate}
              showTime={showTime}
              showLocation={showLocation}
              showHares={showHares}
              showImage={showImage}
              kennelLogoDisplay={kennelLogoDisplay}
              kennelLogoSize={kennelLogoSize}
              kennelNameDisplay={kennelNameDisplay}
            />
          </div>
        ),
      },

      // ── RunsPageBlock ─────────────────────────────────────────────────────
      RunsPageBlock: {
        label: "Runs Page",
        fields: {
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: { blockBg: "", padding: DEFAULT_PADDING },
        render: ({ blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <RunsPageBlock />
          </div>
        ),
      },

      // ── EventsListBlock ───────────────────────────────────────────────────
      EventsListBlock: {
        label: "Events List",
        fields: {
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: { blockBg: "", padding: DEFAULT_PADDING },
        render: ({ blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <EventsListBlock />
          </div>
        ),
      },

      // ── SongsListBlock ────────────────────────────────────────────────────
      SongsListBlock: {
        label: "Songs List",
        fields: {
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: { blockBg: "", padding: DEFAULT_PADDING },
        render: ({ blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <SongsListBlock />
          </div>
        ),
      },

      // ── StatsListBlock ────────────────────────────────────────────────────
      StatsListBlock: {
        label: "Stats List",
        fields: {
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: { blockBg: "", padding: DEFAULT_PADDING },
        render: ({ blockBg, padding }) => (
          <div style={blockStyle(padding, blockBg)}>
            <StatsListBlock />
          </div>
        ),
      },

      // ── ContentBlock ──────────────────────────────────────────────────────
      // Already has blockBg and padding — no wrapper needed.
      ContentBlock: {
        label: "Content Block",
        fields: {
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
          padding: {
            type: "custom",
            label: "Block padding",
            render: ({ value, onChange }) => (
              <PaddingCrossField
                label="Block padding"
                value={value as PaddingValue}
                onChange={onChange}
                verticalOptions={BLOCK_V}
                horizontalOptions={BLOCK_H}
              />
            ),
          },
          imagePosition: {
            type: "radio",
            label: "Image side",
            options: [
              { label: "Left",  value: "left"  },
              { label: "Right", value: "right" },
            ],
          },
          imageUrl: {
            type: "custom",
            label: "Image",
            render: ({ value, onChange }) => (
              <ImageUploadField value={value as string} onChange={onChange} slug={slug} />
            ),
          },
          imageAlt: { type: "text", label: "Image alt text" },
          imagePadding: {
            type: "custom",
            label: "Image padding",
            render: ({ value, onChange }) => (
              <PaddingCrossField
                label="Image padding"
                value={value as PaddingValue}
                onChange={onChange}
                verticalOptions={SPACING_V}
                horizontalOptions={SPACING_H}
              />
            ),
          },
          heading: { type: "text", label: "Heading" },
          headingColor: {
            type: "select",
            label: "Heading colour",
            options: [
              { label: "Default",      value: ""                         },
              { label: "Title colour", value: "var(--kennel-text-title)" },
              { label: "Body colour",  value: "var(--kennel-text-body)"  },
              { label: "Muted",        value: "var(--kennel-text-muted)" },
              { label: "Primary",      value: "var(--kennel-primary)"    },
              { label: "On primary",   value: "var(--kennel-primary-fg)" },
              { label: "Accent",       value: "var(--kennel-accent)"     },
              { label: "White",        value: "#ffffff"                  },
              { label: "Black",        value: "#000000"                  },
            ],
          },
          headingAlign: {
            type: "radio",
            label: "Heading alignment",
            options: [
              { label: "Left",   value: "left"   },
              { label: "Center", value: "center" },
              { label: "Right",  value: "right"  },
            ],
          },
          textGap: {
            type: "custom",
            label: "Heading / body gap",
            render: ({ value, onChange }) => (
              <StepCycleField
                label="Heading / body gap"
                value={value as number}
                onChange={onChange}
                options={TEXT_GAP_OPTIONS}
              />
            ),
          },
          body: markdownField("Body text (markdown)"),
          bodyColor: {
            type: "select",
            label: "Body text colour",
            options: [
              { label: "Default",      value: ""                         },
              { label: "Title colour", value: "var(--kennel-text-title)" },
              { label: "Body colour",  value: "var(--kennel-text-body)"  },
              { label: "Muted",        value: "var(--kennel-text-muted)" },
              { label: "Primary",      value: "var(--kennel-primary)"    },
              { label: "On primary",   value: "var(--kennel-primary-fg)" },
              { label: "Accent",       value: "var(--kennel-accent)"     },
              { label: "White",        value: "#ffffff"                  },
              { label: "Black",        value: "#000000"                  },
            ],
          },
          bodyAlign: {
            type: "radio",
            label: "Body text alignment",
            options: [
              { label: "Left",   value: "left"    },
              { label: "Center", value: "center"  },
              { label: "Right",  value: "right"   },
              { label: "Full",   value: "justify" },
            ],
          },
          textPadding: {
            type: "custom",
            label: "Text padding",
            render: ({ value, onChange }) => (
              <PaddingCrossField
                label="Text padding"
                value={value as PaddingValue}
                onChange={onChange}
                verticalOptions={SPACING_V}
                horizontalOptions={SPACING_H}
              />
            ),
          },
          buttonPosition: {
            type: "custom",
            label: "Button position",
            render: ({ value, onChange }) => (
              <ButtonPositionField value={value as string} onChange={onChange} />
            ),
          },
          buttonHref: {
            type: "select",
            label: "Button links to",
            options: navPages.length > 0
              ? [{ label: "— select a page —", value: "" }, ...navPages.map(p => ({ label: p.label, value: p.href }))]
              : [{ label: "No active pages", value: "" }],
          },
          buttonText: { type: "text", label: "Button text" },
          buttonTextColor: {
            type: "select",
            label: "Button text colour",
            options: [
              { label: "Default (on primary)", value: ""                         },
              { label: "Title colour",         value: "var(--kennel-text-title)" },
              { label: "Body colour",          value: "var(--kennel-text-body)"  },
              { label: "Primary",              value: "var(--kennel-primary)"    },
              { label: "Accent",               value: "var(--kennel-accent)"     },
              { label: "White",                value: "#ffffff"                  },
              { label: "Black",                value: "#000000"                  },
            ],
          },
          buttonTextAlign: {
            type: "radio",
            label: "Button text alignment",
            options: [
              { label: "Left",   value: "left"   },
              { label: "Center", value: "center" },
              { label: "Right",  value: "right"  },
            ],
          },
          buttonColor: {
            type: "select",
            label: "Button colour",
            options: [
              { label: "Primary",      value: "var(--kennel-primary)"    },
              { label: "On primary",   value: "var(--kennel-primary-fg)" },
              { label: "Accent",       value: "var(--kennel-accent)"     },
              { label: "Title colour", value: "var(--kennel-text-title)" },
              { label: "Body colour",  value: "var(--kennel-text-body)"  },
              { label: "White",        value: "#ffffff"                  },
              { label: "Black",        value: "#000000"                  },
            ],
          },
          buttonPadding: {
            type: "custom",
            label: "Button padding",
            render: ({ value, onChange }) => (
              <PaddingCrossField
                label="Button padding"
                value={value as PaddingValue}
                onChange={onChange}
                verticalOptions={SPACING_V}
                horizontalOptions={SPACING_H}
              />
            ),
          },
          buttonIcon: {
            type: "custom",
            label: "Button icon",
            render: ({ value, onChange }) => (
              <IconPickerField value={value as string} onChange={onChange} />
            ),
          },
          buttonIconPosition: {
            type: "radio",
            label: "Icon position",
            options: [
              { label: "Before text", value: "before" },
              { label: "After text",  value: "after"  },
              { label: "Icon only",   value: "only"   },
            ],
          },
          blockBg: {
            type: "select",
            label: "Block background",
            options: BG_OPTIONS,
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
              { label: "Primary",      value: "var(--kennel-primary)"    },
              { label: "On primary",   value: "var(--kennel-primary-fg)" },
              { label: "Accent",       value: "var(--kennel-accent)"     },
              { label: "Title colour", value: "var(--kennel-text-title)" },
              { label: "Body colour",  value: "var(--kennel-text-body)"  },
              { label: "Muted",        value: "var(--kennel-text-muted)" },
              { label: "White",        value: "#ffffff"                  },
              { label: "Black",        value: "#000000"                  },
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
          headingColor: "",
          headingAlign: "left",
          body: "",
          bodyColor: "",
          bodyAlign: "left",
          imagePosition: "left",
          imageWidth: 60,
          padding: { top: 40, right: 5, bottom: 40, left: 5 },
          imagePadding: { top: 0, right: 0, bottom: 0, left: 0 },
          textPadding:  { top: 0, right: 0, bottom: 0, left: 0 },
          textGap: 16,
          blockBg: "",
          hasBorder: false,
          borderColor: "var(--kennel-primary)",
          borderWidth: 2,
          borderRadius: 0,
          buttonPosition: "",
          buttonHref: "",
          buttonText: "Learn more",
          buttonTextColor: "",
          buttonTextAlign: "center",
          buttonColor: "var(--kennel-primary)",
          buttonIcon: "ArrowRight",
          buttonIconPosition: "after",
          buttonPadding: { top: 0, right: 0, bottom: 0, left: 0 },
        },
        render: ({ imageUrl, imageAlt, heading, headingColor, headingAlign, body, bodyColor, bodyAlign, imagePosition, imageWidth, padding, imagePadding, textPadding, textGap, blockBg, hasBorder, borderColor, borderWidth, borderRadius, buttonPosition, buttonHref, buttonText, buttonTextColor, buttonTextAlign, buttonColor, buttonIcon, buttonIconPosition, buttonPadding }) => (
          <ContentBlock
            imageUrl={imageUrl}
            imageAlt={imageAlt}
            heading={heading}
            headingColor={headingColor}
            headingAlign={headingAlign}
            body={body}
            bodyColor={bodyColor}
            bodyAlign={bodyAlign}
            imagePosition={imagePosition}
            imageWidth={imageWidth}
            padding={padding}
            imagePadding={imagePadding}
            textPadding={textPadding}
            textGap={textGap}
            blockBg={blockBg}
            hasBorder={hasBorder}
            borderColor={borderColor}
            borderWidth={borderWidth}
            borderRadius={borderRadius}
            buttonPosition={buttonPosition}
            buttonHref={buttonHref}
            buttonText={buttonText}
            buttonTextColor={buttonTextColor}
            buttonTextAlign={buttonTextAlign}
            buttonColor={buttonColor}
            buttonIcon={buttonIcon}
            buttonIconPosition={buttonIconPosition}
            buttonPadding={buttonPadding}
          />
        ),
      },

      // ── ButtonBlock ───────────────────────────────────────────────────────
      // Already has paddingTop / paddingBottom — only background added.
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
              { label: "None",   value: 0  },
              { label: "Small",  value: 16 },
              { label: "Medium", value: 40 },
              { label: "Large",  value: 80 },
            ],
          },
          paddingBottom: {
            type: "select",
            label: "Bottom padding",
            options: [
              { label: "None",   value: 0  },
              { label: "Small",  value: 16 },
              { label: "Medium", value: 40 },
              { label: "Large",  value: 80 },
            ],
          },
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
        },
        defaultProps: {
          label: "Learn more",
          href: `/${slug}`,
          buttonStyle: "primary",
          align: "left",
          paddingTop: 16,
          paddingBottom: 16,
          blockBg: "",
        },
        render: ({ label, href, buttonStyle, align, paddingTop, paddingBottom, blockBg }) => (
          <div style={{ background: blockBg || undefined }}>
            <ButtonBlock
              label={label}
              href={href}
              buttonStyle={buttonStyle}
              align={align}
              paddingTop={paddingTop}
              paddingBottom={paddingBottom}
            />
          </div>
        ),
      },

      // ── RowBlock ──────────────────────────────────────────────────────────
      RowBlock: {
        label: "Row",
        fields: {
          // Slot fields — one per possible column (unused slots are hidden)
          "column-0": { type: "slot" },
          "column-1": { type: "slot" },
          "column-2": { type: "slot" },
          "column-3": { type: "slot" },
          layout: {
            type: "custom",
            label: "Layout",
            render: ({ value, onChange }) => (
              <RowLayoutField value={value as RowLayout} onChange={onChange} />
            ),
          },
          gap: {
            type: "select",
            label: "Column gap",
            options: [
              { label: "None",   value: 0  },
              { label: "Small",  value: 8  },
              { label: "Medium", value: 16 },
              { label: "Large",  value: 24 },
              { label: "XL",     value: 40 },
            ],
          },
          verticalAlign: {
            type: "radio",
            label: "Vertical alignment",
            options: [
              { label: "Top",     value: "flex-start" },
              { label: "Centre",  value: "center"     },
              { label: "Stretch", value: "stretch"    },
            ],
          },
          collapseBelow: {
            type: "select",
            label: "Collapse to single column below",
            options: [
              { label: "Small — 640px  (phones)",  value: "sm"    },
              { label: "Medium — 768px (tablets)", value: "md"    },
              { label: "Large — 1024px",           value: "lg"    },
              { label: "Never collapse",           value: "never" },
            ],
          },
          blockBg: { type: "select", label: "Background", options: BG_OPTIONS },
          padding: paddingField(),
        },
        defaultProps: {
          "column-0": [], "column-1": [], "column-2": [], "column-3": [],
          layout: { columns: 2 as const, flex: [1, 1, 1, 1] as [number, number, number, number] },
          gap: 16,
          verticalAlign: "flex-start" as const,
          collapseBelow: "sm",
          blockBg: "",
          padding: DEFAULT_PADDING,
        },
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        render: ({ "column-0": Col0, "column-1": Col1, "column-2": Col2, "column-3": Col3, layout, gap, verticalAlign, collapseBelow, blockBg, padding }: any) => {
          const { columns, flex } = layout as RowLayout;
          const slots = [Col0, Col1, Col2, Col3] as React.ComponentType<{ disallow?: string[] }>[];
          return (
            <div style={blockStyle(padding, blockBg)}>
              <RowBlock layout={layout as RowLayout} gap={gap} verticalAlign={verticalAlign} collapseBelow={collapseBelow}>
                {Array.from({ length: columns }).map((_, i) => {
                  const Slot = slots[i];
                  return (
                    <div key={i} style={{ flex: flex?.[i] ?? 1, minWidth: 0 }}>
                      <Slot disallow={["RowBlock"]} />
                    </div>
                  );
                })}
              </RowBlock>
            </div>
          );
        },
      },

    },
  };
}
