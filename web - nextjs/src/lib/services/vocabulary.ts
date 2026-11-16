// Wrappers for the extract-vocabulary and translate-words Supabase Edge
// Functions (unchanged from the Flutter backend — Groq key stays server-side).
// Ports supabase_edge_vocabulary_service.dart / supabase_edge_translation_service.dart.

import type { VocabularyExtractionResult, VocabularyWord } from "@/lib/data/models";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";

export async function extractVocabulary(
  text: string,
  uiLanguage: string,
): Promise<VocabularyExtractionResult> {
  const { data, error } = await getSupabaseBrowserClient().functions.invoke(
    "extract-vocabulary",
    { body: { text, ui_language: uiLanguage } },
  );
  if (error) throw new Error(error.message);

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
  if (error) throw new Error(error.message);

  const raw = data as { translations?: Array<{ word: string; translation: string }> };
  const map: Record<string, string> = {};
  for (const t of raw.translations ?? []) {
    if (t.word && t.translation) map[t.word] = t.translation;
  }
  return map;
}
