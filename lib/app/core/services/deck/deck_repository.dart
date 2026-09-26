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

  /// The signed-in user's decks, most recently created first.
  Future<List<Deck>> listDecks();

  /// A single deck and its flashcards.
  Future<(Deck, List<Flashcard>)> getDeck(String deckId);

  Future<void> renameDeck(String deckId, String newName);

  /// Deletes the deck and all of its flashcards.
  Future<void> deleteDeck(String deckId);

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
