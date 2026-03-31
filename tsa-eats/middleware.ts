import { NextRequest, NextResponse } from 'next/server';

const PUBLIC_PATHS = [
  '/register',
  '/register/verify',
  '/admin/login',
  '/api/auth/',
  '/api/admin/login',
  '/api/restaurants',
  '/_next/',
  '/favicon.ico',
];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const host = req.headers.get('host') ?? '';

  // --- Subdomain routing ---

  if (host === 'admin.tsaeats.org') {
    // /login on the admin subdomain maps to /admin/login (public)
    if (pathname === '/login') {
      const url = req.nextUrl.clone();
      url.pathname = '/admin/login';
      return NextResponse.rewrite(url);
    }
    const adminCookie = req.cookies.get('tsa_admin')?.value;
    if (!adminCookie) {
      return NextResponse.redirect(new URL('https://admin.tsaeats.org/login', req.url));
    }
    // API routes: pass through without path rewrite — they are already at the correct path
    if (pathname.startsWith('/api/')) {
      return NextResponse.next();
    }
    // Page routes: rewrite to /admin prefix, but don't double-rewrite paths
    // that already start with /admin (e.g. post-login router.push('/admin'))
    const url = req.nextUrl.clone();
    url.pathname = pathname.startsWith('/admin') ? pathname : `/admin${pathname === '/' ? '' : pathname}`;
    return NextResponse.rewrite(url);
  }

  if (host === 'signup.tsaeats.org') {
    // Redirect to the canonical domain — the multi-step registration flow
    // (register → verify → home) must run on tsaeats.org to work correctly.
    const qs = req.nextUrl.search;
    return NextResponse.redirect(new URL(`https://tsaeats.org/register${qs}`), 302);
  }

  if (host === 'restaurant.tsaeats.org') {
    // Placeholder until restaurant routes are built
    return NextResponse.redirect(new URL('https://tsaeats.org', req.url));
  }

  // --- Path-based routing for tsaeats.org ---

  // Always allow public paths
  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // Protect /admin routes (except /admin/login handled above)
  if (pathname.startsWith('/admin') || pathname.startsWith('/api/admin')) {
    const adminCookie = req.cookies.get('tsa_admin')?.value;
    if (!adminCookie) {
      return NextResponse.redirect(new URL('/admin/login', req.url));
    }
    // Full signature verification happens in the route/page — middleware
    // just checks cookie presence to avoid a DB round-trip on every request.
    return NextResponse.next();
  }

  // Protect worker routes
  const sessionCookie = req.cookies.get('tsa_session')?.value;
  if (!sessionCookie) {
    return NextResponse.redirect(new URL('/register', req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
