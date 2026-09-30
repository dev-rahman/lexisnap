// Supabase Edge Function: delete-account
//
// Permanently deletes the calling user. Their profile photos are removed
// from Storage first; deleting the auth user then cascades to decks,
// flashcards and example sentences through those tables'
// `on delete cascade` foreign keys, so nothing of the account is left.
//
// This has to run server-side: deleting a user takes the service role key,
// which must never ship inside the app. Supabase provides SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY to every Edge Function automatically.
//
// `verify_jwt` is left at Supabase's default (true), so only requests
// carrying a signed-in user's token reach this code - and the token is
// what decides whose account goes, so no one can name another user's id.
//
// Deploy: supabase functions deploy delete-account

import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const PHOTO_BUCKET = "avatars";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) {
    return jsonResponse({ error: "Not signed in" }, 401);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  const user = userData?.user;
  if (userError || !user) {
    return jsonResponse({ error: "Not signed in" }, 401);
  }

  // Photos first: once the user row is gone, nothing ties these files to
  // anyone, so a failure after that point would leave them behind forever.
  const photos = admin.storage.from(PHOTO_BUCKET);
  const { data: files, error: listError } = await photos.list(user.id);
  if (listError) {
    return jsonResponse({ error: "Couldn't remove your profile photo" }, 500);
  }
  if (files.length > 0) {
    const { error: removeError } = await photos.remove(
      files.map((file) => `${user.id}/${file.name}`),
    );
    if (removeError) {
      return jsonResponse({ error: "Couldn't remove your profile photo" }, 500);
    }
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) {
    return jsonResponse({ error: "Couldn't delete your account" }, 500);
  }

  return jsonResponse({ deleted: true }, 200);
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
