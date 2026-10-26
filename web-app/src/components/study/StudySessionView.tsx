"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { Check, Volume2, X } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { ConfirmSheet } from "@/components/ui/Sheet";
import { ProgressRing } from "@/components/ui/ProgressRing";
import { useT } from "@/components/providers/I18nProvider";
import type { Flashcard, StudyMode } from "@/lib/data/models";
import { useStudySession } from "@/lib/hooks/useStudySession";
import { speak } from "@/lib/services/tts";
import { cn } from "@/lib/utils/cn";

export function StudySessionView({
  cards,
  cap,
  mode,
  practiceOnly,
}: {
  cards: Flashcard[];
  cap: number;
  mode: StudyMode;
  practiceOnly: boolean;
}) {
  const t = useT();
  const router = useRouter();
  const session = useStudySession({ cards, cap, mode, practiceOnly });
  const [revealed, setRevealed] = useState(false);
  const [picked, setPicked] = useState<number | null>(null);
  const [leaving, setLeaving] = useState(false);
  const shownAt = useRef<number>(Date.now());
  const step = session.step;

  useEffect(() => {
    setRevealed(false);
    setPicked(null);
    shownAt.current = Date.now();
  }, [step?.card.id, step?.kind]);

  if (session.isComplete) {
    return <SessionSummary reviewed={session.reviewedCount} accuracy={session.accuracy} onDone={() => router.back()} />;
  }
  if (!step) return null;

  const elapsed = () => Date.now() - shownAt.current;

  function choose(index: number) {
    if (picked !== null) return;
    setPicked(index);
    const correct = index === step!.answerIndex;
    const ms = elapsed();
    setTimeout(() => session.answer(correct, ms), 620);
  }

  return (
    <div className="mx-auto flex min-h-dvh max-w-xl flex-col px-5 py-5">
      {/* Top bar */}
      <div className="flex items-center gap-3 safe-top">
        <button
          onClick={() => setLeaving(true)}
          aria-label="Leave"
          className="flex h-9 w-9 items-center justify-center rounded-full text-ink-muted transition hover:bg-surface"
        >
          <X size={22} />
        </button>
        <div className="h-2 flex-1 overflow-hidden rounded-full bg-surface">
          <div
            className="h-full rounded-full bg-accent transition-all duration-300"
            style={{ width: `${Math.round(session.progress * 100)}%` }}
          />
        </div>
        <span className="text-sm font-semibold tabular-nums text-ink-muted">
          {t("study_progress", { current: session.retiredCount, total: session.plannedTotal })}
        </span>
      </div>

      {practiceOnly && (
        <p className="mt-4 rounded-2xl bg-hue-sky/12 px-4 py-2.5 text-center text-sm text-ink-muted">
          {t("study_nothing_due_body")}
        </p>
      )}

      {/* Prompt card */}
      <div className="flex flex-1 items-center justify-center py-6">
        <div className="w-full rounded-3xl border border-border bg-card p-8 text-center shadow-card">
          <button
            onClick={() => speak(step.card.word, step.card.sourceLanguage)}
            className="mx-auto flex items-center gap-2.5 text-[34px] font-bold leading-tight text-ink"
          >
            {step.card.word}
            <Volume2 size={24} className="text-ink-muted" />
          </button>
          {step.card.level && (
            <div className="mt-3 flex justify-center">
              <Chip>{step.card.level}</Chip>
            </div>
          )}
          {step.kind === "recall" && revealed && (
            <div className="mt-6 border-t border-border pt-5">
              <p className="text-2xl font-semibold text-accent">{step.card.translation}</p>
            </div>
          )}
        </div>
      </div>

      {/* Answer area */}
      {step.kind === "choice" ? (
        <div className="space-y-2.5 pb-4">
          <p className="mb-1 text-center text-sm font-medium text-ink-muted">{t("study_choice_prompt")}</p>
          {step.options.map((opt, i) => (
            <button
              key={i}
              onClick={() => choose(i)}
              className={cn(
                "flex h-14 w-full items-center justify-between rounded-2xl border px-5 text-left font-semibold transition",
                picked === null && "border-border bg-card text-ink hover:border-ink-muted/40",
                picked !== null && i === step.answerIndex && "border-success bg-success/12 text-ink",
                picked !== null && i === picked && i !== step.answerIndex && "border-error bg-error/12 text-ink",
                picked !== null && i !== picked && i !== step.answerIndex && "border-border bg-card opacity-55",
              )}
            >
              {opt}
              {picked !== null && i === step.answerIndex && <Check size={20} className="text-success" />}
            </button>
          ))}
        </div>
      ) : (
        <div className="pb-4">
          {!revealed ? (
            <Button variant="secondary" size="lg" fullWidth onClick={() => setRevealed(true)}>
              {t("study_tap_to_reveal")}
            </Button>
          ) : (
            <div className="flex gap-3">
              <Button variant="danger" size="lg" fullWidth onClick={() => session.answer(false, elapsed())}>
                {t("study_forgot")}
              </Button>
              <Button variant="primary" size="lg" fullWidth onClick={() => session.answer(true, elapsed())}>
                {t("study_got_it")}
              </Button>
            </div>
          )}
        </div>
      )}

      <ConfirmSheet
        open={leaving}
        onClose={() => setLeaving(false)}
        title={t("study_leave_title")}
        message={session.remaining === 1 ? t("study_leave_body_one") : t("study_leave_body", { count: session.remaining })}
        cancelLabel={t("study_leave_keep_going")}
        confirmLabel={t("study_leave_confirm")}
        danger
        onConfirm={() => {
          session.finish();
          router.back();
        }}
      />
    </div>
  );
}

function SessionSummary({ reviewed, accuracy, onDone }: { reviewed: number; accuracy: number; onDone: () => void }) {
  const t = useT();
  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col items-center justify-center gap-5 px-6 text-center">
      <ProgressRing value={accuracy} size={132} stroke={11} trackClassName="text-surface" barClassName="text-accent">
        <span className="text-3xl font-bold text-ink">{Math.round(accuracy * 100)}%</span>
        <span className="text-xs text-ink-muted">{t("study_accuracy")}</span>
      </ProgressRing>
      <div>
        <h1 className="text-2xl font-bold text-ink">{t("study_complete_title")}</h1>
        <p className="mt-1 text-ink-muted">{t("study_complete_body", { count: reviewed })}</p>
      </div>
      <Button variant="primary" size="lg" fullWidth className="max-w-xs" onClick={onDone}>
        {t("study_done")}
      </Button>
    </div>
  );
}
