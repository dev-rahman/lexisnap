import '../../../data/models/deck.dart';
import '../../../data/models/deck_word.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/review_grade.dart';

/// Contract for persisting and managing scanned decks. Controllers talk
/// only to this interface, never to a specific backend/SDK.
///
/// To swap Supabase for another backend later, write a new class that
/// implements this interface and swap the single registration in
/// `lib/app/core/services/service_locator.dart`. Nothing else changes.
abstract class DeckRepository {
  /// Creates a deck and all of its flashcards. [sourceLanguage] is null
  /// when detection wasn't available (local-fallback extraction).
  Future<void> createDeck({
    required String name,
    String? sourceLanguage,
    required String targetLanguage,
    required List<DeckWord> words,
  });

  /// Appends [words] as new flashcards to an existing deck. Used by the
  /// scan flow when the user files a batch of scanned words into a deck
  /// they already have, rather than creating a new one. The words must
  /// already be translated into that deck's target language.
  Future<void> addWordsToDeck({
    required String deckId,
    required List<DeckWord> words,
  });

  /// Creates a deck with no cards and returns its id. Used when moving or
  /// copying existing cards into a fresh deck, where the cards already carry
  /// their translations so no scan or word list is involved.
  Future<String> createEmptyDeck({
    required String name,
    String? sourceLanguage,
    required String targetLanguage,
  });

  /// One page of the signed-in user's decks, most recently created first.
  /// Paginated so the list scales to a large backlog; [offset] is how many
  /// decks to skip and [limit] the page size.
  Future<List<Deck>> listDecks({int offset = 0, int limit = 20});

  /// Totals across *all* of the user's decks (not just a loaded page), for
  /// the decks screen's stats row and "do I have any cards" checks.
  Future<({int deckCount, int cardCount})> deckTotals();

  /// Every deck that shares the given language pair, most recent first -
  /// the move/copy/merge destination list, resolved server-side so it's
  /// complete even when the decks list itself is only partly paged in.
  Future<List<Deck>> listDecksByLanguagePair({
    required String? sourceLanguage,
    required String targetLanguage,
  });

  /// A single deck and its flashcards (all of them). Prefer [getDeckMeta] +
  /// [listDeckCards] for the browsing screen; this stays for the operations
  /// that genuinely need every card in memory (e.g. merging a whole deck).
  Future<(Deck, List<Flashcard>)> getDeck(String deckId);

  /// A single deck's metadata and its total card count, without pulling the
  /// cards themselves - the header for the paginated card list.
  Future<Deck> getDeckMeta(String deckId);

  /// How many of a deck's cards are due right now, counted server-side so
  /// the header is right even when only a page of cards is loaded.
  Future<int> deckDueCount(String deckId);

  /// One page of a deck's cards, oldest first (stable order for paging).
  /// The deck's language pair is passed in (the caller already has it from
  /// [getDeckMeta]), so a page fetch is a single query.
  Future<List<Flashcard>> listDeckCards(
    String deckId, {
    required String? sourceLanguage,
    required String targetLanguage,
    int offset = 0,
    int limit = 20,
  });

  Future<void> renameDeck(String deckId, String newName);

  /// Deletes the deck and all of its flashcards.
  Future<void> deleteDeck(String deckId);

  /// Updates a single card's editable content - its word, translation,
  /// optional description, and the full set of example sentences. The
  /// sentences are replaced wholesale, so the list passed is exactly what
  /// the card ends up with. Scheduling state is left untouched.
  Future<void> updateFlashcard({
    required String flashcardId,
    required String word,
    required String translation,
    String? wordDescription,
    required List<String> exampleSentences,
  });

  /// Deletes a single card and its example sentences from its deck.
  Future<void> deleteFlashcard(String flashcardId);

  /// Moves the given cards into another deck. The cards keep their content,
  /// example sentences, and review schedule; only which deck they belong to
  /// changes. The caller is responsible for the two decks sharing a language
  /// pair, since a card's languages are its deck's.
  Future<void> moveFlashcards({
    required List<String> flashcardIds,
    required String toDeckId,
  });

  /// Copies the given cards into another deck as fresh cards - same content
  /// and example sentences, but a new review schedule (due now), leaving the
  /// originals in place. Same language-pair expectation as [moveFlashcards].
  Future<void> copyFlashcards({
    required List<String> flashcardIds,
    required String toDeckId,
  });

  /// Deletes several cards and their example sentences in one go.
  Future<void> deleteFlashcards(List<String> flashcardIds);

  /// The words already in [deckId], lowercased, for spotting which incoming
  /// cards would become duplicates before a move, copy, or merge. Only the
  /// word column is read, so this stays cheap.
  Future<Set<String>> wordsInDeck(String deckId);

  /// Every card due for review right now, across all of the user's decks,
  /// soonest-due first. Each card carries its deck's language pair, so a
  /// session spanning several decks can still speak each word correctly.
  Future<List<Flashcard>> listDueFlashcards({int limit});

  /// Cards that are *not* due yet, soonest-due first, starting at [offset].
  ///
  /// Powers extra practice once the day's scheduled reviews are done: the
  /// user has nothing owed but wants to keep going. [offset] lets the
  /// caller walk further into the upcoming queue on each extra round
  /// rather than serving the same nearest cards over and over.
  Future<List<Flashcard>> listUpcomingFlashcards({
    required int limit,
    int offset,
  });

  /// Records a study-session grade for [card], applying the SM-2 schedule
  /// update and persisting it. Returns the card with its new schedule.
  Future<Flashcard> submitReview(Flashcard card, ReviewGrade grade);
}
