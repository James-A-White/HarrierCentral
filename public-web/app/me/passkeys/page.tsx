import type { Metadata } from "next";
import { listDevices } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { PasskeysView } from "@/components/member/PasskeysView";

export const metadata: Metadata = { title: "Devices" };

/**
 * Everything that can reach this account, and the two ways to take that away:
 * sign a device out, or remove its passkey (E9.F7.S18, E9.F7.S19).
 *
 * Until these existed a passkey could be created and never removed, and a
 * device could never be signed out at all — a hasher who lost a phone had no
 * way to revoke anything.
 */
export default async function MyPasskeysPage() {
  const s = await requireMember();
  const devices = await listDevices(s).catch(() => []);
  return <PasskeysView initial={devices} />;
}
