import 'vocabulary_word.dart';

/// Everything a single `extract-vocabulary` call returns: the words
/// themselves plus what the AI could tell about the scanned text as a
/// whole. The language/name fields are null when this came from the local
/// regex fallback instead (see `ScanController.confirmImage`), which has
/// no way to detect language or suggest a deck name.
class VocabularyExtractionResult {
  const VocabularyExtractionResult({
    required this.words,
    this.sourceLanguageCode,
    this.sourceLanguageName,
    this.suggestedDeckName,
  });

  final List<VocabularyWord> words;
  final String? sourceLanguageCode;
  final String? sourceLanguageName;
  final String? suggestedDeckName;
}
