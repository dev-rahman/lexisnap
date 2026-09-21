import '../../../data/models/deck.dart';
import '../../../data/models/deck_word.dart';
import '../../../data/models/flashcard.dart';

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
}
