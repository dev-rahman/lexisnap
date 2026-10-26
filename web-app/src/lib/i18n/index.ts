// Lightweight i18n: static message catalogs + a formatter with {param}
// interpolation. Mirrors the GetX translations the Flutter app used.

import en from "./messages/en.json";
import de from "./messages/de.json";
import es from "./messages/es.json";
import fr from "./messages/fr.json";
import ko from "./messages/ko.json";

export type AppLocale = "en" | "de" | "es" | "fr" | "ko";
export type MessageKey = keyof typeof en;

export const FALLBACK_LOCALE: AppLocale = "en";

export interface AppLocaleOption {
  code: AppLocale;
  nativeName: string;
  flag: string;
}

/** Shown in the picker in each language's own script (see app_locales.dart). */
export const APP_LOCALES: AppLocaleOption[] = [
  { code: "en", nativeName: "English", flag: "🇺🇸" },
  { code: "de", nativeName: "Deutsch", flag: "🇩🇪" },
  { code: "fr", nativeName: "Français", flag: "🇫🇷" },
  { code: "es", nativeName: "Español", flag: "🇪🇸" },
  { code: "ko", nativeName: "한국어", flag: "🇰🇷" },
];

const CATALOGS: Record<AppLocale, Record<string, string>> = { en, de, es, fr, ko };

export type TranslateParams = Record<string, string | number>;

/** Resolves a key for a locale, falling back to English, with interpolation. */
export function translate(
  locale: AppLocale,
  key: MessageKey,
  params?: TranslateParams,
): string {
  const catalog = CATALOGS[locale] ?? CATALOGS[FALLBACK_LOCALE];
  let value = catalog[key] ?? CATALOGS[FALLBACK_LOCALE][key] ?? key;
  if (params) {
    for (const [name, replacement] of Object.entries(params)) {
      value = value.replaceAll(`{${name}}`, String(replacement));
    }
  }
  return value;
}

export function isAppLocale(value: string | null | undefined): value is AppLocale {
  return value === "en" || value === "de" || value === "es" || value === "fr" || value === "ko";
}
