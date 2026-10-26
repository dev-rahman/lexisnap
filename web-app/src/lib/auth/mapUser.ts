import type { User } from "@supabase/supabase-js";

import type { AppUser } from "@/lib/data/models";

// Port of SupabaseAuthService._mapUser. The user's own uploaded photo lives
// under `photo_url`, not `avatar_url`, because Supabase overwrites avatar_url
// from Google on every sign-in.
const PHOTO_URL_KEY = "photo_url";

export function mapUser(user: User | null): AppUser | null {
  if (!user) return null;
  const metadata = (user.user_metadata ?? {}) as Record<string, unknown>;
  const app = (user.app_metadata ?? {}) as Record<string, unknown>;
  const ownPhoto = metadata[PHOTO_URL_KEY] as string | undefined;
  const providers = app.providers;

  return {
    id: user.id,
    email: user.email ?? null,
    fullName:
      (metadata.full_name as string | undefined) ??
      (metadata.name as string | undefined) ??
      null,
    avatarUrl:
      ownPhoto ??
      (metadata.avatar_url as string | undefined) ??
      (metadata.picture as string | undefined) ??
      null,
    hasOwnPhoto: ownPhoto != null,
    hasPassword: Array.isArray(providers)
      ? providers.includes("email")
      : app.provider === "email",
    emailConfirmed: user.email_confirmed_at != null,
  };
}
