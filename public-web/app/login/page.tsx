import type { Metadata } from "next";
import { LoginClient } from "./LoginClient";

export const metadata: Metadata = {
  title: "Sign in | hashruns.org",
  robots: { index: false },
};

/**
 * /login — a standalone sign-in, and the landing for a QR the phone's camera
 * read WITHOUT the app installed: /login/UWP:<code> falls through to here
 * (the [scan] segment is ignored on the web; only the app reads it), so the
 * person still gets a way in.
 */
export default async function LoginPage({ searchParams }: { searchParams: Promise<{ next?: string; slug?: string }> }) {
  const { next, slug } = await searchParams;
  const safeNext = next && next.startsWith("/") && !next.startsWith("//") ? next : "/";
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-zinc-950 text-zinc-100 antialiased">
        <main className="flex min-h-screen items-center justify-center p-4">
          <LoginClient next={safeNext} slug={slug ?? ""} />
        </main>
      </body>
    </html>
  );
}
