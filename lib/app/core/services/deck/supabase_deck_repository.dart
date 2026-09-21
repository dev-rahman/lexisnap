import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/deck.dart';
import '../../../data/models/deck_word.dart';
import '../../../data/models/flashcard.dart';
import 'deck_repository.dart';

class SupabaseDeckRepository implements DeckRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> createDeck({
    required String name,
    String? sourceLanguage,
    required String targetLanguage,
    required List<DeckWord> words,
  }) async {
    final deck = await _client
        .from('decks')
        .insert({
          'name': name,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        })
        .select()
        .single();

    final deckId = deck['id'] as String;

    final insertedFlashcards = await _client.from('flashcards').insert([
      for (final word in words)
        {
          'deck_id': deckId,
          'word': word.word,
          'level': word.level,
          'word_description': word.wordDescription,
          'translation': word.translation,
        },
    ]).select();

    final sentenceRows = <Map<String, dynamic>>[
      for (var i = 0; i < words.length; i++)
        if (words[i].exampleSentence?.isNotEmpty ?? false)
          {
            'flashcard_id': insertedFlashcards[i]['id'] as String,
            'sentence': words[i].exampleSentence,
          },
    ];

    if (sentenceRows.isNotEmpty) {
      await _client.from('example_sentences').insert(sentenceRows);
    }
  }

  @override
  Future<List<Deck>> listDecks() async {
    final rows = await _client
        .from('decks')
        .select('*, flashcards(count)')
        .order('created_at', ascending: false);

    return [for (final row in rows) _deckFromRow(row)];
  }

  @override
  Future<(Deck, List<Flashcard>)> getDeck(String deckId) async {
    final row = await _client
        .from('decks')
        .select('*, flashcards(*, example_sentences(*))')
        .eq('id', deckId)
        .single();

    final deck = _deckFromRow(row);
    final flashcardRows = (row['flashcards'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final flashcards = [
      for (final card in flashcardRows) _flashcardFromRow(card),
    ];

    return (deck, flashcards);
  }

  @override
  Future<void> renameDeck(String deckId, String newName) async {
    await _client.from('decks').update({'name': newName}).eq('id', deckId);
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    await _client.from('decks').delete().eq('id', deckId);
  }

  Deck _deckFromRow(Map<String, dynamic> row) {
    final flashcardsField = row['flashcards'];
    final cardCount = flashcardsField is List && flashcardsField.isNotEmpty
        ? (flashcardsField.first is Map &&
                  flashcardsField.first.containsKey('count')
              ? flashcardsField.first['count'] as int
              : flashcardsField.length)
        : 0;

    return Deck(
      id: row['id'] as String,
      name: row['name'] as String,
      sourceLanguage: row['source_language'] as String?,
      targetLanguage: row['target_language'] as String,
      cardCount: cardCount,
      createdAt: DateTime.parse(row['created_at'] as String),
      notes: row['notes'] as String?,
    );
  }

  Flashcard _flashcardFromRow(Map<String, dynamic> row) {
    final sentenceRows = (row['example_sentences'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    sentenceRows.sort(
      (a, b) =>
          (a['created_at'] as String).compareTo(b['created_at'] as String),
    );

    return Flashcard(
      id: row['id'] as String,
      word: row['word'] as String,
      level: row['level'] as String?,
      wordDescription: row['word_description'] as String?,
      translation: row['translation'] as String,
      exampleSentences: [
        for (final sentence in sentenceRows) sentence['sentence'] as String,
      ],
      notes: row['notes'] as String?,
      audioUrl: row['audio_url'] as String?,
    );
  }
}
