import type { Metadata } from "next";
import { getBlockedHashers } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { BlockedHashersView } from "@/components/member/BlockedHashersView";

export const metadata: Metadata = { title: "Blocked hashers" };

/**
 * Everyone this member has blocked, and the way to undo it (E9.F1.S16).
 * A block is set from a message's menu in any chat; this is the only place
 * it is listed and lifted.
 */
export default async function BlockedHashersPage() {
  const s = await requireMember();
  const blocked = await getBlockedHashers(s).catch(() => []);
  return <BlockedHashersView initial={blocked} />;
}
