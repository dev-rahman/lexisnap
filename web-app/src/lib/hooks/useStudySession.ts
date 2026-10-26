"use client";

import { useCallback, useMemo, useRef, useState } from "react";

import type { Flashcard, StudyMode } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { inferGrade, type ReviewGrade } from "@/lib/domain/srs";
import {
  StudySessionEngine,
  type StudyStep,
} from "@/lib/domain/studySessionEngine";
import { markStudiedForReminder } from "@/lib/services/push";
import { decksApi } from "@/store/api/decksApi";
import { useAppDispatch } from "@/store/hooks";
import { recordReviews } from "@/store/slices/streakSlice";

export interface SessionSnapshot {
  step: StudyStep | null;
  isComplete: boolean;
  progress: number;
  reviewedCount: number;
  retiredCount: number;
  accuracy: number;
  plannedTotal: number;
  nothingWasDue: boolean;
  skippedDueCount: number;
  tally: Record<ReviewGrade, number>;
  remaining: number;
}

function snapshot(engine: StudySessionEngine): SessionSnapshot {
  return {
    step: engine.currentStep,
    isComplete: engine.isComplete,
    progress: engine.progress,
    reviewedCount: engine.reviewedCount,
    retiredCount: engine.retiredCount,
    accuracy: engine.accuracy,
    plannedTotal: engine.plannedTotal,
    nothingWasDue: engine.nothingWasDue,
    skippedDueCount: engine.skippedDueCount,
    tally: { ...engine.tally },
    remaining: engine.plannedTotal - engine.retiredCount,
  };
}

/**
 * Drives one study session over [cards] — ports StudySessionView's glue around
 * the engine. Grades are inferred from recall + time, persisted via the
 * repository (unless practiceOnly), and the streak is credited on completion.
 */
export function useStudySession(opts: {
  cards: Flashcard[];
  cap: number;
  mode: StudyMode;
  practiceOnly: boolean;
}) {
  const dispatch = useAppDispatch();
  const engineRef = useRef<StudySessionEngine | null>(null);
  if (!engineRef.current) {
    engineRef.current = new StudySessionEngine({
      deck: opts.cards,
      cap: opts.cap,
      mode: opts.mode,
    });
  }
  const engine = engineRef.current;
  const [snap, setSnap] = useState<SessionSnapshot>(() => snapshot(engine));
  const finishedRef = useRef(false);

  const finish = useCallback(() => {
    if (finishedRef.current) return;
    finishedRef.current = true;
    if (!opts.practiceOnly && engine.retiredCount > 0) {
      dispatch(recordReviews(engine.retiredCount));
      void markStudiedForReminder();
    }
    dispatch(
      decksApi.util.invalidateTags([
        { type: "Due", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Decks", id: "LIST" },
      ]),
    );
  }, [dispatch, engine, opts.practiceOnly]);

  const answer = useCallback(
    async (recalled: boolean, timeToAnswerMs: number) => {
      const step = engine.currentStep;
      if (!step) return;
      const grade = inferGrade(recalled, timeToAnswerMs);
      let updated = step.card;
      if (!opts.practiceOnly) {
        try {
          updated = await repo.submitReview(step.card, grade);
        } catch {
          // Keep the session going even if the write fails.
        }
      }
      engine.complete(updated, grade);
      setSnap(snapshot(engine));
      if (engine.isComplete) finish();
    },
    [engine, opts.practiceOnly, finish],
  );

  return useMemo(() => ({ ...snap, answer, finish }), [snap, answer, finish]);
}
