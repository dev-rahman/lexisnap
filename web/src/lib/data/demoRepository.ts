// Demo-mode repository: same surface as repository.ts, backed by local
// fixtures. Reads return demo data; writes are no-ops (screenshots/preview).

import type { Deck, DeckWord, Flashcard } from "./models";
import { isDue } from "./models";
import { demoAllCards, demoDeckById, demoDecks } from "./demoData";

const stripCards = (d: (typeof demoDecks)[number]): Deck => {
  const { cards: _cards, ...deck } = d;
  void _cards;
  return deck;
};

export async function listDecks(offset = 0, limit = 20): Promise<Deck[]> {
  return demoDecks.slice(offset, offset + limit).map(stripCards);
}

export async function deckTotals(): Promise<{ deckCount: number; cardCount: number }> {
  return {
    deckCount: demoDecks.length,
    cardCount: demoAllCards().length,
  };
}

export async function listDecksByLanguagePair(): Promise<Deck[]> {
  return demoDecks.map(stripCards);
}

export async function getDeckMeta(deckId: string): Promise<Deck> {
  const d = demoDeckById(deckId);
  if (!d) throw new Error("Deck not found");
  return stripCards(d);
}

export async function deckDueCount(deckId: string): Promise<number> {
  return (demoDeckById(deckId)?.cards ?? []).filter((c) => isDue(c)).length;
}

export async function listDeckCards(
  deckId: string,
  _src: string | null,
  _tgt: string,
  offset = 0,
  limit = 20,
): Promise<Flashcard[]> {
  return (demoDeckById(deckId)?.cards ?? []).slice(offset, offset + limit);
}

export async function getDeck(
  deckId: string,
): Promise<{ deck: Deck; flashcards: Flashcard[] }> {
  const d = demoDeckById(deckId);
  if (!d) throw new Error("Deck not found");
  return { deck: stripCards(d), flashcards: d.cards };
}

export async function listDueFlashcards(limit = 200): Promise<Flashcard[]> {
  return demoAllCards()
    .filter((c) => isDue(c))
    .slice(0, limit);
}

export async function listUpcomingFlashcards(limit: number, offset = 0): Promise<Flashcard[]> {
  return demoAllCards()
    .filter((c) => !isDue(c))
    .slice(offset, offset + limit);
}

export async function wordsInDeck(deckId: string): Promise<Set<string>> {
  return new Set((demoDeckById(deckId)?.cards ?? []).map((c) => c.word.toLowerCase()));
}

// ---- writes: no-ops in demo ----------------------------------------------
export async function createDeck(_a: {
  name: string;
  sourceLanguage: string | null;
  targetLanguage: string;
  words: DeckWord[];
}): Promise<void> {}
export async function addWordsToDeck(_a: { deckId: string; words: DeckWord[] }): Promise<void> {}
export async function createEmptyDeck(): Promise<string> {
  return "demo-new";
}
export async function renameDeck(): Promise<void> {}
export async function deleteDeck(): Promise<void> {}
export async function updateFlashcard(): Promise<void> {}
export async function deleteFlashcard(): Promise<void> {}
export async function moveFlashcards(): Promise<void> {}
export async function copyFlashcards(): Promise<void> {}
export async function deleteFlashcards(): Promise<void> {}

export async function submitReview(card: Flashcard): Promise<Flashcard> {
  return card;
}
