/// A language someone can translate scanned vocabulary into (or that a scan
/// was detected as being written in) - distinct from `AppLocaleOption`,
/// which is the app's own 5-language UI chrome.
class VocabularyLanguage {
  const VocabularyLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });

  /// ISO 639-1, e.g. 'de'.
  final String code;

  final String name;

  /// Flag emoji for the language's most associated country.
  final String flag;

  @override
  bool operator ==(Object other) =>
      other is VocabularyLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
