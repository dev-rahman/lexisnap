/// A selected word, ready to be saved as a flashcard: everything
/// [VocabularyWord] carries plus the translation added by the target-
/// language step in the scan flow.
class DeckWord {
  const DeckWord({
    required this.word,
    this.level,
    this.wordDescription,
    this.exampleSentence,
    required this.translation,
  });

  final String word;
  final String? level;
  final String? wordDescription;
  final String? exampleSentence;
  final String translation;
}
