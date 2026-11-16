// Port of lib/app/core/services/deck/deck_repository.dart +
// supabase_deck_repository.dart. A plain typed module (no React/Redux) so the
// data access stays testable; RTK Query endpoints wrap these functions.

import type { SupabaseClient } from "@supabase/supabase-js";

import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { calculateNextReview, type ReviewGrade } from "@/lib/domain/srs";
import type { Deck, DeckWord, Flashcard } from "./models";

type Client = SupabaseClient;

function db(client?: Client): Client {
  return client ?? (getSupabaseBrowserClient() as unknown as Client);
}

// ---- row mappers ----------------------------------------------------------

function deckFromRow(row: Record<string, any>): Deck {
  const f = row.flashcards;
  let cardCount = 0;
  if (Array.isArray(f) && f.length > 0) {
    cardCount =
      typeof f[0] === "object" && f[0] !== null && "count" in f[0]
        ? (f[0].count as number)
        : f.length;
  }
  return {
    id: row.id,
    name: row.name,
    sourceLanguage: row.source_language ?? null,
    targetLanguage: row.target_language,
    cardCount,
    createdAt: row.created_at,
    notes: row.notes ?? null,
  };
}

function flashcardFromRow(
  row: Record<string, any>,
  sourceLanguage: string | null,
  targetLanguage: string,
): Flashcard {
  const sentenceRows = (row.example_sentences ?? []) as Array<Record<string, any>>;
  sentenceRows.sort((a, b) =>
    String(a.created_at).localeCompare(String(b.created_at)),
  );
  return {
    id: row.id,
    word: row.word,
    level: row.level ?? null,
    wordDescription: row.word_description ?? null,
    translation: row.translation,
    exampleSentences: sentenceRows.map((s) => s.sentence as string),
    notes: row.notes ?? null,
    audioUrl: row.audio_url ?? null,
    sourceLanguage,
    targetLanguage,
    easeFactor: Number(row.ease_factor),
    intervalDays: row.interval_days,
    repetitions: row.repetitions,
    dueAt: row.due_at,
    lastReviewedAt: row.last_reviewed_at ?? null,
  };
}

// ---- writes: create / append --------------------------------------------

async function insertFlashcards(
  client: Client,
  deckId: string,
  words: DeckWord[],
): Promise<void> {
  if (words.length === 0) return;
  const { data: inserted, error } = await client
    .from("flashcards")
    .insert(
      words.map((w) => ({
        deck_id: deckId,
        word: w.word,
        level: w.level,
        word_description: w.wordDescription,
        translation: w.translation,
      })),
    )
    .select();
  if (error) throw error;

  const sentenceRows = words
    .map((w, i) =>
      w.exampleSentence && w.exampleSentence.length > 0
        ? { flashcard_id: (inserted![i] as any).id as string, sentence: w.exampleSentence }
        : null,
    )
    .filter((r): r is { flashcard_id: string; sentence: string } => r !== null);

  if (sentenceRows.length > 0) {
    const { error: sErr } = await client.from("example_sentences").insert(sentenceRows);
    if (sErr) throw sErr;
  }
}

export async function createDeck(
  args: {
    name: string;
    sourceLanguage: string | null;
    targetLanguage: string;
    words: DeckWord[];
  },
  client?: Client,
): Promise<void> {
  const c = db(client);
  const { data: deck, error } = await c
    .from("decks")
    .insert({
      name: args.name,
      source_language: args.sourceLanguage,
      target_language: args.targetLanguage,
    })
    .select()
    .single();
  if (error) throw error;
  await insertFlashcards(c, (deck as any).id, args.words);
}

export async function addWordsToDeck(
  args: { deckId: string; words: DeckWord[] },
  client?: Client,
): Promise<void> {
  if (args.words.length === 0) return;
  await insertFlashcards(db(client), args.deckId, args.words);
}

export async function createEmptyDeck(
  args: { name: string; sourceLanguage: string | null; targetLanguage: string },
  client?: Client,
): Promise<string> {
  const { data, error } = await db(client)
    .from("decks")
    .insert({
      name: args.name,
      source_language: args.sourceLanguage,
      target_language: args.targetLanguage,
    })
    .select()
    .single();
  if (error) throw error;
  return (data as any).id as string;
}

// ---- reads ---------------------------------------------------------------

export async function listDecks(
  offset = 0,
  limit = 20,
  client?: Client,
): Promise<Deck[]> {
  const { data, error } = await db(client)
    .from("decks")
    .select("*, flashcards(count)")
    .order("created_at", { ascending: false })
    .range(offset, offset + limit - 1);
  if (error) throw error;
  return (data ?? []).map(deckFromRow);
}

export async function deckTotals(
  client?: Client,
): Promise<{ deckCount: number; cardCount: number }> {
  const c = db(client);
  const decks = await c.from("decks").select("*", { count: "exact", head: true });
  const cards = await c.from("flashcards").select("*", { count: "exact", head: true });
  return { deckCount: decks.count ?? 0, cardCount: cards.count ?? 0 };
}

export async function listDecksByLanguagePair(
  sourceLanguage: string | null,
  targetLanguage: string,
  client?: Client,
): Promise<Deck[]> {
  let query = db(client)
    .from("decks")
    .select("*, flashcards(count)")
    .eq("target_language", targetLanguage);
  query = sourceLanguage === null
    ? query.is("source_language", null)
    : query.eq("source_language", sourceLanguage);
  const { data, error } = await query.order("created_at", { ascending: false });
  if (error) throw error;
  return (data ?? []).map(deckFromRow);
}

export async function getDeckMeta(deckId: string, client?: Client): Promise<Deck> {
  const { data, error } = await db(client)
    .from("decks")
    .select("*, flashcards(count)")
    .eq("id", deckId)
    .single();
  if (error) throw error;
  return deckFromRow(data as any);
}

export async function deckDueCount(deckId: string, client?: Client): Promise<number> {
  const { count, error } = await db(client)
    .from("flashcards")
    .select("*", { count: "exact", head: true })
    .eq("deck_id", deckId)
    .lte("due_at", new Date().toISOString());
  if (error) throw error;
  return count ?? 0;
}

export async function listDeckCards(
  deckId: string,
  sourceLanguage: string | null,
  targetLanguage: string,
  offset = 0,
  limit = 20,
  client?: Client,
): Promise<Flashcard[]> {
  const { data, error } = await db(client)
    .from("flashcards")
    .select("*, example_sentences(*)")
    .eq("deck_id", deckId)
    .order("created_at")
    .order("id")
    .range(offset, offset + limit - 1);
  if (error) throw error;
  return (data ?? []).map((r) => flashcardFromRow(r, sourceLanguage, targetLanguage));
}

export async function getDeck(
  deckId: string,
  client?: Client,
): Promise<{ deck: Deck; flashcards: Flashcard[] }> {
  const { data, error } = await db(client)
    .from("decks")
    .select("*, flashcards(*, example_sentences(*))")
    .eq("id", deckId)
    .single();
  if (error) throw error;
  const deck = deckFromRow(data as any);
  const rows = ((data as any).flashcards ?? []) as Array<Record<string, any>>;
  const flashcards = rows.map((r) =>
    flashcardFromRow(r, deck.sourceLanguage, deck.targetLanguage),
  );
  return { deck, flashcards };
}

export async function listDueFlashcards(limit = 200, client?: Client): Promise<Flashcard[]> {
  const { data, error } = await db(client)
    .from("flashcards")
    .select("*, example_sentences(*), decks!inner(*)")
    .lte("due_at", new Date().toISOString())
    .order("due_at")
    .limit(limit);
  if (error) throw error;
  return (data ?? []).map((r) =>
    flashcardFromRow(r, r.decks.source_language ?? null, r.decks.target_language),
  );
}

export async function listUpcomingFlashcards(
  limit: number,
  offset = 0,
  client?: Client,
): Promise<Flashcard[]> {
  const { data, error } = await db(client)
    .from("flashcards")
    .select("*, example_sentences(*), decks!inner(*)")
    .gt("due_at", new Date().toISOString())
    .order("due_at")
    .range(offset, offset + limit - 1);
  if (error) throw error;
  return (data ?? []).map((r) =>
    flashcardFromRow(r, r.decks.source_language ?? null, r.decks.target_language),
  );
}

// ---- mutations -----------------------------------------------------------

export async function renameDeck(deckId: string, newName: string, client?: Client): Promise<void> {
  const { error } = await db(client).from("decks").update({ name: newName }).eq("id", deckId);
  if (error) throw error;
}

export async function deleteDeck(deckId: string, client?: Client): Promise<void> {
  const { error } = await db(client).from("decks").delete().eq("id", deckId);
  if (error) throw error;
}

export async function updateFlashcard(
  args: {
    flashcardId: string;
    word: string;
    translation: string;
    wordDescription: string | null;
    exampleSentences: string[];
  },
  client?: Client,
): Promise<void> {
  const c = db(client);
  const { error } = await c
    .from("flashcards")
    .update({
      word: args.word,
      translation: args.translation,
      word_description: args.wordDescription,
    })
    .eq("id", args.flashcardId);
  if (error) throw error;

  await c.from("example_sentences").delete().eq("flashcard_id", args.flashcardId);

  const rows = args.exampleSentences
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .map((s) => ({ flashcard_id: args.flashcardId, sentence: s }));
  if (rows.length > 0) {
    const { error: sErr } = await c.from("example_sentences").insert(rows);
    if (sErr) throw sErr;
  }
}

export async function deleteFlashcard(flashcardId: string, client?: Client): Promise<void> {
  const { error } = await db(client).from("flashcards").delete().eq("id", flashcardId);
  if (error) throw error;
}

export async function moveFlashcards(
  flashcardIds: string[],
  toDeckId: string,
  client?: Client,
): Promise<void> {
  if (flashcardIds.length === 0) return;
  const { error } = await db(client)
    .from("flashcards")
    .update({ deck_id: toDeckId })
    .in("id", flashcardIds);
  if (error) throw error;
}

export async function copyFlashcards(
  flashcardIds: string[],
  toDeckId: string,
  client?: Client,
): Promise<void> {
  if (flashcardIds.length === 0) return;
  const c = db(client);
  const { data: sources, error } = await c
    .from("flashcards")
    .select("*, example_sentences(*)")
    .in("id", flashcardIds);
  if (error) throw error;
  if (!sources || sources.length === 0) return;

  const { data: inserted, error: iErr } = await c
    .from("flashcards")
    .insert(
      sources.map((row: any) => ({
        deck_id: toDeckId,
        word: row.word,
        level: row.level,
        word_description: row.word_description,
        translation: row.translation,
      })),
    )
    .select();
  if (iErr) throw iErr;

  const sentenceRows: Array<{ flashcard_id: string; sentence: string }> = [];
  sources.forEach((row: any, i: number) => {
    for (const s of row.example_sentences ?? []) {
      sentenceRows.push({ flashcard_id: (inserted![i] as any).id, sentence: s.sentence });
    }
  });
  if (sentenceRows.length > 0) {
    const { error: sErr } = await c.from("example_sentences").insert(sentenceRows);
    if (sErr) throw sErr;
  }
}

export async function deleteFlashcards(flashcardIds: string[], client?: Client): Promise<void> {
  if (flashcardIds.length === 0) return;
  const { error } = await db(client).from("flashcards").delete().in("id", flashcardIds);
  if (error) throw error;
}

export async function wordsInDeck(deckId: string, client?: Client): Promise<Set<string>> {
  const { data, error } = await db(client)
    .from("flashcards")
    .select("word")
    .eq("deck_id", deckId);
  if (error) throw error;
  return new Set((data ?? []).map((r: any) => (r.word as string).toLowerCase()));
}

export async function submitReview(
  card: Flashcard,
  grade: ReviewGrade,
  client?: Client,
): Promise<Flashcard> {
  const update = calculateNextReview(
    {
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      repetitions: card.repetitions,
    },
    grade,
  );
  const reviewedAt = new Date();

  const { error } = await db(client)
    .from("flashcards")
    .update({
      ease_factor: update.easeFactor,
      interval_days: update.intervalDays,
      repetitions: update.repetitions,
      due_at: update.dueAt.toISOString(),
      last_reviewed_at: reviewedAt.toISOString(),
    })
    .eq("id", card.id);
  if (error) throw error;

  return {
    ...card,
    easeFactor: update.easeFactor,
    intervalDays: update.intervalDays,
    repetitions: update.repetitions,
    dueAt: update.dueAt.toISOString(),
    lastReviewedAt: reviewedAt.toISOString(),
  };
}
