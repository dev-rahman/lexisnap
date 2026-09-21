import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/deck_word.dart';
import 'deck_repository.dart';

class SupabaseDeckRepository implements DeckRepository {
  @override
  Future<void> createDeck({
    required String name,
    String? sourceLanguage,
    required String targetLanguage,
    required List<DeckWord> words,
  }) async {
    final client = Supabase.instance.client;

    final deck = await client
        .from('decks')
        .insert({
          'name': name,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        })
        .select()
        .single();

    final deckId = deck['id'] as String;

    await client.from('flashcards').insert([
      for (final word in words)
        {
          'deck_id': deckId,
          'word': word.word,
          'level': word.level,
          'example_sentence': word.exampleSentence,
          'translation': word.translation,
        },
    ]);
  }
}
