import { createContext, useContext, useEffect, useMemo, type ReactNode } from "react";

import { translate, type AppLocale, type MessageKey, type TranslateParams } from "@/lib/i18n";
import { useAppSelector } from "@/store/hooks";

type TFn = (key: MessageKey, params?: TranslateParams) => string;

interface I18nValue {
  locale: AppLocale;
  t: TFn;
}

const I18nContext = createContext<I18nValue | null>(null);

export function I18nProvider({ children }: { children: ReactNode }) {
  const locale = useAppSelector((s) => s.prefs.locale);

  // No server <html lang> in a SPA — keep it in sync from here.
  useEffect(() => {
    document.documentElement.lang = locale;
  }, [locale]);

  const value = useMemo<I18nValue>(
    () => ({ locale, t: (key, params) => translate(locale, key, params) }),
    [locale],
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

/** Translation hook: `const t = useT()` then `t("key", { param })`. */
export function useT(): TFn {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useT must be used within I18nProvider");
  return ctx.t;
}

export function useLocale(): AppLocale {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error("useLocale must be used within I18nProvider");
  return ctx.locale;
}
