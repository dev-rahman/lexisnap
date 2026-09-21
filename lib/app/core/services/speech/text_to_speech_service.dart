/// Contract for speaking a word aloud. Controllers talk only to this
/// interface, never to a specific TTS engine/SDK.
///
/// To swap engines later, write a new class that implements this
/// interface and swap the single registration in
/// `lib/app/core/services/service_locator.dart`. Nothing else changes.
abstract class TextToSpeechService {
  /// Speaks [text], in the voice/locale for [languageCode] (an ISO 639-1
  /// code like 'fr') when available, otherwise the device default.
  Future<void> speak(String text, {String? languageCode});
}
