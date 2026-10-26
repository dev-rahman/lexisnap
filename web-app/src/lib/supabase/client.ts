"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

import { config } from "@/lib/config";

/**
 * Browser-side Supabase client. A singleton so the whole app shares one
 * auth/session instance (and RTK Query, services, and components all talk to
 * the same client).
 */
let browserClient: SupabaseClient | null = null;

export function getSupabaseBrowserClient(): SupabaseClient {
  if (!browserClient) {
    browserClient = createBrowserClient(config.supabaseUrl, config.supabaseKey);
  }
  return browserClient;
}
