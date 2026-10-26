import '../../../data/models/vocabulary_extraction_result.dart';

/// Contract for turning scanned text into leveled vocabulary. Controllers
/// talk only to this interface, never to a specific AI provider/SDK.
///
/// To swap providers later, write a new class that implements this
/// interface and swap the single registration in
/// `lib/app/core/services/service_locator.dart`. Nothing else changes.
abstract class VocabularyAiService {
  /// Picks the words worth learning out of [text], classifies each by CEFR
  /// level (A1-C2), writes one example sentence per word at that level,
  /// tags each word's own language, translates each into [uiLanguage] (the
  /// language the app's UI is in, e.g. "English", for the selection preview),
  /// and reports the text's dominant source language plus a suggested deck
  /// name. Throws on any failure - callers fall back to local extraction.
  Future<VocabularyExtractionResult> extractVocabulary(
    String text, {
    String? uiLanguage,
  });
}
