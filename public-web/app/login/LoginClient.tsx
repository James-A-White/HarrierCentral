"use client";

import { useRouter } from "next/navigation";
import { MemberSignIn } from "@/components/member/MemberSignIn";

export function LoginClient({ next, slug }: { next: string; slug: string }) {
  const router = useRouter();
  return (
    <MemberSignIn
      slug={slug}
      kennelName="Harrier Central"
      onSignedIn={() => router.replace(next)}
    />
  );
}
