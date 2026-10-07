import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/deck.dart';
import '../../../data/models/deck_word.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/models/review_grade.dart';
import '../../utils/spaced_repetition.dart';
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
    await _insertFlashcards(deckId, words);
  }

  @override
  Future<void> addWordsToDeck({
    required String deckId,
    required List<DeckWord> words,
  }) async {
    if (words.isEmpty) return;
    await _insertFlashcards(deckId, words);
  }

  /// Inserts [words] as flashcards under [deckId] plus their example
  /// sentences. Shared by [createDeck] (on a freshly inserted deck) and
  /// [addWordsToDeck] (on an existing one), so a scanned batch is saved
  /// the same way whichever deck it lands in.
  Future<void> _insertFlashcards(String deckId, List<DeckWord> words) async {
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
      for (final card in flashcardRows)
        _flashcardFromRow(
          card,
          sourceLanguage: deck.sourceLanguage,
          targetLanguage: deck.targetLanguage,
        ),
    ];

    return (deck, flashcards);
  }

  @override
  Future<List<Flashcard>> listDueFlashcards({int limit = 200}) async {
    final rows = await _client
        .from('flashcards')
        .select('*, example_sentences(*), decks!inner(*)')
        .lte('due_at', DateTime.now().toIso8601String())
        .order('due_at')
        .limit(limit);

    return [
      for (final row in rows)
        _flashcardFromRow(
          row,
          sourceLanguage: (row['decks'] as Map)['source_language'] as String?,
          targetLanguage: (row['decks'] as Map)['target_language'] as String,
        ),
    ];
  }

  @override
  Future<List<Flashcard>> listUpcomingFlashcards({
    required int limit,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('flashcards')
        .select('*, example_sentences(*), decks!inner(*)')
        .gt('due_at', DateTime.now().toIso8601String())
        .order('due_at')
        .range(offset, offset + limit - 1);

    return [
      for (final row in rows)
        _flashcardFromRow(
          row,
          sourceLanguage: (row['decks'] as Map)['source_language'] as String?,
          targetLanguage: (row['decks'] as Map)['target_language'] as String,
        ),
    ];
  }

  @override
  Future<void> renameDeck(String deckId, String newName) async {
    await _client.from('decks').update({'name': newName}).eq('id', deckId);
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    await _client.from('decks').delete().eq('id', deckId);
  }

  @override
  Future<void> updateFlashcard({
    required String flashcardId,
    required String word,
    required String translation,
    String? wordDescription,
    required List<String> exampleSentences,
  }) async {
    await _client
        .from('flashcards')
        .update({
          'word': word,
          'translation': translation,
          'word_description': wordDescription,
        })
        .eq('id', flashcardId);

    // Example sentences live in their own table with no natural key to diff
    // against, so the simplest correct update is to clear the card's rows
    // and re-insert the current list in order. The set is small (a handful
    // at most), so the extra writes are cheap.
    await _client
        .from('example_sentences')
        .delete()
        .eq('flashcard_id', flashcardId);

    final sentenceRows = <Map<String, dynamic>>[
      for (final sentence in exampleSentences)
        if (sentence.trim().isNotEmpty)
          {'flashcard_id': flashcardId, 'sentence': sentence.trim()},
    ];

    if (sentenceRows.isNotEmpty) {
      await _client.from('example_sentences').insert(sentenceRows);
    }
  }

  @override
  Future<void> deleteFlashcard(String flashcardId) async {
    await _client.from('flashcards').delete().eq('id', flashcardId);
  }

  @override
  Future<Flashcard> submitReview(Flashcard card, ReviewGrade grade) async {
    final update = calculateNextReview(
      easeFactor: card.easeFactor,
      intervalDays: card.intervalDays,
      repetitions: card.repetitions,
      grade: grade,
    );
    final reviewedAt = DateTime.now();

    await _client
        .from('flashcards')
        .update({
          'ease_factor': update.easeFactor,
          'interval_days': update.intervalDays,
          'repetitions': update.repetitions,
          'due_at': update.dueAt.toIso8601String(),
          'last_reviewed_at': reviewedAt.toIso8601String(),
        })
        .eq('id', card.id);

    return card.copyWith(
      easeFactor: update.easeFactor,
      intervalDays: update.intervalDays,
      repetitions: update.repetitions,
      dueAt: update.dueAt,
      lastReviewedAt: reviewedAt,
    );
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

  Flashcard _flashcardFromRow(
    Map<String, dynamic> row, {
    required String? sourceLanguage,
    required String targetLanguage,
  }) {
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
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      easeFactor: (row['ease_factor'] as num).toDouble(),
      intervalDays: row['interval_days'] as int,
      repetitions: row['repetitions'] as int,
      dueAt: DateTime.parse(row['due_at'] as String),
      lastReviewedAt: row['last_reviewed_at'] == null
          ? null
          : DateTime.parse(row['last_reviewed_at'] as String),
    );
  }
}
