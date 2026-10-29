// Wrappers for the extract-vocabulary and translate-words Supabase Edge
// Functions (unchanged from the Flutter backend — Groq key stays server-side).
// Ports supabase_edge_vocabulary_service.dart / supabase_edge_translation_service.dart.

import type { VocabularyExtractionResult, VocabularyWord } from "@/lib/data/models";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";

/** Thrown when the user has hit their daily cap for an AI action (HTTP 429
 *  from the edge function). Callers can special-case it to show a limit/upgrade
 *  message rather than a generic error. */
export class QuotaExceededError extends Error {
  constructor(public readonly limit: number | null) {
    super("quota_exceeded");
    this.name = "QuotaExceededError";
  }
}

// supabase-js reports a non-2xx edge response as a FunctionsHttpError whose
// JSON body is tucked away on `context` (a Response). Surface our 429 quota
// payload as a typed error; otherwise rethrow the generic message.
async function throwForEdgeError(error: {
  message?: string;
  context?: Response;
}): Promise<never> {
  const ctx = error?.context;
  if (ctx && typeof ctx.json === "function") {
    try {
      const body = await ctx.clone().json();
      if (body?.code === "quota_exceeded") {
        throw new QuotaExceededError(
          typeof body.limit === "number" ? body.limit : null,
        );
      }
    } catch (e) {
      if (e instanceof QuotaExceededError) throw e;
      // Body wasn't our quota JSON — fall through to the generic error.
    }
  }
  throw new Error(error?.message ?? "Request failed");
}

export async function extractVocabulary(
  text: string,
  uiLanguage: string,
): Promise<VocabularyExtractionResult> {
  const { data, error } = await getSupabaseBrowserClient().functions.invoke(
    "extract-vocabulary",
    { body: { text, ui_language: uiLanguage } },
  );
  if (error) await throwForEdgeError(error);

  const raw = data as {
    words?: Array<Record<string, unknown>>;
    language_code?: string;
    language_name?: string;
    suggested_deck_name?: string;
  };

  const words: VocabularyWord[] = (raw.words ?? []).map((w) => ({
    word: String(w.word),
    level: (w.level as string | undefined) ?? null,
    wordDescription: (w.word_description as string | undefined) ?? null,
    exampleSentence: (w.example_sentence as string | undefined) ?? null,
    translation: (w.translation as string | undefined) ?? null,
    languageCode: (w.language_code as string | undefined) ?? null,
  }));

  return {
    words,
    sourceLanguageCode: raw.language_code ?? null,
    sourceLanguageName: raw.language_name ?? null,
    suggestedDeckName: raw.suggested_deck_name ?? null,
  };
}

/** Returns a map of input word → translation (dictionary form). */
export async function translateWords(args: {
  words: string[];
  sourceLanguage: string | null;
  targetLanguage: string;
}): Promise<Record<string, string>> {
  const { data, error } = await getSupabaseBrowserClient().functions.invoke(
    "translate-words",
    {
      body: {
        words: args.words,
        source_language: args.sourceLanguage ?? undefined,
        target_language: args.targetLanguage,
      },
    },
  );
  if (error) await throwForEdgeError(error);

  const raw = data as { translations?: Array<{ word: string; translation: string }> };
  const map: Record<string, string> = {};
  for (const t of raw.translations ?? []) {
    if (t.word && t.translation) map[t.word] = t.translation;
  }
  return map;
}
