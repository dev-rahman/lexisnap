"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { Volume2, X } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { ConfirmSheet } from "@/components/ui/Sheet";
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

  // Reset per-step interaction state and the answer timer.
  useEffect(() => {
    setRevealed(false);
    setPicked(null);
    shownAt.current = Date.now();
  }, [step?.card.id, step?.kind]);

  if (session.isComplete) {
    return (
      <SessionSummary
        reviewed={session.reviewedCount}
        accuracy={session.accuracy}
        onDone={() => router.back()}
      />
    );
  }
  if (!step) return null;

  const elapsed = () => Date.now() - shownAt.current;

  async function choose(index: number) {
    if (picked !== null) return;
    setPicked(index);
    const correct = index === step!.answerIndex;
    const ms = elapsed();
    setTimeout(() => session.answer(correct, ms), 650);
  }

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col px-5 py-4">
      {/* Top bar: leave + progress */}
      <div className="flex items-center gap-3 safe-top">
        <button onClick={() => setLeaving(true)} aria-label="Leave" className="text-ink-muted">
          <X size={24} />
        </button>
        <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-surface">
          <div
            className="h-full rounded-full bg-accent transition-all"
            style={{ width: `${Math.round(session.progress * 100)}%` }}
          />
        </div>
        <span className="text-sm tabular-nums text-ink-muted">
          {t("study_progress", {
            current: session.retiredCount,
            total: session.plannedTotal,
          })}
        </span>
      </div>

      {practiceOnly && (
        <p className="mt-3 rounded-md bg-hue-sky/15 px-3 py-2 text-center text-sm text-ink-muted">
          {t("study_nothing_due_body")}
        </p>
      )}

      {/* Prompt */}
      <div className="flex flex-1 flex-col items-center justify-center">
        <button
          onClick={() => speak(step.card.word, step.card.sourceLanguage)}
          className="mb-2 flex items-center gap-2 text-3xl font-bold text-ink"
        >
          {step.card.word}
          <Volume2 size={22} className="text-ink-muted" />
        </button>
        {step.card.level && (
          <span className="rounded-full bg-surface px-2 py-0.5 text-xs font-semibold text-ink-muted">
            {step.card.level}
          </span>
        )}

        {step.kind === "recall" && revealed && (
          <p className="mt-6 text-2xl font-semibold text-accent">
            {step.card.translation}
          </p>
        )}
      </div>

      {/* Answer area */}
      {step.kind === "choice" ? (
        <div className="grid grid-cols-1 gap-2.5 pb-6">
          <p className="mb-1 text-center text-sm text-ink-muted">{t("study_choice_prompt")}</p>
          {step.options.map((opt, i) => (
            <button
              key={i}
              onClick={() => choose(i)}
              className={cn(
                "h-14 rounded-md border px-4 text-left font-medium transition",
                picked === null && "border-border bg-surface text-ink",
                picked !== null && i === step.answerIndex && "border-success bg-success/15 text-ink",
                picked !== null && i === picked && i !== step.answerIndex && "border-error bg-error/15 text-ink",
                picked !== null && i !== picked && i !== step.answerIndex && "border-border bg-surface opacity-60",
              )}
            >
              {opt}
            </button>
          ))}
        </div>
      ) : (
        <div className="pb-6">
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
        message={
          session.remaining === 1
            ? t("study_leave_body_one")
            : t("study_leave_body", { count: session.remaining })
        }
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

function SessionSummary({
  reviewed,
  accuracy,
  onDone,
}: {
  reviewed: number;
  accuracy: number;
  onDone: () => void;
}) {
  const t = useT();
  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col items-center justify-center gap-4 px-6 text-center">
      <div className="text-5xl">🎉</div>
      <h1 className="text-2xl font-bold text-ink">{t("study_complete_title")}</h1>
      <p className="text-ink-muted">{t("study_complete_body", { count: reviewed })}</p>
      <div className="my-2 rounded-xl bg-surface px-6 py-3">
        <div className="text-3xl font-bold text-accent">{Math.round(accuracy * 100)}%</div>
        <div className="text-xs text-ink-muted">{t("study_accuracy")}</div>
      </div>
      <Button variant="primary" size="lg" fullWidth onClick={onDone}>
        {t("study_done")}
      </Button>
    </div>
  );
}
