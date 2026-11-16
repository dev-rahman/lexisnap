"use client";

import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

import { StudySessionView } from "@/components/study/StudySessionView";
import { Spinner } from "@/components/ui/Spinner";
import type { Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { DUE_QUEUE_LIMIT } from "@/store/api/decksApi";
import { useAppSelector } from "@/store/hooks";

/**
 * Review/practice session. `mode=due|practice` or `deck=<id>` chooses the
 * card set; the engine (via StudySessionView) handles ordering and kind.
 */
export default function StudyPage() {
  const params = useSearchParams();
  const mode = params.get("mode");
  const deckId = params.get("deck");
  const dailyGoal = useAppSelector((s) => s.streak.dailyGoal);
  const studyMode = useAppSelector((s) => s.prefs.studyMode);
  // Listen mode has its own route; fall back to smart here.
  const mode2 = studyMode === "listen" ? "smart" : studyMode;

  const [cards, setCards] = useState<Flashcard[] | null>(null);
  const practiceOnly = mode === "practice";
  const cap = practiceOnly ? 10 : dailyGoal;

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        let result: Flashcard[];
        if (deckId) {
          const { flashcards } = await repo.getDeck(deckId);
          result = flashcards;
        } else if (practiceOnly) {
          result = await repo.listUpcomingFlashcards(10);
        } else {
          result = await repo.listDueFlashcards(DUE_QUEUE_LIMIT);
        }
        if (active) setCards(result);
      } catch {
        if (active) setCards([]);
      }
    })();
    return () => {
      active = false;
    };
  }, [deckId, practiceOnly]);

  if (!cards) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-paper">
        <Spinner className="text-accent" />
      </div>
    );
  }

  return (
    <StudySessionView
      cards={cards}
      cap={cap}
      mode={mode2}
      practiceOnly={practiceOnly}
    />
  );
}
