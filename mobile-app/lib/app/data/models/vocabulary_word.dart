/// A single word pulled from a scan, optionally enriched with a CEFR level,
/// a short definition, and an example sentence by [VocabularyAiService].
/// [level], [wordDescription], and [exampleSentence] are null when this
/// came from the local regex fallback instead (see
/// `ScanController.confirmImage`).
class VocabularyWord {
  const VocabularyWord({
    required this.word,
    this.level,
    this.wordDescription,
    this.exampleSentence,
    this.translation,
    this.languageCode,
  });

  final String word;

  /// 'A1'..'C2', or null when not AI-classified.
  final String? level;

  final String? wordDescription;
  final String? exampleSentence;

  /// The word translated into the app's UI language, shown on the
  /// word-selection screen so the user can see each word's meaning while
  /// picking. Null/empty for the regex fallback, which can't translate.
  final String? translation;

  /// This word's own ISO 639-1 language code. A single scan can mix
  /// languages, so each word carries its own rather than sharing the scan's
  /// dominant one. Null for the local regex fallback, which can't detect it.
  final String? languageCode;

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
    word: json['word'] as String,
    level: json['level'] as String?,
    wordDescription: json['word_description'] as String?,
    exampleSentence: json['example_sentence'] as String?,
    translation: json['translation'] as String?,
    languageCode: json['language_code'] as String?,
  );

  VocabularyWord copyWith({String? translation}) => VocabularyWord(
    word: word,
    level: level,
    wordDescription: wordDescription,
    exampleSentence: exampleSentence,
    translation: translation ?? this.translation,
    languageCode: languageCode,
  );

  // Equality/hashCode by lowercased word, so this can be used in a Set for
  // selection tracking exactly like the old List<String> could.
  @override
  bool operator ==(Object other) =>
      other is VocabularyWord && other.word.toLowerCase() == word.toLowerCase();

  @override
  int get hashCode => word.toLowerCase().hashCode;
}
