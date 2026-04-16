/**
 * Server-side API client for the HC6 public web shim.
 *
 * All functions here run only on the server (Next.js Server Components /
 * generateStaticParams / generateMetadata). Never import this in a
 * "use client" component.
 *
 * The shim URL is read from HC_API_URL (set in .env.local for dev,
 * environment variables in production).
 */

const API_URL = process.env.HC_API_URL;

if (!API_URL && process.env.NODE_ENV === "production") {
  throw new Error("HC_API_URL environment variable is not set.");
}

// ─── Types ────────────────────────────────────────────────────────────────────

/** Shape of a single row from publicWeb_getLandingPageData */
export interface KennelLandingData {
  // Core identity
  PublicKennelId: string;
  KennelName: string;
  KennelShortName: string;
  KennelUniqueShortName: string;
  KennelDescription: string | null;

  // Branding
  KennelLogo: string | null;
  FaviconUrl: string | null;
  BannerImage: string | null;
  WebsiteBackgroundImage: string | null;
  WebsiteTitleText: string | null;

  // HC6 theming (null until data migration from HC.Kennel runs)
  ThemeMode: "light" | "dark" | null;
  PrimaryColor: string | null;
  AccentColor: string | null;
  ScrollBlur: number | null;
  Tagline: string | null;
  WelcomeText: string | null;
  OgImageUrl: string | null;

  // SEO
  SeoTitle: string | null;
  SeoDescription: string | null;
  SeoStructuredDataJson: string | null;

  // Routing
  CustomDomain: string | null;
  WebsiteEnabled: boolean | null;

  // HC5 legacy colours (null until data migration)
  WebsiteBackgroundColor: string | null;
  MenuBackgroundColor: string | null;
  MenuTextColor: string | null;
  BodyTextColor: string | null;
  TitleTextColor: string | null;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Calls the PublicWebApi shim and returns the first result set as typed rows.
 * Returns null if the kennel was not found (shim returned 404).
 * Throws on network or server errors.
 */
async function callPublicWebApi<T>(
  queryType: string,
  params: Record<string, string>
): Promise<T[] | null> {
  const base = API_URL ?? "http://localhost:7071";
  const url = new URL(`${base}/api/PublicWebApi`);
  url.searchParams.set("queryType", queryType);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  const res = await fetch(url.toString(), {
    // Always read fresh data so DB edits are visible on the next refresh.
    cache: "no-store",
  });

  if (res.status === 404) return null;

  if (!res.ok) {
    throw new Error(
      `PublicWebApi error: ${res.status} ${res.statusText} (queryType=${queryType})`
    );
  }

  // Shim returns array of result sets: [[row, row, ...], [row, ...], ...]
  const body: T[][] = await res.json();
  return body[0] ?? [];
}

/**
 * Like callPublicWebApi but returns all rowsets as a raw array-of-arrays.
 * Used by SPs that return multiple rowsets (e.g. getEvents returns a count
 * rowset followed by the event rows).
 * Returns null on 404 (kennel not found). Throws on other errors.
 */
async function callPublicWebApiAllRowsets(
  queryType: string,
  params: Record<string, string>
): Promise<unknown[][] | null> {
  const base = API_URL ?? "http://localhost:7071";
  const url = new URL(`${base}/api/PublicWebApi`);
  url.searchParams.set("queryType", queryType);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  const res = await fetch(url.toString(), {
    // Always read fresh data so DB edits are visible on the next refresh.
    cache: "no-store",
  });

  if (res.status === 404) return null;

  if (!res.ok) {
    throw new Error(
      `PublicWebApi error: ${res.status} ${res.statusText} (queryType=${queryType})`
    );
  }

  return res.json();
}

// ─── Tag decoding ──────────────────────────────────────────────────────────────
//
// Tags are stored on HC.Event as three INT bitflag columns (Tags1, Tags2, Tags3).
// The bit encoding matches the RunTag Dart enum in kennel_page_new_enums.dart:
//   upper 32 bits of the Dart bitFlag = which column (1=Tags1, 2=Tags2)
//   lower 32 bits = the bit mask to AND against that column
//
// Decoding is done server-side here so client components receive string[].

type TagDef = { col: 1 | 2; mask: number; title: string };

const TAG_DEFS: TagDef[] = [
  // Theme
  { col: 1, mask: 0x00000001, title: "Normal Run" },
  { col: 1, mask: 0x00000002, title: "Red Dress Run" },
  { col: 2, mask: 0x00000004, title: "Family Hash" },
  { col: 1, mask: 0x00000004, title: "Full Moon Run" },
  { col: 1, mask: 0x00000008, title: "Harriette Run" },
  { col: 1, mask: 0x40000000, title: "AGM" },
  { col: 2, mask: 0x00000200, title: "Drinking Practice" },
  { col: 2, mask: 0x00020000, title: "Hangover Run" },
  // Restrictions
  { col: 1, mask: 0x00000010, title: "Men Only" },
  { col: 1, mask: 0x00000020, title: "Women Only" },
  { col: 1, mask: 0x00000040, title: "Kids Allowed" },
  { col: 1, mask: 0x00000080, title: "No Kids Allowed" },
  { col: 1, mask: 0x02000000, title: "Dog Friendly" },
  { col: 2, mask: 0x00000002, title: "No Dogs Allowed" },
  // What to bring
  { col: 1, mask: 0x10000000, title: "Bring Cash on Trail" },
  { col: 1, mask: 0x00000100, title: "Bring Flashlight" },
  { col: 2, mask: 0x00000008, title: "Bring Dry Clothes" },
  { col: 1, mask: 0x20000000, title: "Bag Drop Available" },
  { col: 2, mask: 0x00000100, title: "No Bag Drop Available" },
  { col: 2, mask: 0x00001000, title: "Bring Drinking Vessel" },
  { col: 2, mask: 0x00002000, title: "Bring a Chair" },
  // Run type
  { col: 1, mask: 0x00002000, title: "Pub Crawl" },
  { col: 2, mask: 0x00004000, title: "A-to-B Run" },
  { col: 2, mask: 0x00000800, title: "Short Walk / Old Farts Trail" },
  { col: 1, mask: 0x00000400, title: "Walker Trail" },
  { col: 2, mask: 0x00000010, title: "Short Trail" },
  { col: 1, mask: 0x00000800, title: "Medium Trail" },
  { col: 1, mask: 0x00001000, title: "Long Run Trail" },
  { col: 2, mask: 0x00000400, title: "Ballbreaker Trail" },
  { col: 1, mask: 0x00040000, title: "BASH / Bike Hash" },
  // Terrain
  { col: 1, mask: 0x00010000, title: "Shiggy Run" },
  { col: 1, mask: 0x00080000, title: "City Run" },
  { col: 1, mask: 0x00800000, title: "Steep Hills" },
  { col: 1, mask: 0x00400000, title: "Nighttime Run" },
  { col: 1, mask: 0x00008000, title: "Baby Jogger Friendly" },
  { col: 1, mask: 0x00000200, title: "Water on Trail" },
  { col: 2, mask: 0x00010000, title: "Swim Stop" },
  // Hares
  { col: 1, mask: 0x00100000, title: "Live Hare" },
  { col: 1, mask: 0x00200000, title: "Dead Hare" },
  { col: 1, mask: 0x04000000, title: "Pick-up Hash" },
  { col: 1, mask: 0x08000000, title: "Catch the Hare" },
  // Other
  { col: 1, mask: 0x00004000, title: "On After / After Party" },
  { col: 2, mask: 0x00008000, title: "Drink Stop" },
  { col: 1, mask: 0x00020000, title: "Accessible by Public Transport" },
  { col: 1, mask: 0x01000000, title: "Charity Event" },
  { col: 2, mask: 0x00000020, title: "Parking Available" },
  { col: 2, mask: 0x00000040, title: "No Parking Available" },
  { col: 2, mask: 0x00000080, title: "Camping Hash" },
  { col: 2, mask: 0x00000001, title: "Multi-day Event" },
];

function decodeTags(tags1: number, tags2: number, tags3: number): string[] {
  // tags3 reserved for future use — included in signature for completeness
  void tags3;
  return TAG_DEFS
    .filter(({ col, mask }) => col === 1 ? (tags1 & mask) !== 0 : (tags2 & mask) !== 0)
    .map(({ title }) => title);
}

// ─── Public API ───────────────────────────────────────────────────────────────

// ─── Song types ───────────────────────────────────────────────────────────────

/** Shape of a single row from publicWeb_getSongs */
export interface Song {
  id: string;
  SongName: string;
  TuneOf: string | null;
  BawdyRating: number | null;
  Lyrics: string | null;
  Notes: string | null;
  Actions: string | null;
  Variants: string | null;
  ImageUrl: string | null;
  AudioUrl: string | null;
  Rank: number | null;
  Tags: string | null;
}

/**
 * Fetches the songs assigned to a kennel by its PublicKennelId.
 * Returns an empty array when the kennel has no songs or is not found.
 */
export async function getSongs(publicKennelId: string): Promise<Song[]> {
  const rows = await callPublicWebApi<Song>("getSongs", { publicKennelId });
  return rows ?? [];
}

/**
 * Fetches a single song by its ID, scoped to the kennel.
 * Returns null when the song is not found or not assigned to this kennel.
 */
export async function getSong(
  publicKennelId: string,
  songId: string
): Promise<Song | null> {
  const rows = await callPublicWebApi<Song>("getSong", { publicKennelId, songId });
  if (!rows || rows.length === 0) return null;
  return rows[0];
}

// ─── getStats ─────────────────────────────────────────────────────────────────

/** Shape of a single member-stats row from publicWeb_getStats (Rowset 1). */
export interface KennelStatRow {
  Rank: number;
  DisplayName: string;
  TotalRuns: number;
  TotalHaring: number;
  YtdRuns: number;
  YtdHaring: number;
  RollingYearRuns: number;
  RollingYearHaring: number;
}

export interface GetStatsResult {
  /** Total hashers with a non-removed relationship to the kennel (from the Rowset 0 sentinel). */
  hasherCount: number;
  rows: KennelStatRow[];
}

/**
 * Fetches member run stats for a kennel by its PublicKennelId.
 * Returns null when the kennel does not exist or is not publicly visible.
 */
export async function getStats(publicKennelId: string): Promise<GetStatsResult | null> {
  const data = await callPublicWebApiAllRowsets("getStats", { publicKennelId });
  if (!data) return null;

  const [sentinelRows, statRows] = data as [
    Array<{ HasherCount: number }>,
    KennelStatRow[],
  ];

  return {
    hasherCount: sentinelRows?.[0]?.HasherCount ?? 0,
    rows: statRows ?? [],
  };
}

// ─── getGlobalCalendar ────────────────────────────────────────────────────────

/** Shape of a single row from publicWeb_getGlobalCalendar (Rowset 1). */
export interface GlobalCalendarRow {
  /** Local date of the event in YYYY-MM-DD form (DATE cast from EventStartDatetime). */
  EventDate: string;
  /** URL slug — used to build the kennel homepage link. */
  KennelSlug: string;
  KennelName: string;
  /** Logo URL or null. Caller must verify it starts with "https://" before rendering. */
  KennelLogo: string | null;
  /** CSS hex colour for the logo placeholder. May be null; fall back to a default. */
  PrimaryColor: string | null;
  /** Stable public GUID — safe to use as a React list key. */
  PublicKennelId: string;
  /**
   * EventNumber of the first event that day for this kennel (MIN when multiple).
   * Used to build the run detail URL. May be 0 for uncounted events — fall back
   * to the kennel homepage in that case.
   */
  EventNumber: number;
}

/**
 * Fetches upcoming runs across all kennels for a given date window.
 * Returns one entry per (date, kennel) — multiple events on the same day
 * for the same kennel are collapsed to a single row by the SP.
 *
 * Returns an empty array when there are no events in the window (not an error).
 */
export async function getGlobalCalendar(options: {
  fromDate: string;
  daysLimit?: number;
}): Promise<GlobalCalendarRow[]> {
  const params: Record<string, string> = { fromDate: options.fromDate };
  if (options.daysLimit !== undefined)
    params.daysLimit = String(options.daysLimit);

  // SP returns rowset 0 (sentinel) + rowset 1 (calendar rows). The sentinel
  // ensures the shim never emits 404 for an empty date window.
  const data = await callPublicWebApiAllRowsets("getGlobalCalendar", params);
  if (!data) return [];

  const [, calendarRows] = data as [unknown[], GlobalCalendarRow[]];
  return calendarRows ?? [];
}

/**
 * Fetches landing page data for a kennel by its unique short name (URL slug).
 * Returns null when the kennel does not exist or is not publicly visible.
 */
export async function getKennelLandingData(
  kennelUniqueShortName: string
): Promise<KennelLandingData | null> {
  const rows = await callPublicWebApi<KennelLandingData>(
    "getLandingPageData",
    { kennelUniqueShortName }
  );

  if (rows === null || rows.length === 0) return null;
  return rows[0];
}

// ─── getEvents ────────────────────────────────────────────────────────────────

/** Shape of a single event row from publicWeb_getEvents (Rowset 1). */
export interface RunEvent {
  PublicEventId: string;
  EventNumber: number;
  EventName: string;
  EventStartDatetime: string;
  EventEndDatetime: string | null;
  EventTypeName: string | null;
  EventPriceForMembers: number | null;
  EventPriceForNonMembers: number | null;
  EventCurrencyType: string | null;
  Hares: string | null;
  LocationOneLineDesc: string | null;
  LocationStreet: string | null;
  LocationCity: string | null;
  LocationPostCode: string | null;
  Latitude: number | null;
  Longitude: number | null;
  w3wJson: string | null;
  EventDescription: string | null;
  EventImage: string | null;
  EventUrl: string | null;
  IsCountedRun: number;
  /** Human-readable tag names decoded from the Tags1/Tags2/Tags3 bitflags. */
  tags: string[];
}

export interface GetEventsOptions {
  isFuture: boolean;
  /** Return up to this many events. May be combined with dateCutoff/daysOffset. */
  maxEvents?: number;
  /** Absolute far-boundary date (ISO 8601). Mutually exclusive with daysOffset. */
  dateCutoff?: string;
  /** Relative boundary: days from today. Always positive; direction from isFuture. */
  daysOffset?: number;
  /** When true, heavy text fields (EventDescription, EventUrl, w3wJson) are omitted. */
  summaryOnly?: boolean;
}

export interface GetEventsResult {
  /** Total events matching the filter before the maxEvents cap was applied. */
  totalMatchingEvents: number;
  events: RunEvent[];
}

// Raw shape of a Rowset-1 row before tag decoding
type RawRunEvent = Omit<RunEvent, "tags"> & {
  Tags1: number;
  Tags2: number;
  Tags3: number;
};

// ─── getGlobalRuns ────────────────────────────────────────────────────────────

/**
 * Shape of a single row from publicWeb_getGlobalRuns (Rowset 1).
 * Includes full kennel context so the detail panel needs no second API call.
 */
export interface GlobalRunRow {
  // Event identity
  PublicEventId: string;
  EventNumber: number;
  EventName: string;

  // Timing
  EventStartDatetime: string;
  EventEndDatetime: string | null;

  // Event type
  EventTypeName: string | null;

  // Fees
  EventPriceForMembers: number | null;
  EventPriceForNonMembers: number | null;
  EventCurrencyType: string | null;

  // People
  Hares: string | null;

  // Location
  LocationOneLineDesc: string | null;
  LocationStreet: string | null;
  LocationCity: string | null;
  LocationPostCode: string | null;
  LocationRegion: string | null;
  LocationCountry: string | null;

  Latitude: number | null;
  Longitude: number | null;
  w3wJson: string | null;

  // Content
  EventDescription: string | null;
  EventImage: string | null;
  EventUrl: string | null;

  // Tags (decoded from bitflags by getGlobalRuns())
  tags: string[];

  // Metadata
  IsCountedRun: number;

  // Kennel context
  KennelSlug: string;
  KennelShortName: string;
  KennelName: string;
  KennelLogo: string | null;
  PrimaryColor: string | null;
  PublicKennelId: string;
  /** Custom domain (e.g. 'www.cityhash.org'). NULL when kennel has none. */
  KennelWebsiteDomain: string | null;
  /** Continent name from HC.Country via Kennel.CountryId. NULL when kennel has no country set. */
  KennelContinent: string | null;
}

export interface GetGlobalRunsOptions {
  isFuture: boolean;
  /** Events per page (default 50, clamped 1–200 server-side). */
  pageSize?: number;
  /** Zero-based row offset for pagination (default 0). */
  offset?: number;
}

export interface GetGlobalRunsResult {
  /** Total events matching the isFuture filter before the pageSize cap. */
  totalMatchingEvents: number;
  runs: GlobalRunRow[];
}

// Raw shape before tag decoding
type RawGlobalRunRow = Omit<GlobalRunRow, "tags"> & {
  Tags1: number;
  Tags2: number;
  Tags3: number;
};

/**
 * Fetches individual runs across all kennels, sorted by date.
 * Returns the first page of future runs by default.
 */
export async function getGlobalRuns(
  options: GetGlobalRunsOptions
): Promise<GetGlobalRunsResult> {
  const params: Record<string, string> = {
    isFuture: options.isFuture ? "1" : "0",
  };
  if (options.pageSize !== undefined) params.pageSize = String(options.pageSize);
  if (options.offset   !== undefined) params.offset   = String(options.offset);

  const data = await callPublicWebApiAllRowsets("getGlobalRuns", params);
  if (!data) return { totalMatchingEvents: 0, runs: [] };

  const [headerRows, runRows] = data as [
    Array<{ TotalMatchingEvents: number }>,
    RawGlobalRunRow[],
  ];

  const totalMatchingEvents = headerRows?.[0]?.TotalMatchingEvents ?? 0;

  const runs: GlobalRunRow[] = (runRows ?? []).map((row) => {
    const { Tags1, Tags2, Tags3, ...rest } = row;
    return { ...rest, tags: decodeTags(Tags1, Tags2, Tags3) };
  });

  return { totalMatchingEvents, runs };
}

/**
 * Fetches upcoming or past events for a kennel by its PublicKennelId.
 * Returns null when the kennel does not exist or is not publicly visible.
 */
export async function getEvents(
  publicKennelId: string,
  options: GetEventsOptions
): Promise<GetEventsResult | null> {
  const params: Record<string, string> = {
    publicKennelId,
    isFuture: options.isFuture ? "1" : "0",
  };
  if (options.maxEvents !== undefined)
    params.maxEvents = String(options.maxEvents);
  if (options.dateCutoff !== undefined)
    params.dateCutoff = options.dateCutoff;
  if (options.daysOffset !== undefined)
    params.daysOffset = String(options.daysOffset);
  if (options.summaryOnly)
    params.summaryOnly = "1";

  const data = await callPublicWebApiAllRowsets("getEvents", params);
  if (!data) return null;

  const [headerRows, eventRows] = data as [
    Array<{ TotalMatchingEvents: number }>,
    RawRunEvent[],
  ];

  const totalMatchingEvents = headerRows?.[0]?.TotalMatchingEvents ?? 0;

  const events: RunEvent[] = (eventRows ?? []).map((row) => {
    const { Tags1, Tags2, Tags3, ...rest } = row;
    return { ...rest, tags: decodeTags(Tags1, Tags2, Tags3) };
  });

  return { totalMatchingEvents, events };
}
