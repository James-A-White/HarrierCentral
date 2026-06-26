import { getKennelLandingData, getEvents, type KennelLandingData, type RunEvent } from "@/lib/api";

/** A run number is a positive integer; anything else is a custom page slug. */
export function isNumeric(s: string): boolean {
  return /^\d+$/.test(s);
}

/**
 * Resolves a kennel slug + run number to the kennel landing data and the matching
 * event. Returns `[null, null]` when the kennel doesn't exist, and `[kennel, null]`
 * when the kennel exists but no event matches the run number. Shared by the run
 * detail page and the PackTrack full-screen page.
 */
export async function resolveKennelAndEvent(
  slug: string,
  runNumber: string,
): Promise<[KennelLandingData | null, RunEvent | null]> {
  const kennelData = await getKennelLandingData(slug);
  if (!kennelData) return [null, null];

  const num = parseInt(runNumber, 10);
  if (isNaN(num)) return [kennelData, null];

  const [futureResult, pastResult] = await Promise.all([
    getEvents(kennelData.PublicKennelId, { isFuture: true,  daysOffset: 365 }),
    getEvents(kennelData.PublicKennelId, { isFuture: false, daysOffset: 730 }),
  ]);

  const allEvents = [
    ...(futureResult?.events ?? []),
    ...(pastResult?.events  ?? []),
  ];

  const event = allEvents.find((e) => e.EventNumber === num) ?? null;
  return [kennelData, event];
}
