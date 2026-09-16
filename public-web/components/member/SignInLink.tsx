"use client";

/**
 * The front door (James, 2026-09-16: "How do I log in now? A button on
 * hashruns.org?"). "Sign in" when there is no member cookie, "My hashing"
 * → /me/runs when there is. Rendered in the global tab bar and the kennel
 * sites' sticky nav; asks /api/member/me once on mount.
 */
import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { CircleUserRound } from "lucide-react";

export function SignInLink({ className, style }: { className?: string; style?: React.CSSProperties }) {
  const pathname = usePathname();
  const [state, setState] = useState<"unknown" | "out" | "in">("unknown");
  const [name, setName] = useState("");

  useEffect(() => {
    let cancelled = false;
    fetch("/api/member/me", { cache: "no-store" })
      .then((r) => r.json())
      .then((j: { signedIn?: boolean; hashName?: string }) => {
        if (cancelled) return;
        setState(j.signedIn ? "in" : "out");
        setName(j.hashName ?? "");
      })
      .catch(() => { if (!cancelled) setState("out"); });
    return () => { cancelled = true; };
  }, []);

  if (state === "unknown") return <span className={className} style={{ ...style, visibility: "hidden" }}>Sign in</span>;

  const href = state === "in" ? "/me/runs" : `/login?next=${encodeURIComponent(pathname === "/" ? "/me/runs" : pathname)}`;
  return (
    <Link href={href} className={className} style={style} title={state === "in" && name ? name : undefined}>
      <CircleUserRound className="h-4 w-4 shrink-0" />
      <span>{state === "in" ? "My hashing" : "Sign in"}</span>
    </Link>
  );
}
