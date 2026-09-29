import type { Metadata } from "next";
import { dmPreferenceOf, getBlockedHashers, getMyKennels } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { BlockedHashersView } from "@/components/member/BlockedHashersView";
import { DirectMessagePreferenceView } from "@/components/member/DirectMessagePreferenceView";

export const metadata: Metadata = { title: "Messages and blocking" };

/**
 * Who can reach this member: the direct-message preference (E9.F1.S18) and
 * everyone they have blocked, with the way to undo it (E9.F1.S16). A block
 * is set from a message's menu in any chat; this is the only place it is
 * listed and lifted.
 *
 * There is no getter for the preference: it is two bits of
 * HC.Hasher.Preferences, which publicWeb_getMyKennels already returns on
 * every row as HasherPreferences. A member with no kennel row at all shows
 * the default — friends only — which is also what every row holds until
 * somebody changes it.
 */
export default async function BlockedHashersPage() {
  const s = await requireMember();
  const [blocked, kennels] = await Promise.all([
    getBlockedHashers(s).catch(() => []),
    getMyKennels(s).catch(() => []),
  ]);
  const preference = dmPreferenceOf(kennels.find((k) => k.HasherPreferences != null)?.HasherPreferences);
  return (
    <div className="space-y-8">
      <DirectMessagePreferenceView initial={preference} />
      <BlockedHashersView initial={blocked} />
    </div>
  );
}
