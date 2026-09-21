import 'package:flutter_tts/flutter_tts.dart';

import 'text_to_speech_service.dart';

/// Speaks words aloud using the OS's built-in text-to-speech engine via
/// the `flutter_tts` plugin - free, offline, no account or API key.
class FlutterTtsService implements TextToSpeechService {
  final _tts = FlutterTts();

  /// Maps the ISO 639-1 codes this app deals with (from `extract-vocabulary`
  /// language detection) to the BCP-47 locale tags `flutter_tts` expects.
  static const _localesByLanguageCode = {
    'en': 'en-US',
    'de': 'de-DE',
    'fr': 'fr-FR',
    'es': 'es-ES',
    'ko': 'ko-KR',
  };

  @override
  Future<void> speak(String text, {String? languageCode}) async {
    final locale = languageCode != null
        ? _localesByLanguageCode[languageCode]
        : null;

    if (locale != null) {
      try {
        await _tts.setLanguage(locale);
      } catch (_) {
        // Voice/locale not installed on this device - fall back to
        // whatever the engine's current/default language is.
      }
    }

    await _tts.stop();
    await _tts.speak(text);
  }
}
