/// A single saved flashcard, as shown (read-only, for now) in deck detail.
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
}
