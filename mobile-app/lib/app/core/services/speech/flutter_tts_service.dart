import 'package:flutter_tts/flutter_tts.dart';

import 'text_to_speech_service.dart';

/// Speaks words aloud using the OS's built-in text-to-speech engine via
/// the `flutter_tts` plugin - free, offline, no account or API key.
class FlutterTtsService implements TextToSpeechService {
  FlutterTtsService() {
    // Makes `speak` resolve when the utterance actually finishes rather
    // than when it's queued, which is what lets listening mode chain
    // word, pause, translation, pause without guessing at durations.
    _tts.awaitSpeakCompletion(true);
  }

  final _tts = FlutterTts();

  /// Maps every ISO 639-1 code in `VocabularyLanguages.all` (plus AI-
  /// detected source languages, which use the same codes) to the BCP-47
  /// locale tag `flutter_tts` expects. Falls back to the device's default
  /// voice for anything not listed here or not installed on-device.
  static const _localesByLanguageCode = {
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'pt': 'pt-PT',
    'nl': 'nl-NL',
    'ru': 'ru-RU',
    'zh': 'zh-CN',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'ar': 'ar-SA',
    'hi': 'hi-IN',
    'bn': 'bn-BD',
    'tr': 'tr-TR',
    'vi': 'vi-VN',
    'th': 'th-TH',
    'id': 'id-ID',
    'pl': 'pl-PL',
    'uk': 'uk-UA',
    'el': 'el-GR',
    'he': 'he-IL',
    'sv': 'sv-SE',
    'no': 'nb-NO',
    'da': 'da-DK',
    'fi': 'fi-FI',
    'cs': 'cs-CZ',
    'ro': 'ro-RO',
    'hu': 'hu-HU',
    'sw': 'sw-KE',
    'tl': 'fil-PH',
    'ms': 'ms-MY',
    'fa': 'fa-IR',
    'ur': 'ur-PK',
    'ta': 'ta-IN',
    'hr': 'hr-HR',
    'sk': 'sk-SK',
    'bg': 'bg-BG',
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

  @override
  Future<void> stop() => _tts.stop();
}
