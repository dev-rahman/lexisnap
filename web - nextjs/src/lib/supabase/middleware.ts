import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

import { config } from "@/lib/config";

/**
 * Refreshes the Supabase session cookie on every request and enforces auth
 * gating — the Next.js equivalent of AuthMiddleware in the Flutter app:
 *   - signed-out users are kept out of authed routes (→ /login)
 *   - signed-in users are kept out of the auth flow (→ /home)
 */
const AUTH_ROUTES = ["/login", "/signup", "/forgot-password"];
const PUBLIC_ROUTES = ["/onboarding", "/auth/callback"];

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(config.supabaseUrl, config.supabaseKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value),
        );
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  // IMPORTANT: getUser() must be called to refresh the token.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { pathname } = request.nextUrl;
  const isAuthRoute = AUTH_ROUTES.some((r) => pathname.startsWith(r));
  const isPublic =
    PUBLIC_ROUTES.some((r) => pathname.startsWith(r)) || pathname === "/";

  if (!user && !isAuthRoute && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return NextResponse.redirect(url);
  }

  if (user && isAuthRoute) {
    const url = request.nextUrl.clone();
    url.pathname = "/home";
    return NextResponse.redirect(url);
  }

  return response;
}
