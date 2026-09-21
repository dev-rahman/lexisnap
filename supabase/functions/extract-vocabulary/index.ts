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
// `verify_jwt` is left at Supabase's default (true), so only requests
// carrying a signed-in LexiSnap user's auth token reach this code - the
// Flutter client gets this for free via `functions.invoke`, matching the
// app's `AuthMiddleware(requiresAuth: true)` on the scan route.
//
// Deploy: supabase functions deploy extract-vocabulary
// Secret:  supabase secrets set GROQ_API_KEY=gsk_...

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const MAX_TEXT_LENGTH = 6000;
const CEFR_LEVELS = new Set(["A1", "A2", "B1", "B2", "C1", "C2"]);

const SYSTEM_PROMPT =
  "You are a vocabulary-extraction assistant for a language-learning " +
  "flashcard app. Given OCR-scanned text, identify 5-25 words genuinely " +
  "worth learning as vocabulary (skip trivial function words like " +
  "articles/pronouns unless the text is clearly about them). For each " +
  "word, classify its CEFR level (A1-C2) by how commonly it's learned, " +
  "write a short dictionary-style definition of the word (in the same " +
  "language as the word itself), and write exactly one natural example " +
  "sentence that uses the word and is written at that same CEFR level - " +
  "a B1 word gets a B1-appropriate sentence, not simplified or " +
  "overcomplicated. Deduplicate case-insensitively. Also detect the " +
  "source language of the scanned text (as an ISO 639-1 code and its " +
  "English display name), and suggest a short, thematic name for a " +
  'flashcard deck made from this text (e.g. "Restaurant menu ' +
  'vocabulary", not just "French words"). Respond with ONLY a JSON ' +
  "object of this exact shape, no other text: " +
  '{"language_code": string, "language_name": string, ' +
  '"suggested_deck_name": string, "words": [{"word": string, ' +
  '"level": "A1"|"A2"|"B1"|"B2"|"C1"|"C2", "word_description": string, ' +
  '"example_sentence": string}, ...]}';

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!GROQ_API_KEY) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  let text: unknown;
  try {
    const body = await req.json();
    text = body?.text;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  if (typeof text !== "string" || text.trim().length === 0) {
    return jsonResponse({ error: "\"text\" is required" }, 400);
  }

  const truncatedText = text.slice(0, MAX_TEXT_LENGTH);

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
            { role: "system", content: SYSTEM_PROMPT },
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
}> {
  const rawWords = (parsed as { words?: unknown })?.words;
  if (!Array.isArray(rawWords)) return [];

  const result: Array<{
    word: string;
    level: string;
    word_description: string;
    example_sentence: string;
  }> = [];

  for (const item of rawWords) {
    const word = (item as { word?: unknown })?.word;
    const level = (item as { level?: unknown })?.level;
    const wordDescription = (item as { word_description?: unknown })
      ?.word_description;
    const exampleSentence = (item as { example_sentence?: unknown })
      ?.example_sentence;

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
