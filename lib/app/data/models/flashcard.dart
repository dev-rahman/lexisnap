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

  /// SM-2 scheduling state - see `lib/app/core/utils/spaced_repetition.dart`.
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
  final DateTime? lastReviewedAt;

  bool get isDue => !dueAt.isAfter(DateTime.now());

  Flashcard copyWith({
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
  }) {
    return Flashcard(
      id: id,
      word: word,
      level: level,
      wordDescription: wordDescription,
      translation: translation,
      exampleSentences: exampleSentences,
      notes: notes,
      audioUrl: audioUrl,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
