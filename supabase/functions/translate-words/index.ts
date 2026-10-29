// Supabase Edge Function: translate-words
//
// Takes a list of words (already picked out by extract-vocabulary and
// selected by the user) and asks Groq (gpt-oss-120b) for a natural,
// dictionary-appropriate translation of each into the requested target
// language. The Groq API key lives here as a Supabase secret and is never
// shipped inside the app.
//
// Auth: `verify_jwt` (Supabase's default) only proves the bearer token is a
// valid project JWT - and the public anon key is one - so it does NOT by itself
// keep anonymous traffic off this paid Groq call. The handler additionally
// requires a real signed-in user (see `authenticatedUserId`). Clients get the
// token for free via `functions.invoke` when a session exists.
//
// Deploy: supabase functions deploy translate-words
// Secret:  supabase secrets set GROQ_API_KEY=gsk_... (shared with extract-vocabulary)

import { createClient } from "npm:@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
// Auto-injected into every Edge Function by Supabase.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const MAX_WORDS = 100;

// Require a *real signed-in user*, not merely a valid project JWT. `verify_jwt`
// only proves the bearer token is signed by this project - and the public anon
// key (shipped in every client bundle) is such a token - so it alone does NOT
// keep anonymous traffic out. We validate the token against Supabase Auth and
// insist on an actual user, so this metered, paid Groq call can't be driven by
// anyone who copies the public anon key out of the app. Returns the user id, or
// null when the caller isn't an authenticated user.
async function authenticatedUserId(req: Request): Promise<string | null> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token || !SUPABASE_URL || !SUPABASE_ANON_KEY) return null;
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user || data.user.role !== "authenticated") return null;
  return data.user.id;
}

function buildSystemPrompt(targetLanguage: string, sourceLanguage?: string): string {
  const sourceHint = sourceLanguage
    ? `The words are in ${sourceLanguage}. `
    : "";
  return (
    "You are a translation assistant for a language-learning flashcard " +
    `app. ${sourceHint}Translate each given word into ${targetLanguage}, ` +
    "using the single most natural, dictionary-appropriate translation " +
    "(the word's base/dictionary form, not a full sentence). Respond " +
    "with ONLY a JSON object of this exact shape, no other text: " +
    '{"translations": [{"word": string, "translation": string}, ...]} - ' +
    "one entry per input word, in the same order, using the exact same " +
    '"word" spelling as given.'
  );
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!GROQ_API_KEY) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  // Gate the paid Groq call behind a real signed-in user (see note above).
  const userId = await authenticatedUserId(req);
  if (!userId) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let words: unknown;
  let sourceLanguage: unknown;
  let targetLanguage: unknown;
  try {
    const body = await req.json();
    words = body?.words;
    sourceLanguage = body?.source_language;
    targetLanguage = body?.target_language;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (
    !Array.isArray(words) ||
    words.length === 0 ||
    !words.every((word) => typeof word === "string" && word.trim().length > 0)
  ) {
    return jsonResponse({ error: "\"words\" must be a non-empty string array" }, 400);
  }
  if (typeof targetLanguage !== "string" || targetLanguage.trim().length === 0) {
    return jsonResponse({ error: "\"target_language\" is required" }, 400);
  }
  if (sourceLanguage !== undefined && typeof sourceLanguage !== "string") {
    return jsonResponse({ error: "\"source_language\" must be a string" }, 400);
  }

  const truncatedWords = words.slice(0, MAX_WORDS) as string[];

  try {
    const groqResponse = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: "openai/gpt-oss-120b",
          messages: [
            {
              role: "system",
              content: buildSystemPrompt(
                targetLanguage,
                sourceLanguage as string | undefined,
              ),
            },
            { role: "user", content: JSON.stringify(truncatedWords) },
          ],
          response_format: { type: "json_object" },
        }),
      },
    );

    if (!groqResponse.ok) {
      const errorBody = await groqResponse.text();
      console.error("Groq error", groqResponse.status, errorBody);
      return jsonResponse({ error: "Upstream AI request failed" }, 502);
    }

    const completion = await groqResponse.json();
    const content = completion.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      return jsonResponse({ error: "Malformed AI response" }, 502);
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      return jsonResponse({ error: "AI response was not valid JSON" }, 502);
    }

    const translations = validateTranslations(parsed);
    if (translations.length === 0) {
      return jsonResponse({ error: "No valid translations in AI response" }, 502);
    }

    return jsonResponse({ translations }, 200);
  } catch (error) {
    console.error("translate-words failed", error);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});

/// Groq's JSON mode guarantees valid JSON, not a specific shape, so every
/// entry is checked before it's trusted - malformed entries are dropped
/// rather than passed through or allowed to crash the client.
function validateTranslations(
  parsed: unknown,
): Array<{ word: string; translation: string }> {
  const rawTranslations = (parsed as { translations?: unknown })
    ?.translations;
  if (!Array.isArray(rawTranslations)) return [];

  const result: Array<{ word: string; translation: string }> = [];

  for (const item of rawTranslations) {
    const word = (item as { word?: unknown })?.word;
    const translation = (item as { translation?: unknown })?.translation;

    if (
      typeof word === "string" &&
      word.trim().length > 0 &&
      typeof translation === "string" &&
      translation.trim().length > 0
    ) {
      result.push({ word, translation });
    }
  }

  return result;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
