// Port of lib/app/data/vocabulary_languages.dart + the TTS locale map from
// flutter_tts_service.dart. The curated set of languages a scan can be
// translated into, and that deck source/target codes resolve against.

export interface VocabularyLanguage {
  code: string; // ISO 639-1
  name: string;
  flag: string;
}

export const VOCABULARY_LANGUAGES: VocabularyLanguage[] = [
  { code: "en", name: "English", flag: "🇬🇧" },
  { code: "es", name: "Spanish", flag: "🇪🇸" },
  { code: "fr", name: "French", flag: "🇫🇷" },
  { code: "de", name: "German", flag: "🇩🇪" },
  { code: "it", name: "Italian", flag: "🇮🇹" },
  { code: "pt", name: "Portuguese", flag: "🇵🇹" },
  { code: "nl", name: "Dutch", flag: "🇳🇱" },
  { code: "ru", name: "Russian", flag: "🇷🇺" },
  { code: "zh", name: "Chinese", flag: "🇨🇳" },
  { code: "ja", name: "Japanese", flag: "🇯🇵" },
  { code: "ko", name: "Korean", flag: "🇰🇷" },
  { code: "ar", name: "Arabic", flag: "🇸🇦" },
  { code: "hi", name: "Hindi", flag: "🇮🇳" },
  { code: "bn", name: "Bengali", flag: "🇧🇩" },
  { code: "tr", name: "Turkish", flag: "🇹🇷" },
  { code: "vi", name: "Vietnamese", flag: "🇻🇳" },
  { code: "th", name: "Thai", flag: "🇹🇭" },
  { code: "id", name: "Indonesian", flag: "🇮🇩" },
  { code: "pl", name: "Polish", flag: "🇵🇱" },
  { code: "uk", name: "Ukrainian", flag: "🇺🇦" },
  { code: "el", name: "Greek", flag: "🇬🇷" },
  { code: "he", name: "Hebrew", flag: "🇮🇱" },
  { code: "sv", name: "Swedish", flag: "🇸🇪" },
  { code: "no", name: "Norwegian", flag: "🇳🇴" },
  { code: "da", name: "Danish", flag: "🇩🇰" },
  { code: "fi", name: "Finnish", flag: "🇫🇮" },
  { code: "cs", name: "Czech", flag: "🇨🇿" },
  { code: "ro", name: "Romanian", flag: "🇷🇴" },
  { code: "hu", name: "Hungarian", flag: "🇭🇺" },
  { code: "sw", name: "Swahili", flag: "🇰🇪" },
  { code: "tl", name: "Filipino", flag: "🇵🇭" },
  { code: "ms", name: "Malay", flag: "🇲🇾" },
  { code: "fa", name: "Persian", flag: "🇮🇷" },
  { code: "ur", name: "Urdu", flag: "🇵🇰" },
  { code: "ta", name: "Tamil", flag: "🇮🇳" },
  { code: "hr", name: "Croatian", flag: "🇭🇷" },
  { code: "sk", name: "Slovak", flag: "🇸🇰" },
  { code: "bg", name: "Bulgarian", flag: "🇧🇬" },
];

const BY_CODE = new Map(VOCABULARY_LANGUAGES.map((l) => [l.code, l]));

/** Looks up a language by its stored code; null for legacy free-text values. */
export function languageByCode(code: string | null | undefined): VocabularyLanguage | null {
  if (!code) return null;
  return BY_CODE.get(code) ?? null;
}

/** ISO 639-1 → BCP-47 locale tag for the Web Speech API. */
export const TTS_LOCALE_BY_CODE: Record<string, string> = {
  en: "en-US",
  es: "es-ES",
  fr: "fr-FR",
  de: "de-DE",
  it: "it-IT",
  pt: "pt-PT",
  nl: "nl-NL",
  ru: "ru-RU",
  zh: "zh-CN",
  ja: "ja-JP",
  ko: "ko-KR",
  ar: "ar-SA",
  hi: "hi-IN",
  bn: "bn-BD",
  tr: "tr-TR",
  vi: "vi-VN",
  th: "th-TH",
  id: "id-ID",
  pl: "pl-PL",
  uk: "uk-UA",
  el: "el-GR",
  he: "he-IL",
  sv: "sv-SE",
  no: "nb-NO",
  da: "da-DK",
  fi: "fi-FI",
  cs: "cs-CZ",
  ro: "ro-RO",
  hu: "hu-HU",
  sw: "sw-KE",
  tl: "fil-PH",
  ms: "ms-MY",
  fa: "fa-IR",
  ur: "ur-PK",
  ta: "ta-IN",
  hr: "hr-HR",
  sk: "sk-SK",
  bg: "bg-BG",
};
