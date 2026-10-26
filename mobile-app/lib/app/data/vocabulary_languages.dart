import 'models/vocabulary_language.dart';

/// The curated set of languages someone can pick as a scan's target
/// language, and that source/target codes stored on a deck are resolved
/// against for flag/name display. Deliberately a plain data catalog, not
/// tied to the app's own 5-language UI chrome (`AppLocales`).
class VocabularyLanguages {
  VocabularyLanguages._();

  static const all = [
    VocabularyLanguage(code: 'en', name: 'English', flag: '🇬🇧'),
    VocabularyLanguage(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    VocabularyLanguage(code: 'fr', name: 'French', flag: '🇫🇷'),
    VocabularyLanguage(code: 'de', name: 'German', flag: '🇩🇪'),
    VocabularyLanguage(code: 'it', name: 'Italian', flag: '🇮🇹'),
    VocabularyLanguage(code: 'pt', name: 'Portuguese', flag: '🇵🇹'),
    VocabularyLanguage(code: 'nl', name: 'Dutch', flag: '🇳🇱'),
    VocabularyLanguage(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    VocabularyLanguage(code: 'zh', name: 'Chinese', flag: '🇨🇳'),
    VocabularyLanguage(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    VocabularyLanguage(code: 'ko', name: 'Korean', flag: '🇰🇷'),
    VocabularyLanguage(code: 'ar', name: 'Arabic', flag: '🇸🇦'),
    VocabularyLanguage(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
    VocabularyLanguage(code: 'bn', name: 'Bengali', flag: '🇧🇩'),
    VocabularyLanguage(code: 'tr', name: 'Turkish', flag: '🇹🇷'),
    VocabularyLanguage(code: 'vi', name: 'Vietnamese', flag: '🇻🇳'),
    VocabularyLanguage(code: 'th', name: 'Thai', flag: '🇹🇭'),
    VocabularyLanguage(code: 'id', name: 'Indonesian', flag: '🇮🇩'),
    VocabularyLanguage(code: 'pl', name: 'Polish', flag: '🇵🇱'),
    VocabularyLanguage(code: 'uk', name: 'Ukrainian', flag: '🇺🇦'),
    VocabularyLanguage(code: 'el', name: 'Greek', flag: '🇬🇷'),
    VocabularyLanguage(code: 'he', name: 'Hebrew', flag: '🇮🇱'),
    VocabularyLanguage(code: 'sv', name: 'Swedish', flag: '🇸🇪'),
    VocabularyLanguage(code: 'no', name: 'Norwegian', flag: '🇳🇴'),
    VocabularyLanguage(code: 'da', name: 'Danish', flag: '🇩🇰'),
    VocabularyLanguage(code: 'fi', name: 'Finnish', flag: '🇫🇮'),
    VocabularyLanguage(code: 'cs', name: 'Czech', flag: '🇨🇿'),
    VocabularyLanguage(code: 'ro', name: 'Romanian', flag: '🇷🇴'),
    VocabularyLanguage(code: 'hu', name: 'Hungarian', flag: '🇭🇺'),
    VocabularyLanguage(code: 'sw', name: 'Swahili', flag: '🇰🇪'),
    VocabularyLanguage(code: 'tl', name: 'Filipino', flag: '🇵🇭'),
    VocabularyLanguage(code: 'ms', name: 'Malay', flag: '🇲🇾'),
    VocabularyLanguage(code: 'fa', name: 'Persian', flag: '🇮🇷'),
    VocabularyLanguage(code: 'ur', name: 'Urdu', flag: '🇵🇰'),
    VocabularyLanguage(code: 'ta', name: 'Tamil', flag: '🇮🇳'),
    VocabularyLanguage(code: 'hr', name: 'Croatian', flag: '🇭🇷'),
    VocabularyLanguage(code: 'sk', name: 'Slovak', flag: '🇸🇰'),
    VocabularyLanguage(code: 'bg', name: 'Bulgarian', flag: '🇧🇬'),
  ];

  /// Looks up a language by its stored code. Returns null for unrecognized
  /// or legacy free-text values (e.g. decks saved before this catalog
  /// existed, whose `target_language` might be a plain word like
  /// "spanish") - callers fall back to showing the raw text instead.
  static VocabularyLanguage? byCode(String? code) {
    if (code == null) return null;
    for (final language in all) {
      if (language.code == code) return language;
    }
    return null;
  }
}
