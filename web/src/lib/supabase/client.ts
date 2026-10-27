import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { config } from "@/lib/config";

/**
 * Single browser-side Supabase client for the whole SPA. `persistSession`
 * keeps the session in localStorage across reloads; `detectSessionInUrl`
 * lets the OAuth redirect (/auth/callback) finish and store the session.
 */
let browserClient: SupabaseClient | null = null;

export function getSupabaseBrowserClient(): SupabaseClient {
  if (!browserClient) {
    browserClient = createClient(config.supabaseUrl, config.supabaseKey, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    });
  }
  return browserClient;
}
