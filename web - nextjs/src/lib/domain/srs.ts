// Port of lib/app/core/utils/spaced_repetition.dart and
// lib/app/data/models/review_grade.dart — SM-2, the algorithm behind Anki.

import { dueDateAfter } from "./studyDay";

/** Four-level recall scale (Anki). Users never pick it; it's inferred. */
export type ReviewGrade = "again" | "hard" | "good" | "easy";

const QUICK_THRESHOLD_MS = 4000;
const LABORED_THRESHOLD_MS = 10000;

/**
 * Maps a yes/no answer plus the time-to-answer (ms) onto the four-level
 * scale. Quick correct answers are genuinely known (easy); slow ones were
 * reconstructed (good/hard); a miss is always `again`.
 */
export function inferGrade(recalled: boolean, timeToAnswerMs: number): ReviewGrade {
  if (!recalled) return "again";
  if (timeToAnswerMs <= QUICK_THRESHOLD_MS) return "easy";
  if (timeToAnswerMs <= LABORED_THRESHOLD_MS) return "good";
  return "hard";
}

export interface SrsState {
  easeFactor: number;
  intervalDays: number;
  repetitions: number;
}

export interface SrsUpdate extends SrsState {
  dueAt: Date;
}

const GRADE_QUALITY: Record<ReviewGrade, number> = {
  again: 0,
  hard: 3,
  good: 4,
  easy: 5,
};

/**
 * The next scheduling state for a flashcard. Due dates land on study-day
 * boundaries rather than the exact review time — see studyDay.ts.
 */
export function calculateNextReview(
  state: SrsState,
  grade: ReviewGrade,
  now: Date = new Date(),
): SrsUpdate {
  const quality = GRADE_QUALITY[grade];

  let newEaseFactor =
    state.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  newEaseFactor = Math.max(1.3, newEaseFactor);

  let newRepetitions: number;
  let newIntervalDays: number;
  if (quality < 3) {
    // A lapse stays due today so it can be re-earned in the same sitting.
    newRepetitions = 0;
    newIntervalDays = 0;
  } else {
    newRepetitions = state.repetitions + 1;
    if (newRepetitions === 1) {
      newIntervalDays = 1;
    } else if (newRepetitions === 2) {
      newIntervalDays = 6;
    } else {
      newIntervalDays = Math.round(state.intervalDays * newEaseFactor);
    }
  }

  return {
    easeFactor: newEaseFactor,
    intervalDays: newIntervalDays,
    repetitions: newRepetitions,
    dueAt: dueDateAfter(now, newIntervalDays),
  };
}
