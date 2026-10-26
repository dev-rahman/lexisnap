/// Contract for translating a list of words into a target language.
/// Controllers talk only to this interface, never to a specific AI
/// provider/SDK.
///
/// To swap providers later, write a new class that implements this
/// interface and swap the single registration in
/// `lib/app/core/services/service_locator.dart`. Nothing else changes.
abstract class TranslationAiService {
  /// Returns a translation per input word (keyed by the exact string given
  /// in [words]), written in [targetLanguage]. [sourceLanguage] is passed
  /// along as context when known, but translation should still work
  /// without it. Throws on any failure.
  Future<Map<String, String>> translateWords({
    required List<String> words,
    String? sourceLanguage,
    required String targetLanguage,
  });
}
