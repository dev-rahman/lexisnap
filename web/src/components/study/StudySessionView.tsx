import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Volume2, X } from "lucide-react";

import type { Flashcard, StudyMode } from "@/lib/data/models";
import { speak } from "@/lib/services/tts";
import { useStudySession } from "@/lib/hooks/useStudySession";
import { Button } from "@/components/ui/Button";
import { Confetti } from "@/components/ui/Confetti";
import { ProgressRing } from "@/components/ui/ProgressRing";
import { StreakFlame } from "@/components/streak/StreakFlame";
import { Sheet } from "@/components/ui/Sheet";
import { useStreakView } from "@/lib/hooks/useStreakView";
import { useT } from "@/providers/I18nProvider";
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
  const navigate = useNavigate();
  const session = useStudySession({ cards, cap, mode, practiceOnly });
  const [confirmLeave, setConfirmLeave] = useState(false);

  if (session.isComplete) {
    return <Celebration session={session} practiceOnly={practiceOnly} />;
  }

  const step = session.step;
  if (!step) return null;

  return (
    <div className="flex min-h-dvh flex-col bg-paper safe-top">
      {/* Progress bar */}
      <div className="flex items-center gap-3 px-4 py-3">
        <button
          onClick={() => setConfirmLeave(true)}
          aria-label={t("common_cancel")}
          className="grid h-10 w-10 shrink-0 place-items-center rounded-full text-ink-soft hover:bg-ink/5"
        >
          <X size={22} />
        </button>
        <div className="h-3 flex-1 overflow-hidden rounded-full bg-ink/10">
          <div
            className="h-full rounded-full bg-gradient-to-r from-coral to-flame transition-[width] duration-500"
            style={{ width: `${Math.round(session.progress * 100)}%` }}
          />
        </div>
        <span className="shrink-0 font-display text-sm font-bold text-ink-muted">
          {session.retiredCount}/{session.plannedTotal}
        </span>
      </div>

      <div className="mx-auto flex w-full max-w-focus flex-1 flex-col px-4 pb-8">
        {step.kind === "choice" ? (
          <ChoiceStep key={session.retiredCount + "-" + step.card.id} step={step} session={session} />
        ) : (
          <RecallStep key={session.retiredCount + "-" + step.card.id} step={step} session={session} />
        )}
      </div>

      <Sheet
        open={confirmLeave}
        onClose={() => setConfirmLeave(false)}
        title={t("study_leave_title")}
        footer={
          <div className="flex gap-3">
            <Button variant="ghost" fullWidth onClick={() => setConfirmLeave(false)}>
              {t("study_leave_keep_going")}
            </Button>
            <Button variant="danger" fullWidth onClick={() => navigate(-1)}>
              {t("study_leave_confirm")}
            </Button>
          </div>
        }
      >
        <p className="text-ink-muted">{t("study_leave_body")}</p>
      </Sheet>
    </div>
  );
}

type Session = ReturnType<typeof useStudySession>;

function SpeakButton({ text, lang }: { text: string; lang: string | null }) {
  return (
    <button
      onClick={() => speak(text, lang)}
      className="grid h-10 w-10 place-items-center rounded-full bg-ink/5 text-ink-soft hover:bg-coral-soft hover:text-coral"
      aria-label="Listen"
    >
      <Volume2 size={20} />
    </button>
  );
}

function ChoiceStep({ step, session }: { step: NonNullable<Session["step"]>; session: Session }) {
  const t = useT();
  const start = useRef(performance.now());
  const [chosen, setChosen] = useState<number | null>(null);
  const locked = chosen != null;

  useEffect(() => {
    start.current = performance.now();
  }, [step.card.id]);

  function choose(i: number) {
    if (locked) return;
    setChosen(i);
    const correct = i === step.answerIndex;
    const elapsed = performance.now() - start.current;
    setTimeout(() => session.answer(correct, elapsed), correct ? 650 : 1100);
  }

  return (
    <div className="flex flex-1 flex-col">
      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <p className="mb-3 text-sm font-medium text-ink-muted">
          {t("study_choice_prompt")}
        </p>
        <div className="flex items-center gap-3">
          <h2 className="font-display text-4xl font-bold text-ink">{step.card.word}</h2>
          <SpeakButton text={step.card.word} lang={step.card.sourceLanguage} />
        </div>
        {step.card.level && (
          <span className="mt-3 rounded-full bg-coral-soft px-3 py-0.5 text-xs font-bold text-coral">
            {step.card.level}
          </span>
        )}
      </div>

      <div className="grid gap-3">
        {step.options.map((opt, i) => {
          const isAnswer = i === step.answerIndex;
          const state = !locked
            ? "idle"
            : isAnswer
              ? "correct"
              : i === chosen
                ? "wrong"
                : "dim";
          return (
            <button
              key={i}
              onClick={() => choose(i)}
              disabled={locked}
              className={cn(
                "btn3d h-auto min-h-[3.5rem] justify-start px-5 py-3 text-left text-[17px] font-bold",
                state === "idle" &&
                  "bg-card text-ink border border-border shadow-soft hover:border-coral/40",
                state === "correct" && "bg-success text-white animate-pop-in",
                state === "wrong" && "bg-error text-white animate-shake",
                state === "dim" && "bg-card text-ink-muted border border-border opacity-50",
              )}
            >
              {opt}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function RecallStep({ step, session }: { step: NonNullable<Session["step"]>; session: Session }) {
  const t = useT();
  const start = useRef(performance.now());
  const [revealed, setRevealed] = useState(false);

  useEffect(() => {
    start.current = performance.now();
    setRevealed(false);
  }, [step.card.id]);

  function grade(recalled: boolean) {
    session.answer(recalled, performance.now() - start.current);
  }

  return (
    <div className="flex flex-1 flex-col">
      <button
        onClick={() => !revealed && setRevealed(true)}
        className="group flex flex-1 items-center justify-center py-4"
        style={{ perspective: 1200 }}
      >
        <div
          className={cn(
            "relative w-full max-w-sm rounded-[2rem] border-2 border-border bg-card p-8 text-center shadow-card transition-transform duration-500",
          )}
        >
          <div className="flex items-center justify-center gap-3">
            <h2 className="font-display text-4xl font-bold text-ink">{step.card.word}</h2>
            <SpeakButton text={step.card.word} lang={step.card.sourceLanguage} />
          </div>
          {!revealed ? (
            <p className="mt-6 text-sm font-semibold text-ink-muted">
              {t("study_tap_to_reveal")}
            </p>
          ) : (
            <div className="mt-6 animate-[rise-in_0.3s_ease-out] border-t border-border pt-5">
              <p className="font-display text-2xl font-bold text-coral">
                {step.card.translation}
              </p>
              {step.card.wordDescription && (
                <p className="mt-2 text-sm text-ink-muted">{step.card.wordDescription}</p>
              )}
            </div>
          )}
        </div>
      </button>

      {revealed ? (
        <div className="grid grid-cols-2 gap-3">
          <Button variant="danger" size="lg" onClick={() => grade(false)}>
            {t("study_forgot")}
          </Button>
          <Button variant="success" size="lg" onClick={() => grade(true)}>
            {t("study_got_it")}
          </Button>
        </div>
      ) : (
        <Button fullWidth size="lg" onClick={() => setRevealed(true)}>
          {t("study_tap_to_reveal")}
        </Button>
      )}
    </div>
  );
}

function Celebration({
  session,
  practiceOnly,
}: {
  session: Session;
  practiceOnly: boolean;
}) {
  const t = useT();
  const navigate = useNavigate();
  const { streak } = useStreakView();
  const accuracy = Math.round(session.accuracy * 100);

  return (
    <div className="app-wash relative flex min-h-dvh flex-col items-center justify-center bg-paper px-6 text-center safe-top">
      <Confetti />
      <div className="mb-6 grid h-28 w-28 animate-pop-in place-items-center rounded-[2rem] bg-gradient-to-br from-coral to-flame text-7xl shadow-card-lift">
        🎉
      </div>
      <h1 className="font-display text-3xl font-bold text-ink">
        {t("study_complete_title")}
      </h1>
      <p className="mt-1 text-ink-muted">{t("study_complete_body")}</p>

      <div className="mt-8 flex items-center gap-8">
        <ProgressRing
          progress={session.accuracy}
          size={120}
          stroke={12}
          barClassName="text-success"
          trackClassName="text-ink/10"
        >
          <div>
            <div className="font-display text-3xl font-bold text-ink">{accuracy}%</div>
            <div className="text-xs font-medium text-ink-muted">
              {t("study_accuracy")}
            </div>
          </div>
        </ProgressRing>

        {!practiceOnly && (
          <div className="flex flex-col items-center">
            <StreakFlame count={streak.current} size={64} />
            <div className="mt-1 font-display text-3xl font-bold text-ink">
              {streak.current}
            </div>
            <div className="text-xs font-medium text-ink-muted">
              {t("study_streak_days", { count: streak.current })}
            </div>
          </div>
        )}
      </div>

      <div className="mt-10 w-full max-w-xs">
        <Button fullWidth size="lg" onClick={() => navigate("/home", { replace: true })}>
          {t("study_done")}
        </Button>
      </div>
    </div>
  );
}
