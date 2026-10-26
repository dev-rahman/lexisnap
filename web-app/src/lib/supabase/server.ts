import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

import { config } from "@/lib/config";

/**
 * Server-side Supabase client for Server Components and Route Handlers.
 * Reads/writes the session cookie so SSR knows who is signed in.
 */
export async function getSupabaseServerClient() {
  const cookieStore = await cookies();

  return createServerClient(config.supabaseUrl, config.supabaseKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        } catch {
          // Called from a Server Component — safe to ignore; the middleware
          // refreshes the session cookie on navigation.
        }
      },
    },
  });
}
