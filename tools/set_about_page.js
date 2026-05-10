#!/usr/bin/env node
/**
 * Builds and saves the London H3 About page layout to the database.
 * Run from repo root: node tools/set_about_page.js
 */

const { execSync } = require("child_process");
const fs   = require("fs");
const path = require("path");
const os   = require("os");

// Parse .env manually — no dotenv dependency required
const envPath = path.join(__dirname, "..", ".env");
fs.readFileSync(envPath, "utf8").split("\n").forEach((line) => {
  const m = line.match(/^([^#=]+)=(.*)$/);
  if (m) process.env[m[1].trim()] = m[2].trim();
});

const { HC_SQL_SERVER, HC_SQL_DATABASE, HC_SQL_USERNAME, HC_SQL_PASSWORD } = process.env;
if (!HC_SQL_SERVER) { console.error("HC_SQL_* env vars not set."); process.exit(1); }

const KENNEL_SLUG = "LH3";
const PAGE_ID     = "about";

// ── Helpers ───────────────────────────────────────────────────────────────────

function sqlcmd(query) {
  return execSync(
    `sqlcmd -S "${HC_SQL_SERVER}" -d "${HC_SQL_DATABASE}" -U "${HC_SQL_USERNAME}" -P "${HC_SQL_PASSWORD}" -W -Q "${query.replace(/"/g, '\\"')}"`,
    { encoding: "utf8" }
  );
}

function sqlcmdFile(file) {
  return execSync(
    `sqlcmd -S "${HC_SQL_SERVER}" -d "${HC_SQL_DATABASE}" -U "${HC_SQL_USERNAME}" -P "${HC_SQL_PASSWORD}" -b -i "${file}"`,
    { encoding: "utf8" }
  );
}

// ── New About page Puck layout ────────────────────────────────────────────────

const DEFAULT_PAD = { top: 0, right: 0, bottom: 0, left: 0 };
const SECTION_PAD = { top: 40, right: 0, bottom: 0, left: 0 };

function rtb(id, content, extra = {}) {
  return {
    type: "RichTextBlock",
    props: {
      id,
      content,
      textColor: "",
      align: "left",
      maxWidth: false,
      blockBg: "",
      padding: DEFAULT_PAD,
      ...extra,
    },
  };
}

function photoStub(id) {
  return {
    type: "ContentBlock",
    props: {
      id,
      imageUrl: "",
      imageAlt: "",
      heading: "",
      headingColor: "",
      headingAlign: "left",
      body: "",
      bodyColor: "",
      bodyAlign: "left",
      imagePosition: "left",
      imageWidth: 100,
      padding: DEFAULT_PAD,
      imagePadding: DEFAULT_PAD,
      textPadding: DEFAULT_PAD,
      textGap: 16,
      blockBg: "",
      hasBorder: false,
      borderColor: "",
      borderWidth: 1,
      borderRadius: 16,
      buttonPosition: "",
      buttonHref: "",
      buttonText: "",
      buttonTextColor: "",
      buttonTextAlign: "left",
      buttonColor: "",
      buttonIcon: "",
      buttonIconPosition: "before",
      buttonPadding: { top: 8, right: 0, bottom: 0, left: 0 },
    },
  };
}

function row(id, cols, flexValues, gap = 32, extra = {}) {
  return {
    type: "RowBlock",
    props: {
      id,
      layout: { columns: cols, flex: flexValues },
      gap,
      verticalAlign: "flex-start",
      collapseBelow: "md",
      blockBg: "",
      padding: SECTION_PAD,
      ...extra,
    },
  };
}

// ── Content ───────────────────────────────────────────────────────────────────

const intro = `# London Hash House Harriers

*The drinking club with a running problem.*

The Hash House Harriers — the HHH, or simply "the Hash" — is a worldwide family of non-competitive running clubs. Trails are set through the city by volunteer "hares," and the pack follows, solving checks and false trails before ending up at the pub.

No race numbers. No finish times. No trophies. Just running, beer, and the kind of friends you make when you get slightly lost together in a park at dusk.

London H3 has been running all over London for decades. All paces welcome. No experience necessary.`;

const firstSteps = `## First Steps

Your first hash can feel a little bewildering — and that's by design.

You'll find the starting pub announced on the [runs page](/lh3/runs) a week in advance. Before the off, the hares give a quick briefing: a blob of chalk or flour means you're on trail, a circle of dots is a **check** (stop, fan out, find the trail), and three chalk marks across the path mean **false trail**. Shout "on-on" when you find trail, and "checking" when you're looking.

Faster runners hunt for trail at checks; if you're at the back, just follow whoever's shouting. You'll get there.

Somewhere in the middle there's a drink stop — a carrier bag materialises from behind a hedge with cold beer and something non-alcoholic. You drink. You run on.

The "on inn" marks tell you you're nearly back. The pack converges on the pub — sometimes from several directions at once — and then the circle begins.`;

const terminology = `## What Makes a Hash

### The Check
A circle of marks with arrows pointing outward. The pack spreads out to find where trail continues. Once someone finds it they shout "on-on" and the pack corrects course. This keeps faster and slower runners together — back-markers rarely have to do any of the detective work.

### The False Trail
Three marks across the path. Wrong way. Go back to the last check and try a different direction.

### The Drink Stop
Somewhere mid-trail, the hares have hidden refreshments. There is always beer. There is usually something non-alcoholic. Standards of cuisine vary considerably.

### The On Inn
A series of marks indicating you're nearly home. Follow them. The pub is close.`;

const circle = `## The Circle

The ceremonial heart of the hash. After the run, the pack forms a circle and the GM takes charge.

Crimes are tried. Accusations fly. Songs — varying considerably in quality — are sung. Down-downs are awarded: the accused must drink their vessel in one. First-timers, returning hashers, visiting hashers from other kennels, the hares themselves, and anyone who has done something embarrassing are all called to the centre.

It is chaotic, good-natured, and entirely compulsory for newcomers.

After the circle, the pack retires to the bar. Some people stay for one drink. Some stay considerably longer. The next run is announced. The whole thing starts again.`;

const culture = `## A Bit of History

The Hash House Harriers were founded in 1938 in Kuala Lumpur by a group of British expatriates who met at the Selangor Club — nicknamed "the Hash House" for the quality of its food. They invented a running game based on the old English sport of hare and hounds, kept the name, and the rest is history.

From that one group, hashing has spread to almost every country in the world. There are thousands of kennels globally, with major international events — Interhash, Eurohash, the Inter-Americas — drawing hashers from everywhere.

### Hash Names

Most hashers eventually earn a hash name: a nickname bestowed by the group, usually based on something embarrassing, memorable, or both. You don't choose your hash name. Your hash name chooses you.

### The Global Family

If you hash in London and then visit New York, Cape Town, Tokyo, or almost anywhere else in the world, you'll find a hash. The circle may sound slightly different, the beer will probably be local, but the chalk marks on the ground are the same and the welcome is genuine.`;

const join = `## Come and Have a Run

You don't need to be fast. You don't need to be fit. You need to be able to follow chalk marks and enjoy a drink at the end.

Runs happen weekly, year-round, rain or shine — this is London, so mostly rain. Check the [runs page](/lh3/runs) for the next start location and time. Just show up — no booking required. Bring a few pounds for the hash cash and wear shoes you don't mind getting dirty.

If you have questions before your first hash, [get in touch](/lh3/about) — we're a friendly lot.

*On-on.*`;

// ── Assemble Puck layout ──────────────────────────────────────────────────────

// Slot format: column content lives inside the RowBlock props (not in a separate zones object)
function rowWithSlots(id, cols, flexValues, col0, col1, gap = 32, extra = {}) {
  return {
    type: "RowBlock",
    props: {
      id,
      "column-0": col0,
      "column-1": col1,
      "column-2": [],
      "column-3": [],
      layout: { columns: cols, flex: flexValues },
      gap,
      verticalAlign: "flex-start",
      collapseBelow: "md",
      blockBg: "",
      padding: SECTION_PAD,
      ...extra,
    },
  };
}

const aboutLayout = {
  root: { props: {} },
  content: [
    rtb("rtb-intro", intro),
    rowWithSlots("row-first-steps", 2, [3, 2, 1, 1],
      [rtb("rtb-first-steps", firstSteps)],
      [photoStub("cb-photo-1")]
    ),
    rtb("rtb-terminology", terminology, { padding: SECTION_PAD }),
    rowWithSlots("row-circle", 2, [2, 3, 1, 1],
      [photoStub("cb-photo-2")],
      [rtb("rtb-circle", circle)]
    ),
    rtb("rtb-culture", culture, { padding: SECTION_PAD }),
    rtb("rtb-join", join, { padding: SECTION_PAD }),
  ],
};

// ── Read current layout, update about page, write back ────────────────────────

console.log(`\nFetching current layout for ${KENNEL_SLUG}...`);

const raw = execSync(
  `sqlcmd -S "${HC_SQL_SERVER}" -d "${HC_SQL_DATABASE}" -U "${HC_SQL_USERNAME}" -P "${HC_SQL_PASSWORD}" -W -h -1 -y 0 ` +
  `-Q "SET NOCOUNT ON; SELECT kw.PageLayoutJson FROM HC.KennelWebsite kw JOIN HC.Kennel k ON k.id = kw.KennelId WHERE k.KennelUniqueShortName = '${KENNEL_SLUG}'"`,
  { encoding: "utf8" }
).trim();

const siteConfig = JSON.parse(raw);

const pageIdx = siteConfig.pages.findIndex((p) => p.id === PAGE_ID);
if (pageIdx === -1) {
  console.error(`Page '${PAGE_ID}' not found in site config.`);
  process.exit(1);
}

siteConfig.pages[pageIdx].layout = aboutLayout;
siteConfig.pages[pageIdx].status = "menu"; // make it visible in nav

const newJson = JSON.stringify(siteConfig);

// Write via a temp SQL file to avoid shell escaping issues with large JSON
const tempFile = path.join(os.tmpdir(), "set_about_page.sql");
const escaped  = newJson.replace(/'/g, "''");
fs.writeFileSync(tempFile, `
UPDATE kw
SET kw.PageLayoutJson = N'${escaped}'
FROM HC.KennelWebsite kw
JOIN HC.Kennel k ON k.id = kw.KennelId
WHERE k.KennelUniqueShortName = '${KENNEL_SLUG}';
PRINT 'Updated ${KENNEL_SLUG} ${PAGE_ID} page.';
`);

console.log("Saving updated layout...");
sqlcmdFile(tempFile);
fs.unlinkSync(tempFile);

console.log(`\n✓ About page saved for ${KENNEL_SLUG}. Set to 'menu' (visible in nav).\n`);
