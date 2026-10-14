---
paths:
  - "mobile-app/**/*.dart"
  - "portal/**/*.dart"
  - "public-web/**/*.tsx"
  - "public-web/**/*.ts"
---

# Photos and Kennel Logos

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read a Dart file or a public-web source file.

---

**Trail photos are shown in a carousel, on a Harrier Central background
(every client):**

A photo of a trail is never a dead end and never a bare image on a white
page. Wherever individual run or trail photos are displayed — any client, any
screen — three things hold:

1. **A carousel, not a terminus.** One photo at a time, with a way to the
   next: arrows, swipe, or both. A grid of thumbnails is fine as the way *in*,
   but every thumbnail opens the carousel **at that photo**, never the raw
   blob URL. A link straight to `harriercentral.blob.core.windows.net` gives
   the viewer a bare image with no way back to the run, no way on to the next
   photo, and none of the kennel's styling. That was the state of the web's
   run photo page and its photo strip until 2026-09-22.
2. **Shown whole, at its own aspect ratio — thumbnails too.** `BoxFit.contain`
   / `object-contain`, never `cover`, and never a fixed box that forces a
   shape. A hash photo cropped to fit loses whoever was standing at the edge,
   and the joke with them — Trail TV's strip cut heads off (James,
   2026-09-28: "I always want photos to display in their normal aspect
   ratio"). A ROW of photos (a strip, a grid line) gives them all the SAME
   HEIGHT and lets each WIDTH follow its aspect ratio (`height: 100%;
   width: auto`, or `SizedBox(height: h, child: Image(fit: BoxFit.fitHeight))`).
   A photo that does not fit the row drops out whole — wrap onto a hidden
   line — rather than being cut at the edge. This supersedes the old
   allowance for square-cropped thumbnails. (Profile photos are square and
   shown whole, never trimmed into a circle — James, 2026-10-02; a kennel
   logo follows its own rule below.)
3. **On the right backdrop**, which differs per client:

| Client | Backdrop | How |
|---|---|---|
| Mobile app | Jungle | `Backgrounds.defaultHcBackground()`, passed into the viewer (see `MapPhotoPage`) |
| Portal | Hash foot, **light** variant | `Backgrounds.defaultHcBackgroundLight()` — the portal is white cards and slate text, and the dark tile makes the console unreadable |
| Public web | **The kennel's own artwork** where they have it, the jungle where they do not | `<KennelBackground kennel={kennel} />` — it already falls back to `/images/jungle_background.jpg` |

The photo itself sits on a dark translucent pane over that backdrop, so the
backdrop reads at the edges rather than being covered by a flat slab.

**Downloads go through `/api/photo-download` (web).** The `download`
attribute is ignored cross-origin and the photos are on the blob account, so
a direct link just reopens the image. That one route re-serves the bytes from
our origin with `Content-Disposition: attachment`; it is allowlisted to our
storage host, because without that it is an open proxy. There is ONE such
route — a second was added and removed on 2026-09-22.

Audited across all three clients on 2026-09-22. The mobile app already
complied everywhere.

**Never crop or mask a kennel logo (web and Flutter):**

A kennel's logo is its identity and its members designed it. It is shown
whole, always, on every surface: run cards, kennel cards, run history, chat
lists, kennel pages, the web and the app alike. Never put it behind a
circular mask, never square it off, never let a container clip it.

- Fit it with `object-contain` (CSS) or `BoxFit.contain` (Flutter), inside a
  box it is free to letterbox within. Never `object-cover` / `BoxFit.cover`,
  which crops whatever does not fit.
- Never pair a logo with `rounded-full` + `overflow-hidden`, `ClipOval`,
  `CircleAvatar`, or `shape: BoxShape.circle`. Wide logos are common and a
  circle eats their ends: CHEastEnders lost both sides this way on the web's
  Run Counts list (James, 2026-09-17).
- Rounding the CONTAINER is fine as long as the logo inside is contained and
  fully visible. It is the clipping of the image that is banned, not the
  corner radius of a card.

This applies only to kennel logos and kennel cover art. Hasher profile
photos are always SQUARE and shown whole — never trimmed into a circle
(James, 2026-10-02); new screens use `HasherPhoto`. Older screens that
still draw circular avatars are to be changed as they are touched. Country
flags keep the circular treatment the app already gives them.
