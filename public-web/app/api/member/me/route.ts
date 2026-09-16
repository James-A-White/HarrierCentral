import { NextRequest, NextResponse } from "next/server";
import { readMember } from "@/lib/member-session";

/** GET → { signedIn, hashName?, photo? } — never the credentials. */
export async function GET(req: NextRequest) {
  const s = readMember(req);
  if (!s) return NextResponse.json({ signedIn: false });
  return NextResponse.json({ signedIn: true, hashName: s.hashName || s.displayName, photo: s.photo });
}
