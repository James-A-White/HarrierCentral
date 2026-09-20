import type { Metadata } from "next";
import { listPasskeys } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { PasskeysView } from "@/components/member/PasskeysView";

export const metadata: Metadata = { title: "Passkeys" };

/**
 * Manage the passkeys on this account (E9.F7.S18). Until this page existed a
 * passkey could be created and never removed — a hasher who lost a phone had
 * no way to revoke it and no way to see what was registered.
 */
export default async function MyPasskeysPage() {
  const s = await requireMember();
  const passkeys = await listPasskeys(s).catch(() => []);
  return <PasskeysView initial={passkeys} />;
}
