# Trail Markers — Canonical Spec

Status: **contract locked 2026-07-24.** This is the shared contract for the
trail-marker system consumed by the **portal** (authoring), the **mobile app**
(placing + rendering), and **public-web** (rendering). It replaces the legacy
"every marker is a baked circular badge PNG" scheme.

A marker is EITHER a short **text** sequence OR a **glyph** from a fixed library.
Most kennels mark with letters/numbers that vary by local language — those are now
free data (no artwork). Only genuinely pictorial marks ship as glyphs.

---

## 1. Marker model (stored in `HC.Kennel…trailSymbolsConfigJson`)

The column is an array of slot objects. The SPs (`hcportal_editKennel` /
`hcportal_getKennel`) pass the blob through unparsed — **no SP changes**.

```jsonc
// text marker
{ "slot": 2, "name": "False Trail", "kind": "text",  "text": "FT",      "invert": false, "action": null }
// glyph marker
{ "slot": 1, "name": "Check",       "kind": "glyph", "glyphId": "check", "invert": false, "action": null }
```

| Field | Meaning |
|---|---|
| `slot` | 1–12 slot index (ordering + identity within a kennel) |
| `name` | Display name (portal + flash confirmation) |
| `kind` | `"glyph"` \| `"text"` |
| `glyphId` | when `kind=glyph`: an id from `glyph_registry.json` |
| `text` | when `kind=text`: up to **7 non-space chars**; a **space → newline** (stacked). Case preserved as entered. `:` is disallowed. |
| `invert` | placeholder flag (see §4). Applies to text + `mono` glyphs only. |
| `action` | `null` \| `"addText"` \| `"endRun"` — **orthogonal** to presentation |

**Legacy / back-compat:** old entries have `icon: "I-050.png"` and no `kind`.
A tolerant reader maps the legacy icon → text or glyph (letter icons → text,
pictorial icons → glyphId). No forced DB migration; stored JSON may be rewritten
to the new shape later.

---

## 2. Glyph library

Canonical list lives in `glyph_registry.json` (this folder). Assets in `glyphs/`.
Each app mirrors the list in code and bundles the PNGs (bundle-per-app).

- **`colorMode: "mono"`** — single-colour silhouette (dark ink baked in, shape in
  alpha). Renderer draws it directly for the normal (dark-on-yellow) case, and
  tints it light for invert. Invertable.
- **`colorMode: "fixed"`** — full-colour PNG, rendered as-is, **never** tinted or
  inverted (e.g. `caution` is always red).

The registry — **not the filename** — is authoritative for `colorMode`. A renderer
seeing `GLY::caution` on a track must look up `caution → fixed` in the registry.
The `.mono.` / `.fixed.` filename suffix is only a human hint.

9 glyphs: `check`, `whichyway`, `fishhook`, `regroup`, `hashview`, `label`,
`drinkstop`, `oninn` (all mono); `caution` (fixed). All other historical marks
(FT, SC, CB, BS, DS, ON IN, HV, …) were letters and are expressed as **text**.

---

## 3. Track encoding (self-describing on the Azure Table track)

When a mark is placed it rides on the GPS track's `type` field. This must be
self-describing so every renderer can draw it without the kennel config.

```
type :=
    null                                   // ordinary GPS point
  | "PHO::" blobId                         // photo marker (unchanged)
  | "GLY::" glyphId  { "::" attr }
  | "TXT::" text     { "::" attr }         // text may contain spaces (→ newlines); no ':'
  | legacy                                 // I-NNN.png | HashRunPointTypes key [::label]

attr := "L=" label | "A=" action           // order-independent; UNKNOWN keys ignored
```

- **`A=<action>`** rides whenever the marker has an action (`A=endRun`, or any
  future action). Renderers switch on actions they understand — `endRun`
  terminates the drawn polyline (replaces the old hardcoded On-Inn terminator) —
  and **safely ignore unknown actions**, so old renderers never choke on new ones.
- **`L=<label>`** carries the mark-time note (the output of an `addText` marker).
  `addText` is placement-time only; the renderer just displays the label.
- **Legacy** `I-NNN.png`, `HashRunPointTypes` keys, and `key::label` are still
  parsed so historical runs keep rendering.

`:` is banned from `text` input so `::` stays an unambiguous separator; split a
segment on its first `=` only (labels may contain `=`).

---

## 4. Render spec (identical across mobile buttons, mobile map, web map)

**Tile:** rounded rectangle, **no border**. Corner radius ≈ 20% of side; glyph/
text padded ≈ 7% inside.

| | normal | invert (placeholder) |
|---|---|---|
| background | `#FCFF04` (yellow) | `#2D0000` (dark) |
| ink | `#2D0000` (dark) | `#FFFDF0` (off-white) |

- **text** → ink colour, bold, auto-sized to fit; split on space into stacked
  lines; longest line drives width, line count drives height.
- **glyph, `mono`** → draw the asset (already dark ink) for normal; tint to the
  ink colour for invert (`srcIn` in Flutter, `mask`/`currentColor` on web).
- **glyph, `fixed`** → draw as-is; ignore `invert`.

`invert` is **wired but not switched on** — standard is always the yellow tile.
The portal greys out the invert control when a `fixed` glyph is selected.

---

## 5. Rollout (one component per commit)

1. **Contract** (this doc + `glyph_registry.json` + `glyphs/`) ← *this commit*
2. **Portal** — `TrailSlotConfig` gains `kind/text/glyphId/invert`; editor gets a
   Glyph/Text toggle → glyph picker or 7-char text field (live stacked preview).
3. **Mobile** — model + `live_run_general_page` renderer (text branch, drop
   border, mono tint) + map markers + `markSlot` emits `GLY::`/`TXT::` + `A=endRun`.
4. **Public-web** — `packtrack.ts` parser + `PackTrackMap.tsx` marker draw.
5. Each app copies `glyphs/*.png` into its own asset tree.

## 6. Adding a glyph without shipping an app (2026-08-30)

Every renderer falls back to blob storage for a glyph id it does not know:

    https://harriercentral.blob.core.windows.net/trail-glyphs/<id>.mono.png
    https://harriercentral.blob.core.windows.net/trail-glyphs/<id>.fixed.png

(container `trail-glyphs`, anonymous blob read). Bundled assets always win, so
the normal path costs no network and works offline.

- **Mobile** — `TrailGlyphImage`: `kTrailGlyphs` → asset; otherwise `<id>.mono.png`
  tinted to ink, then `<id>.fixed.png` in full colour, then the "?" tile.
  Fetches go through `CachedNetworkImage`, so each glyph downloads once and is
  then served from disk, including offline.
- **Public web** — `parseMark` returns the blob URL (assumed mono) for an id
  missing from `GLYPHS`.

**To add a glyph with no release:** draw it 300x300, transparent, ink #2D0000,
32px stroke (see the existing set), name it `<id>.mono.png`, and upload:

    az storage blob upload --account-name harriercentral --auth-mode key \
      --container-name trail-glyphs --name <id>.mono.png --file <path> \
      --content-type image/png --overwrite

**LIMIT:** this makes an unknown glyph RENDER. For a kennel to *choose* one it
must appear in the slot picker, which reads the bundled `kTrailGlyphs` — that
still needs a release, or a future remote manifest. So the no-release path
covers marks laid by newer clients, not new options for older ones. Keep adding
new glyphs to `glyph_registry.json` and both asset trees as well, so they are
bundled from the next build onward.
