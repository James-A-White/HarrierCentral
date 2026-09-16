import type { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { MEMBER_COOKIE, openSession } from "@/lib/member-session";
import { MemberTabBar } from "@/components/member/MemberTabBar";

export const metadata: Metadata = {
  title: { default: "My hashing | hashruns.org", template: "%s | hashruns.org" },
  robots: { index: false },
};

// Personal pages: rendered per request under the cookie, never cached.
export const dynamic = "force-dynamic";

/**
 * The member area — the app's five tabs for people using the browser as
 * their device (E9.F7). Every page under /me is server-rendered with the
 * member's own data; a visitor without a cookie is sent to sign in and
 * brought back.
 */
export default async function MemberLayout({ children }: { children: React.ReactNode }) {
  const jar = await cookies();
  const session = openSession(jar.get(MEMBER_COOKIE)?.value);
  if (!session) redirect("/login?next=/me/runs");

  return (
    <html lang="en" className="dark">
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        <div className="fixed inset-0 -z-10 bg-repeat" style={{ backgroundImage: "url(/images/jungle_background.jpg)", backgroundSize: "1024px 1024px" }} />
        <div className="fixed inset-0 -z-[9]" style={{ backgroundColor: "#000000", opacity: 0.55 }} />
        <MemberTabBar hashName={session.hashName || session.displayName || "Hasher"} />
        <main className="mx-auto w-full max-w-4xl px-3 pb-28 pt-[60px] sm:pb-16 sm:pt-[64px] md:px-6">{children}</main>
      </body>
    </html>
  );
}
