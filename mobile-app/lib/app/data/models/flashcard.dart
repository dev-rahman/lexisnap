/// Sentinel for [Flashcard.copyWith]'s nullable [wordDescription], so
/// "leave unchanged" (the default) can be told apart from "set to null".
const Object _unset = Object();

/// A single saved flashcard, as shown in deck detail and studied in a
/// spaced-repetition session.
class Flashcard {
  const Flashcard({
    required this.id,
    required this.word,
    this.level,
    this.wordDescription,
    required this.translation,
    required this.exampleSentences,
    this.notes,
    this.audioUrl,
    this.sourceLanguage,
    required this.targetLanguage,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
    this.lastReviewedAt,
  });

  final String id;
  final String word;
  final String? level;
  final String? wordDescription;
  final String translation;
  final List<String> exampleSentences;

  /// Reserved for future AI-written context; unused for now.
  final String? notes;

  /// Reserved for future recorded audio; unused for now - pronunciation
  /// currently uses on-device text-to-speech instead.
  final String? audioUrl;

  /// Copied down from the card's deck so a card carries its own language
  /// pair. A review session can span several decks, so the text-to-speech
  /// voice has to be decided per card rather than per session.
  /// [sourceLanguage] is null when detection wasn't available.
  final String? sourceLanguage;
  final String targetLanguage;

  /// SM-2 scheduling state - see `lib/app/core/utils/spaced_repetition.dart`.
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;

  bool get isDue => !dueAt.isAfter(DateTime.now());

  Flashcard copyWith({
    String? word,
    String? translation,
    Object? wordDescription = _unset,
    List<String>? exampleSentences,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
  }) {
    return Flashcard(
      id: id,
      word: word ?? this.word,
      level: level,
      // Sentinel rather than `?? this.wordDescription`, so an edit that
      // clears the description (passing null) actually clears it.
      wordDescription: wordDescription == _unset
          ? this.wordDescription
          : wordDescription as String?,
      translation: translation ?? this.translation,
      exampleSentences: exampleSentences ?? this.exampleSentences,
      notes: notes,
      audioUrl: audioUrl,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
