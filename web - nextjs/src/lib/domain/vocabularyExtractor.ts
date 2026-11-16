// Port of lib/app/core/utils/vocabulary_extractor.dart.
//
// Turns raw OCR text into a deduplicated list of candidate words, in
// first-seen order. Deliberately light-touch — no stopword filtering, since
// the scan can be in any supported language. Used as the offline fallback
// when the extract-vocabulary edge function can't be reached.

const MAX_WORDS = 150;
const WORD_PATTERN = /[\p{L}][\p{L}'-]*/gu;

export function extractVocabulary(text: string): string[] {
  const seen = new Set<string>();
  const words: string[] = [];

  for (const match of text.matchAll(WORD_PATTERN)) {
    const word = match[0];
    if (word.length < 2) continue;

    const key = word.toLowerCase();
    if (!seen.has(key)) {
      seen.add(key);
      words.push(word);
      if (words.length >= MAX_WORDS) break;
    }
  }

  return words;
}
