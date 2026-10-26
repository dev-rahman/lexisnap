// Framework-free data models — ports of lib/app/data/models/*.dart.
// These are the types the whole app depends on, never the Supabase row shape.

export type StudyMode = "smart" | "quiz" | "flip" | "listen";

export function studyModeIsReview(mode: StudyMode): boolean {
  return mode !== "listen";
}

export interface AppUser {
  id: string;
  email: string | null;
  fullName: string | null;
  /** Photo to show: own upload, else Google picture, else null (initials). */
  avatarUrl: string | null;
  /** Whether avatarUrl is a photo the user uploaded (only kind removable). */
  hasOwnPhoto: boolean;
  /** Whether the account has email+password sign-in (Google accounts don't). */
  hasPassword: boolean;
  emailConfirmed: boolean;
}

export interface Deck {
  id: string;
  name: string;
  sourceLanguage: string | null;
  targetLanguage: string;
  cardCount: number;
  createdAt: string; // ISO
  notes: string | null;
}

export interface Flashcard {
  id: string;
  word: string;
  level: string | null;
  wordDescription: string | null;
  translation: string;
  exampleSentences: string[];
  notes: string | null;
  audioUrl: string | null;
  /** Copied down from the deck so a card carries its own language pair. */
  sourceLanguage: string | null;
  targetLanguage: string;
  // SM-2 scheduling state.
  easeFactor: number;
  intervalDays: number;
  repetitions: number;
  dueAt: string; // ISO
  lastReviewedAt: string | null; // ISO
}

export function isDue(card: Flashcard, now: Date = new Date()): boolean {
  return new Date(card.dueAt).getTime() <= now.getTime();
}

/** A selected word ready to be saved as a flashcard (scan flow write DTO). */
export interface DeckWord {
  word: string;
  level: string | null;
  wordDescription: string | null;
  exampleSentence: string | null;
  translation: string;
}

/** A candidate word from a scan, optionally AI-enriched. */
export interface VocabularyWord {
  word: string;
  level: string | null;
  wordDescription: string | null;
  exampleSentence: string | null;
  /** Translated into the UI language, shown on the selection screen. */
  translation: string | null;
  /** This word's own ISO 639-1 code (a scan can mix languages). */
  languageCode: string | null;
}

export interface VocabularyExtractionResult {
  words: VocabularyWord[];
  sourceLanguageCode: string | null;
  sourceLanguageName: string | null;
  suggestedDeckName: string | null;
}

/** Equality by lowercased word (matches the Dart VocabularyWord contract). */
export function sameWord(a: VocabularyWord, b: VocabularyWord): boolean {
  return a.word.toLowerCase() === b.word.toLowerCase();
}
