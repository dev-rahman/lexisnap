import { useState } from "react";
import { useNavigate } from "react-router-dom";

import { BrandMark } from "@/components/brand/BrandMark";
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
    { emoji: "📸", bg: "from-coral to-flame", title: t("onboarding_scan_title"), body: t("onboarding_scan_body") },
    { emoji: "✨", bg: "from-hue-violet to-hue-sky", title: t("onboarding_words_title"), body: t("onboarding_words_body") },
    { emoji: "💬", bg: "from-hue-teal to-hue-moss", title: t("onboarding_sentences_title"), body: t("onboarding_sentences_body") },
    { emoji: "🔥", bg: "from-flame to-coral", title: t("onboarding_deck_title"), body: t("onboarding_deck_body") },
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
        <div
          key={index}
          className={cn(
            "mb-10 grid h-40 w-40 animate-pop-in place-items-center rounded-[2rem] bg-gradient-to-br text-7xl shadow-card",
            slide.bg,
          )}
        >
          <span>{slide.emoji}</span>
        </div>
        <h1 className="max-w-sm font-display text-3xl font-bold text-ink text-balance">
          {slide.title}
        </h1>
        <p className="mt-3 max-w-sm text-[17px] text-ink-muted text-balance">{slide.body}</p>
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
