import { NextRequest, NextResponse } from "next/server";
import { getMyRunsFor } from "@/lib/member-api";
import { readMember } from "@/lib/member-session";
import { bad } from "@/lib/member-routes";

/** GET ?kennel=<publicKennelId>|country=<countryId>&all=0|1 → the drill-down rows (the app's My Runs / All Runs). */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  const q = req.nextUrl.searchParams;
  const kennel = (q.get("kennel") ?? "").toLowerCase();
  const country = (q.get("country") ?? "").toLowerCase();
  const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
  if (!isId(kennel) && !isId(country)) return bad("Bad request.");
  try {
    const r = await getMyRunsFor(s, { publicKennelId: isId(kennel) ? kennel : undefined, countryId: isId(country) ? country : undefined, allRuns: q.get("all") === "1" });
    return NextResponse.json(r ?? { header: null, runs: [] });
  } catch (e) {
    console.error("history-runs:", e);
    return bad("Couldn't load the runs just now.", 502);
  }
}
