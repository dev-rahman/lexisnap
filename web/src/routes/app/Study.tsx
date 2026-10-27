import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { StudySessionView } from "@/components/study/StudySessionView";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { FullPageSpinner } from "@/components/ui/Spinner";
import type { Flashcard, StudyMode } from "@/lib/data/models";
import { isDue } from "@/lib/data/models";
import * as repo from "@/lib/data/repo";
import { useT } from "@/providers/I18nProvider";
import { useAppSelector } from "@/store/hooks";

export function Study() {
  const t = useT();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const studyMode = useAppSelector((s) => s.prefs.studyMode);
  const dailyGoal = useAppSelector((s) => s.streak.dailyGoal);

  const deckId = params.get("deck");
  const mixed = params.get("mixed") === "1";
  const practiceParam = params.get("practice") === "1";

  const [cards, setCards] = useState<Flashcard[] | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        if (deckId) {
          const { flashcards } = await repo.getDeck(deckId);
          if (!cancelled) setCards(flashcards);
        } else {
          // Mixed review across all decks.
          const due = await repo.listDueFlashcards(200);
          if (due.length > 0 && !practiceParam) {
            if (!cancelled) setCards(due);
          } else {
            const upcoming = await repo.listUpcomingFlashcards(60);
            if (!cancelled) setCards([...due, ...upcoming]);
          }
        }
      } catch {
        if (!cancelled) setCards([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [deckId, mixed, practiceParam]);

  if (cards === null) return <FullPageSpinner />;

  if (cards.length === 0) {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center bg-paper px-6">
        <EmptyState
          emoji="✅"
          title={t("study_nothing_due_title")}
          description={t("study_nothing_due_body")}
          action={
            <Button onClick={() => navigate("/home", { replace: true })}>
              {t("study_done")}
            </Button>
          }
        />
      </div>
    );
  }

  const hasDue = cards.some((c) => isDue(c));
  const practiceOnly = practiceParam || !hasDue;
  const mode: StudyMode = studyMode === "listen" ? "smart" : studyMode;
  const cap = Math.max(dailyGoal, 20);

  return (
    <StudySessionView cards={cards} cap={cap} mode={mode} practiceOnly={practiceOnly} />
  );
}
