// Repository facade. Dispatches to the real Supabase repository, or the demo
// fixtures when demo mode is on — chosen per call so a runtime ?demo toggle
// works. Callers import from here instead of ./repository.

import { isDemo } from "@/lib/demo";
import * as real from "./repository";
import * as demo from "./demoRepository";

function pick<K extends keyof typeof real>(name: K): (typeof real)[K] {
  return ((...args: unknown[]) => {
    const impl = isDemo() && name in demo ? (demo as Record<string, unknown>)[name] : real[name];
    return (impl as (...a: unknown[]) => unknown)(...args);
  }) as (typeof real)[K];
}

export const createDeck = pick("createDeck");
export const addWordsToDeck = pick("addWordsToDeck");
export const createEmptyDeck = pick("createEmptyDeck");
export const listDecks = pick("listDecks");
export const deckTotals = pick("deckTotals");
export const listDecksByLanguagePair = pick("listDecksByLanguagePair");
export const getDeckMeta = pick("getDeckMeta");
export const deckDueCount = pick("deckDueCount");
export const listDeckCards = pick("listDeckCards");
export const getDeck = pick("getDeck");
export const listDueFlashcards = pick("listDueFlashcards");
export const listUpcomingFlashcards = pick("listUpcomingFlashcards");
export const renameDeck = pick("renameDeck");
export const deleteDeck = pick("deleteDeck");
export const updateFlashcard = pick("updateFlashcard");
export const deleteFlashcard = pick("deleteFlashcard");
export const moveFlashcards = pick("moveFlashcards");
export const copyFlashcards = pick("copyFlashcards");
export const deleteFlashcards = pick("deleteFlashcards");
export const wordsInDeck = pick("wordsInDeck");
export const submitReview = pick("submitReview");
