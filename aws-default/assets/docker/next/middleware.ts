import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Get frontend prefix from environment variable
const FRONTEND_PREFIX = process.env.NEXT_PUBLIC_FRONTEND_PREFIX || '/fe';

export function middleware(request: NextRequest) {
  const url = request.nextUrl.clone();
  
  // Case 1: URL starts with /fe/ (e.g., /fe/dashboard)
  // This happens if ALB didn't strip the prefix for some reason
  if (url.pathname.startsWith(`${FRONTEND_PREFIX}/`)) {
    url.pathname = url.pathname.replace(new RegExp(`^${FRONTEND_PREFIX}`), '');
    return NextResponse.rewrite(url);
  }
  
  // Case 2: URL is exactly /fe (without trailing slash)
  // This happens if ALB didn't strip the prefix for some reason
  if (url.pathname === FRONTEND_PREFIX) {
    url.pathname = '/';
    return NextResponse.rewrite(url);
  }
  
  // Case 3: All other paths are handled by Next.js normally
  // This is the most common case after ALB strips the /fe prefix
  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - api (API routes should not be processed by this middleware)
     */
    '/((?!_next/static|_next/image|favicon.ico|api).*)',
  ],
};

