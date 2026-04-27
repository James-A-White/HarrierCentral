import { NextRequest, NextResponse } from "next/server";
import { resolveKennelsByUuid } from "@/lib/api";

export async function GET(request: NextRequest) {
  const ids = request.nextUrl.searchParams.get("ids");
  if (!ids?.trim()) return NextResponse.json([]);

  // Allow only UUID characters (hex, hyphens) and comma separators.
  // The SP uses STRING_SPLIT on a parameter (no dynamic SQL), so this is a
  // belt-and-braces defence rather than a SQL injection guard.
  const sanitised = ids.replace(/[^a-fA-F0-9\-,]/g, "").slice(0, 2000);
  if (!sanitised) return NextResponse.json([]);

  try {
    const kennels = await resolveKennelsByUuid(sanitised);
    return NextResponse.json(
      kennels.map((k) => ({
        slug: k.KennelSlug,
        name: k.KennelName,
        customDomain: k.CustomDomain,
      }))
    );
  } catch {
    return NextResponse.json([]);
  }
}
