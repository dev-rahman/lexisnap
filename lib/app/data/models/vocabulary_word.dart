/// A single word pulled from a scan, optionally enriched with a CEFR level
/// and an example sentence by [VocabularyAiService]. [level] and
/// [exampleSentence] are null when this came from the local regex fallback
/// instead (see `ScanController.confirmImage`).
class VocabularyWord {
  const VocabularyWord({required this.word, this.level, this.exampleSentence});

  final String word;

  /// 'A1'..'C2', or null when not AI-classified.
  final String? level;

  final String? exampleSentence;

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
    word: json['word'] as String,
    level: json['level'] as String?,
    exampleSentence: json['example_sentence'] as String?,
  );

  // Equality/hashCode by lowercased word, so this can be used in a Set for
  // selection tracking exactly like the old List<String> could.
  @override
  bool operator ==(Object other) =>
      other is VocabularyWord && other.word.toLowerCase() == word.toLowerCase();

  @override
  int get hashCode => word.toLowerCase().hashCode;
}
