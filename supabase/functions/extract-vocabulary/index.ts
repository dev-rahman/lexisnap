// Supabase Edge Function: extract-vocabulary
//
// Takes OCR-scanned text from the LexiSnap app and asks Groq (running
// OpenAI's open-weight gpt-oss-120b) to pick out the vocabulary worth
// learning, classify each word's CEFR level (A1-C2), write one example
// sentence per word at that level, detect the text's source language, and
// suggest a deck name. The Groq API key lives here as a Supabase secret
// and is never shipped inside the app. Groq's free tier needs no card on
// file.
//
// Model note: originally used llama-3.3-70b-versatile, which Groq
// decommissioned for free/developer-tier accounts on 2026-08-16. Groq's
// own recommended replacement for that exact case is gpt-oss-120b - keep
// an eye on https://console.groq.com/docs/deprecations if this ever
// starts failing again.
//
// Groq's API is OpenAI-compatible, but its JSON mode only guarantees
// *valid* JSON, not a specific shape (unlike OpenAI's strict json_schema
// mode) - so the exact shape is spelled out in the prompt instead, and the
// result is defensively validated below before it's trusted.
//
// Auth: `verify_jwt` (Supabase's default) only proves the bearer token is a
// valid project JWT - and the public anon key is one - so it does NOT by itself
// keep anonymous traffic off this paid Groq call. The handler additionally
// requires a real signed-in user (see `authenticatedUserId`). Clients get the
// token for free via `functions.invoke` when a session exists.
//
// Deploy: supabase functions deploy extract-vocabulary
// Secret:  supabase secrets set GROQ_API_KEY=gsk_...

import { createClient } from "npm:@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
// Auto-injected into every Edge Function by Supabase.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const MAX_TEXT_LENGTH = 6000;

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
const CEFR_LEVELS = new Set(["A1", "A2", "B1", "B2", "C1", "C2"]);

// `uiLanguage` is the language the app's UI is in (e.g. "English"), so each
// word can be glossed AND defined in the language the user reads - the
// translation shown on the word-selection screen, and the dictionary-style
// definition on the card. Defaults to English when the client doesn't send it.
function buildSystemPrompt(uiLanguage?: string): string {
  const gloss = uiLanguage && uiLanguage.trim().length > 0
    ? uiLanguage.trim()
    : "English";
  return (
    "You are a vocabulary-extraction assistant for a language-learning " +
    "flashcard app. Given OCR-scanned text, identify 5-25 words genuinely " +
    "worth learning as vocabulary (skip trivial function words like " +
    "articles/pronouns unless the text is clearly about them). For each " +
    "word, classify its CEFR level (A1-C2) by how commonly it's learned, " +
    `write a short dictionary-style definition of the word in ${gloss} ` +
    "(the language the learner reads, NOT the word's own language) so they " +
    "understand its meaning and usage, write exactly one natural example " +
    "sentence that uses the word and is written at that same CEFR level " +
    "(a B1 word gets a B1-appropriate sentence, not simplified or " +
    `overcomplicated), and translate the word into ${gloss}. ` +
    "Deduplicate case-insensitively. Tag EACH word with its own ISO 639-1 " +
    "language code, because a scan can mix languages (for example a " +
    "foreign word written next to its native-language translation). Also " +
    "detect the overall/dominant source language of the scanned text (as " +
    "an ISO 639-1 code and its English display name), and suggest a " +
    'short, thematic name for a flashcard deck made from this text (e.g. ' +
    '"Restaurant menu vocabulary", not just "French words"). Respond with ' +
    "ONLY a JSON object of this exact shape, no other text: " +
    '{"language_code": string, "language_name": string, ' +
    '"suggested_deck_name": string, "words": [{"word": string, ' +
    '"level": "A1"|"A2"|"B1"|"B2"|"C1"|"C2", "word_description": string, ' +
    '"example_sentence": string, "language_code": string, ' +
    '"translation": string}, ...]}'
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

  let text: unknown;
  let uiLanguage: unknown;
  try {
    const body = await req.json();
    text = body?.text;
    uiLanguage = body?.ui_language;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (typeof text !== "string" || text.trim().length === 0) {
    return jsonResponse({ error: "\"text\" is required" }, 400);
  }

  const truncatedText = text.slice(0, MAX_TEXT_LENGTH);
  const systemPrompt = buildSystemPrompt(
    typeof uiLanguage === "string" ? uiLanguage : undefined,
  );

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
            { role: "system", content: systemPrompt },
            { role: "user", content: truncatedText },
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

    const words = validateWords(parsed);
    if (words.length === 0) {
      return jsonResponse({ error: "No valid words in AI response" }, 502);
    }

    const languageCode = (parsed as { language_code?: unknown })
      ?.language_code;
    const languageName = (parsed as { language_name?: unknown })
      ?.language_name;
    const suggestedDeckName = (parsed as { suggested_deck_name?: unknown })
      ?.suggested_deck_name;

    if (
      typeof languageCode !== "string" ||
      languageCode.trim().length === 0 ||
      typeof languageName !== "string" ||
      languageName.trim().length === 0 ||
      typeof suggestedDeckName !== "string" ||
      suggestedDeckName.trim().length === 0
    ) {
      return jsonResponse(
        { error: "AI response missing language/deck-name fields" },
        502,
      );
    }

    return jsonResponse(
      {
        words,
        language_code: languageCode,
        language_name: languageName,
        suggested_deck_name: suggestedDeckName,
      },
      200,
    );
  } catch (error) {
    console.error("extract-vocabulary failed", error);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});

/// Groq's JSON mode guarantees valid JSON, not a specific shape, so every
/// entry is checked before it's trusted - malformed entries are dropped
/// rather than passed through or allowed to crash the client.
function validateWords(parsed: unknown): Array<{
  word: string;
  level: string;
  word_description: string;
  example_sentence: string;
  language_code: string | null;
  translation: string;
}> {
  const rawWords = (parsed as { words?: unknown })?.words;
  if (!Array.isArray(rawWords)) return [];

  // The scan's dominant language, used when a word doesn't carry its own -
  // so a word is never dropped just for a missing per-word language.
  const overall = (parsed as { language_code?: unknown })?.language_code;
  const fallbackLanguage =
    typeof overall === "string" && overall.trim().length > 0
      ? overall.trim()
      : null;

  const result: Array<{
    word: string;
    level: string;
    word_description: string;
    example_sentence: string;
    language_code: string | null;
    translation: string;
  }> = [];

  for (const item of rawWords) {
    const word = (item as { word?: unknown })?.word;
    const level = (item as { level?: unknown })?.level;
    const wordDescription = (item as { word_description?: unknown })
      ?.word_description;
    const exampleSentence = (item as { example_sentence?: unknown })
      ?.example_sentence;
    const wordLanguage = (item as { language_code?: unknown })?.language_code;
    const translation = (item as { translation?: unknown })?.translation;

    if (
      typeof word === "string" &&
      word.trim().length > 0 &&
      typeof level === "string" &&
      CEFR_LEVELS.has(level) &&
      typeof wordDescription === "string" &&
      wordDescription.trim().length > 0 &&
      typeof exampleSentence === "string" &&
      exampleSentence.trim().length > 0
    ) {
      result.push({
        word,
        level,
        word_description: wordDescription,
        example_sentence: exampleSentence,
        language_code:
          typeof wordLanguage === "string" && wordLanguage.trim().length > 0
            ? wordLanguage.trim().toLowerCase()
            : fallbackLanguage,
        // Gloss into the app's UI language; don't drop a word if it's absent.
        translation: typeof translation === "string" ? translation.trim() : "",
      });
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
