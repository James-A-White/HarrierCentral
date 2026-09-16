import { NextResponse } from "next/server";
import { clearMemberCookie } from "@/lib/member-session";

/** POST → clears the cookie. The device row stays; an admin can remove it. */
export async function POST() {
  const res = NextResponse.json({ ok: true });
  clearMemberCookie(res);
  return res;
}
