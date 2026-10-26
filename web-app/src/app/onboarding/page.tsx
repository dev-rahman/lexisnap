"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { BookOpen, ListChecks, ScanLine, Sparkles } from "lucide-react";

import { BrandMark } from "@/components/brand/BrandMark";
import { Button } from "@/components/ui/Button";
import { useT } from "@/components/providers/I18nProvider";
import type { MessageKey } from "@/lib/i18n";
import { markOnboardingSeen } from "@/store/slices/prefsSlice";
import { useAppDispatch } from "@/store/hooks";

const PAGES: {
  icon: React.ReactNode;
  title: MessageKey;
  body: MessageKey;
}[] = [
  { icon: <ScanLine size={40} />, title: "onboarding_scan_title", body: "onboarding_scan_body" },
  { icon: <ListChecks size={40} />, title: "onboarding_words_title", body: "onboarding_words_body" },
  { icon: <BookOpen size={40} />, title: "onboarding_sentences_title", body: "onboarding_sentences_body" },
  { icon: <Sparkles size={40} />, title: "onboarding_deck_title", body: "onboarding_deck_body" },
];

export default function OnboardingPage() {
  const t = useT();
  const router = useRouter();
  const dispatch = useAppDispatch();
  const [page, setPage] = useState(0);
  const isLast = page === PAGES.length - 1;

  function finish() {
    dispatch(markOnboardingSeen());
    router.replace("/login");
  }

  const current = PAGES[page];

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-md flex-col bg-paper px-6 py-8 safe-top safe-bottom">
      <div className="flex items-center justify-between">
        <BrandMark size="sm" />
        <button onClick={finish} className="text-sm font-medium text-ink-muted">
          {t("onboarding_skip")}
        </button>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <div className="mb-8 flex h-24 w-24 items-center justify-center rounded-2xl bg-accent/15 text-accent">
          {current.icon}
        </div>
        <h1 className="text-2xl font-bold text-ink">{t(current.title)}</h1>
        <p className="mt-3 max-w-sm text-ink-muted">{t(current.body)}</p>
      </div>

      <div className="mb-6 flex justify-center gap-2">
        {PAGES.map((_, i) => (
          <span
            key={i}
            className={`h-2 rounded-full transition-all ${i === page ? "w-6 bg-accent" : "w-2 bg-border"}`}
          />
        ))}
      </div>

      <Button
        variant="primary"
        size="lg"
        fullWidth
        onClick={() => (isLast ? finish() : setPage((p) => p + 1))}
      >
        {isLast ? t("onboarding_get_started") : t("onboarding_next")}
      </Button>
    </main>
  );
}
