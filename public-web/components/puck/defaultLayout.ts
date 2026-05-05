import type { Data } from "@measured/puck";

// Default page layout — mirrors the current landing page exactly.
// When the editor is added, this becomes the starting point for kennels
// that haven't customised their layout yet.
export const defaultLayout: Data = {
  root: { props: {} },
  content: [
    { type: "WelcomeBlock", props: { id: "welcome" } },
    { type: "NextRunBlock", props: { id: "next-run" } },
    { type: "RunListBlock", props: { id: "future-runs", isFuture: true,  count: 9  } },
    { type: "RunListBlock", props: { id: "past-runs",   isFuture: false, count: 12 } },
  ],
};
