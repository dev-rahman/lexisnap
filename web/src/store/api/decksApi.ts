// RTK Query endpoints wrapping the repository. Server state (decks, cards,
// due queue, totals) lives here with tag-based cache invalidation — the
// "controller" tier's data cache, replacing DecksController's ownership of
// the list.

import { createApi, fakeBaseQuery } from "@reduxjs/toolkit/query/react";

import type { Deck, DeckWord, Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repo";

export const DECKS_PAGE_SIZE = 20;
export const CARDS_PAGE_SIZE = 20;
export const DUE_QUEUE_LIMIT = 200;

type QR<T> = { data: T } | { error: { message: string } };
async function run<T>(fn: () => Promise<T>): Promise<QR<T>> {
  try {
    return { data: await fn() };
  } catch (e) {
    return { error: { message: e instanceof Error ? e.message : String(e) } };
  }
}

export const decksApi = createApi({
  reducerPath: "decksApi",
  baseQuery: fakeBaseQuery<{ message: string }>(),
  tagTypes: ["Decks", "Deck", "DeckCards", "Due", "Totals"],
  endpoints: (build) => ({
    // Decks list — `limit` grows as the user scrolls (range 0..limit).
    getDecks: build.query<Deck[], number>({
      queryFn: (limit) => run(() => repo.listDecks(0, limit)),
      providesTags: [{ type: "Decks", id: "LIST" }],
    }),
    getDeckTotals: build.query<{ deckCount: number; cardCount: number }, void>({
      queryFn: () => run(() => repo.deckTotals()),
      providesTags: [{ type: "Totals", id: "ALL" }],
    }),
    getDeckMeta: build.query<Deck, string>({
      queryFn: (deckId) => run(() => repo.getDeckMeta(deckId)),
      providesTags: (_r, _e, deckId) => [{ type: "Deck", id: deckId }],
    }),
    getDeckDueCount: build.query<number, string>({
      queryFn: (deckId) => run(() => repo.deckDueCount(deckId)),
      providesTags: (_r, _e, deckId) => [{ type: "Deck", id: `${deckId}:due` }],
    }),
    getDeckCards: build.query<
      Flashcard[],
      { deckId: string; sourceLanguage: string | null; targetLanguage: string; limit: number }
    >({
      queryFn: (a) =>
        run(() => repo.listDeckCards(a.deckId, a.sourceLanguage, a.targetLanguage, 0, a.limit)),
      providesTags: (_r, _e, a) => [{ type: "DeckCards", id: a.deckId }],
    }),
    getDueCards: build.query<Flashcard[], void>({
      queryFn: () => run(() => repo.listDueFlashcards(DUE_QUEUE_LIMIT)),
      providesTags: [{ type: "Due", id: "LIST" }],
    }),

    // --- mutations ---
    createDeck: build.mutation<
      void,
      { name: string; sourceLanguage: string | null; targetLanguage: string; words: DeckWord[] }
    >({
      queryFn: (a) => run(() => repo.createDeck(a)),
      invalidatesTags: [
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
      ],
    }),
    addWordsToDeck: build.mutation<void, { deckId: string; words: DeckWord[] }>({
      queryFn: (a) => run(() => repo.addWordsToDeck(a)),
      invalidatesTags: (_r, _e, a) => [
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
        { type: "Deck", id: a.deckId },
        { type: "DeckCards", id: a.deckId },
      ],
    }),
    renameDeck: build.mutation<void, { deckId: string; name: string }>({
      queryFn: (a) => run(() => repo.renameDeck(a.deckId, a.name)),
      invalidatesTags: (_r, _e, a) => [
        { type: "Decks", id: "LIST" },
        { type: "Deck", id: a.deckId },
      ],
    }),
    deleteDeck: build.mutation<void, string>({
      queryFn: (deckId) => run(() => repo.deleteDeck(deckId)),
      invalidatesTags: [
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
      ],
    }),
    updateFlashcard: build.mutation<
      void,
      {
        flashcardId: string;
        deckId: string;
        word: string;
        translation: string;
        wordDescription: string | null;
        exampleSentences: string[];
      }
    >({
      queryFn: (a) =>
        run(() =>
          repo.updateFlashcard({
            flashcardId: a.flashcardId,
            word: a.word,
            translation: a.translation,
            wordDescription: a.wordDescription,
            exampleSentences: a.exampleSentences,
          }),
        ),
      invalidatesTags: (_r, _e, a) => [{ type: "DeckCards", id: a.deckId }],
    }),
    deleteFlashcard: build.mutation<void, { flashcardId: string; deckId: string }>({
      queryFn: (a) => run(() => repo.deleteFlashcard(a.flashcardId)),
      invalidatesTags: (_r, _e, a) => [
        { type: "DeckCards", id: a.deckId },
        { type: "Deck", id: a.deckId },
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
      ],
    }),
    moveFlashcards: build.mutation<
      void,
      { flashcardIds: string[]; toDeckId: string; fromDeckId: string }
    >({
      queryFn: (a) => run(() => repo.moveFlashcards(a.flashcardIds, a.toDeckId)),
      invalidatesTags: (_r, _e, a) => [
        { type: "DeckCards", id: a.fromDeckId },
        { type: "DeckCards", id: a.toDeckId },
        { type: "Deck", id: a.fromDeckId },
        { type: "Deck", id: a.toDeckId },
        { type: "Decks", id: "LIST" },
      ],
    }),
    copyFlashcards: build.mutation<
      void,
      { flashcardIds: string[]; toDeckId: string }
    >({
      queryFn: (a) => run(() => repo.copyFlashcards(a.flashcardIds, a.toDeckId)),
      invalidatesTags: (_r, _e, a) => [
        { type: "DeckCards", id: a.toDeckId },
        { type: "Deck", id: a.toDeckId },
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
      ],
    }),
    deleteFlashcards: build.mutation<void, { flashcardIds: string[]; deckId: string }>({
      queryFn: (a) => run(() => repo.deleteFlashcards(a.flashcardIds)),
      invalidatesTags: (_r, _e, a) => [
        { type: "DeckCards", id: a.deckId },
        { type: "Deck", id: a.deckId },
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
      ],
    }),
  }),
});

export const {
  useGetDecksQuery,
  useGetDeckTotalsQuery,
  useGetDeckMetaQuery,
  useGetDeckDueCountQuery,
  useGetDeckCardsQuery,
  useGetDueCardsQuery,
  useCreateDeckMutation,
  useAddWordsToDeckMutation,
  useRenameDeckMutation,
  useDeleteDeckMutation,
  useUpdateFlashcardMutation,
  useDeleteFlashcardMutation,
  useMoveFlashcardsMutation,
  useCopyFlashcardsMutation,
  useDeleteFlashcardsMutation,
} = decksApi;
