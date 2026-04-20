import { type NextRequest, NextResponse } from "next/server";

// Hosts that belong to the platform — no custom-domain resolution needed.
const SYSTEM_HOSTS = ["hashruns.org", "harriercentral.com"];

function isSystemHost(hostname: string) {
  return SYSTEM_HOSTS.some(
    (h) => hostname === h || hostname.endsWith(`.${h}`)
  );
}

// In-process cache — persists across requests on self-hosted Node.js.
// Maps hostname → slug (or null when the domain isn't registered).
const slugCache = new Map<string, string | null>();

async function resolveCustomDomain(hostname: string): Promise<string | null> {
  if (slugCache.has(hostname)) return slugCache.get(hostname) ?? null;

  const apiUrl = process.env.HC_API_URL;
  if (!apiUrl) return null;

  try {
    const res = await fetch(
      `${apiUrl}/api/PublicWebApi?queryType=resolveCustomDomain&customDomain=${encodeURIComponent(hostname)}`
    );
    // Shim returns 404 when the SP returns zero rows.
    const slug: string | null = res.ok
      ? ((await res.json())?.[0]?.[0]?.KennelSlug ?? null)
      : null;
    slugCache.set(hostname, slug);
    return slug;
  } catch {
    // Don't cache transient errors — let the next request retry.
    return null;
  }
}

export async function middleware(request: NextRequest) {
  const hostname = (request.headers.get("host") ?? "").split(":")[0];

  if (!hostname || isSystemHost(hostname)) return NextResponse.next();

  const slug = await resolveCustomDomain(hostname);
  if (!slug) return NextResponse.next();

  const pathname = request.nextUrl.pathname;

  // Don't double-prefix: client-side <Link> components built before
  // custom-domain awareness already include the slug (e.g. /lh3/about).
  // Pass those through unchanged so they still resolve correctly.
  if (pathname === `/${slug}` || pathname.startsWith(`/${slug}/`)) {
    return NextResponse.next();
  }

  // Rewrite: decisionhall.com/about  →  internal /lh3/about
  //          decisionhall.com/       →  internal /lh3
  const rewritePath =
    pathname === "/" ? `/${slug}` : `/${slug}${pathname}`;

  // Forward the resolved slug and original domain as request headers so
  // server components can use them for canonical URLs and link construction.
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-kennel-slug", slug);
  requestHeaders.set("x-custom-domain", hostname);

  return NextResponse.rewrite(new URL(rewritePath, request.url), {
    request: { headers: requestHeaders },
  });
}

export const config = {
  // Skip Next.js internals and API routes — only intercept page requests.
  matcher: ["/((?!api/|_next/static/|_next/image/|favicon\\.ico).*)"],
};
