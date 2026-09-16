import type { Metadata } from "next";
import { getMyKennels } from "@/lib/member-api";
import { requireMember } from "@/lib/member-server";
import { MyKennels } from "@/components/member/MyKennels";

export const metadata: Metadata = { title: "My kennels" };

export default async function MyKennelsPage() {
  const s = await requireMember();
  const kennels = await getMyKennels(s).catch(() => []);
  return <MyKennels initialKennels={kennels} />;
}
