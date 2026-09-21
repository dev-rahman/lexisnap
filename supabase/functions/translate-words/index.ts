// Supabase Edge Function: translate-words
//
// Takes a list of words (already picked out by extract-vocabulary and
// selected by the user) and asks Groq (gpt-oss-120b) for a natural,
// dictionary-appropriate translation of each into the requested target
// language. The Groq API key lives here as a Supabase secret and is never
// shipped inside the app.
//
// `verify_jwt` is left at Supabase's default (true), so only requests
// carrying a signed-in LexiSnap user's auth token reach this code - the
// Flutter client gets this for free via `functions.invoke`, matching the
// app's `AuthMiddleware(requiresAuth: true)` on the scan route.
//
// Deploy: supabase functions deploy translate-words
// Secret:  supabase secrets set GROQ_API_KEY=gsk_... (shared with extract-vocabulary)

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const MAX_WORDS = 100;

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
