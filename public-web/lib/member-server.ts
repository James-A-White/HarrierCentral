/** Read the member session inside a server component. */
import { cookies } from "next/headers";
import { MEMBER_COOKIE, openSession, type MemberSession } from "@/lib/member-session";

export async function requireMember(): Promise<MemberSession> {
  const jar = await cookies();
  const s = openSession(jar.get(MEMBER_COOKIE)?.value);
  if (!s) throw new Error("no member session"); // the layout has already redirected
  return s;
}
