import { NextRequest, NextResponse } from "next/server";
import { createMember, emailInviteCode } from "@/lib/member-api";
import { bad, ipOf, isEmail, jsonBody, limited } from "@/lib/member-routes";

/**
 * POST { email, hashName, firstName?, lastName?, slug } → { sent: true }
 * Creates the hasher (following the kennel whose link was tapped) and sends
 * the code. The email is only PROVEN when the code comes back through
 * verify-code — the same order the app's own signup uses.
 */
export async function POST(req: NextRequest) {
  const body = await jsonBody<{ email?: string; hashName?: string; firstName?: string; lastName?: string; slug?: string }>(req);
  const email = (body?.email ?? "").trim().toLowerCase();
  const hashName = (body?.hashName ?? "").trim().slice(0, 100);
  const slug = (body?.slug ?? "").trim().toLowerCase();
  if (!isEmail(email)) return bad("Please enter a valid email address.");
  if (hashName.length < 2) return bad("Please tell us your hash name (or the name you go by).");
  if (!slug) return bad("Missing kennel.");
  if (limited(`signup:ip:${ipOf(req)}`, 5, 60 * 60_000)) return bad("Too many sign-ups from here. Please try later.", 429);

  try {
    const created = await createMember({
      email, hashName,
      firstName: (body?.firstName ?? "").trim().slice(0, 100) || undefined,
      lastName: (body?.lastName ?? "").trim().slice(0, 100) || undefined,
      kennelSlug: slug,
    });
    if (!created.ok && !created.duplicate) return bad(created.message, 502);
    // Duplicate means the address already has an account — sending the code
    // is exactly right for them too.
    const known = await emailInviteCode(email);
    return NextResponse.json({ sent: known, known, created: created.ok });
  } catch (e) {
    console.error("signup:", e);
    return bad("We couldn't create your account just now. Please try again.", 502);
  }
}
