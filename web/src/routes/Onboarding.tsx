import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { BrandMark } from "@/components/brand/BrandMark";
import {
  ScanScene,
  SentencesScene,
  StudyScene,
  WordsScene,
} from "@/components/brand/Illustrations";
import { Button } from "@/components/ui/Button";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch } from "@/store/hooks";
import { markOnboardingSeen } from "@/store/slices/prefsSlice";
import { cn } from "@/lib/utils/cn";

export function Onboarding() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const [index, setIndex] = useState(0);

  const slides = [
    { Scene: ScanScene, title: t("onboarding_scan_title"), body: t("onboarding_scan_body") },
    { Scene: WordsScene, title: t("onboarding_words_title"), body: t("onboarding_words_body") },
    { Scene: SentencesScene, title: t("onboarding_sentences_title"), body: t("onboarding_sentences_body") },
    { Scene: StudyScene, title: t("onboarding_deck_title"), body: t("onboarding_deck_body") },
  ];
  const last = index === slides.length - 1;
  const slide = slides[index];

  function finish() {
    dispatch(markOnboardingSeen());
    navigate("/signup", { replace: true });
  }

  return (
    <div className="app-wash flex min-h-dvh flex-col bg-paper px-5 py-6 safe-top pb-safe">
      <div className="flex items-center justify-between">
        <BrandMark size="sm" />
        {!last && (
          <button
            onClick={finish}
            className="rounded-full px-3 py-1.5 text-sm font-semibold text-ink-muted hover:text-ink"
          >
            {t("onboarding_skip")}
          </button>
        )}
      </div>

      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <div key={index} className="mb-8 h-56 w-56 animate-pop-in sm:h-64 sm:w-64">
          <slide.Scene />
        </div>
        <h1
          key={`t-${index}`}
          className="max-w-sm animate-[rise-in_0.4s_ease-out] font-display text-3xl font-bold text-ink text-balance"
        >
          {slide.title}
        </h1>
        <p
          key={`b-${index}`}
          className="mt-3 max-w-sm animate-[rise-in_0.5s_ease-out] text-[17px] text-ink-muted text-balance"
        >
          {slide.body}
        </p>
      </div>

      <div className="mx-auto w-full max-w-sm space-y-6">
        <div className="flex justify-center gap-2">
          {slides.map((_, i) => (
            <button
              key={i}
              onClick={() => setIndex(i)}
              aria-label={`Slide ${i + 1}`}
              className={cn(
                "h-2.5 rounded-full transition-all duration-300",
                i === index ? "w-7 bg-coral" : "w-2.5 bg-border",
              )}
            />
          ))}
        </div>
        <Button
          fullWidth
          size="lg"
          onClick={() => (last ? finish() : setIndex((i) => i + 1))}
        >
          {last ? t("onboarding_get_started") : t("onboarding_next")}
        </Button>
      </div>
    </div>
  );
}
