import '../../../data/models/deck_word.dart';

/// Contract for persisting a scanned deck. Controllers talk only to this
/// interface, never to a specific backend/SDK.
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
}
