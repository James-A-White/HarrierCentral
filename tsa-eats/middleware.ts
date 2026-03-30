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
