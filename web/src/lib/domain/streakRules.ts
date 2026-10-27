// Port of lib/app/core/services/streak/streak_rules.dart.
//
// The streak's rules as pure functions of a StudyStreak and a moment in
// time — kept free of storage so the date arithmetic (the part most likely
// to be off by exactly one day) can be tested directly. Freezes make one or
// two missed days recoverable; they are earned by studying, never bought.

import { studyDayOffset, studyDayStart, studyDaysBetween } from "./studyDay";

export type StreakDay = "studied" | "frozen" | "missed";

export const DEFAULT_DAILY_GOAL = 20;
export const MAX_FREEZES = 2;
export const DAYS_PER_FREEZE = 7;
export const HISTORY_LENGTH = 14;

export interface StudyStreak {
  current: number;
  longest: number;
  reviewsToday: number;
  dailyGoal: number;
  lastStudiedAt: Date | null;
  /** Study days the user studied on, newest first. */
  recentStudyDays: Date[];
  freezes: number;
  /** Study days a freeze covered, newest first. */
  frozenDays: Date[];
}

export function emptyStreak(): StudyStreak {
  return {
    current: 0,
    longest: 0,
    reviewsToday: 0,
    dailyGoal: DEFAULT_DAILY_GOAL,
    lastStudiedAt: null,
    recentStudyDays: [],
    freezes: 0,
    frozenDays: [],
  };
}

export function goalMet(s: StudyStreak): boolean {
  return s.reviewsToday >= s.dailyGoal;
}

export function goalProgress(s: StudyStreak): number {
  if (s.dailyGoal <= 0) return 1;
  return Math.min(1, Math.max(0, s.reviewsToday / s.dailyGoal));
}

function trim(days: Date[], today: Date): Date[] {
  return days.filter((d) => studyDaysBetween(d, today) < HISTORY_LENGTH);
}

/** The most recent study day the streak was alive on, studied or frozen. */
export function lastActiveDay(s: StudyStreak): Date | null {
  const studied = s.lastStudiedAt ? studyDayStart(s.lastStudiedAt) : null;
  const frozen = s.frozenDays.length === 0 ? null : s.frozenDays[0];

  if (studied === null) return frozen;
  if (frozen === null) return studied;
  return frozen.getTime() > studied.getTime() ? frozen : studied;
}

/**
 * Brings [s] up to [now]: resets today's tally on a new study day, then
 * spends banked freezes on every missed day since the streak was last alive
 * — or breaks it if there aren't enough. Idempotent.
 */
export function reconcile(s: StudyStreak, now: Date): StudyStreak {
  const today = studyDayStart(now);
  let next = s;

  if (
    s.lastStudiedAt &&
    studyDaysBetween(s.lastStudiedAt, now) > 0 &&
    s.reviewsToday !== 0
  ) {
    next = { ...next, reviewsToday: 0 };
  }

  const lastActive = lastActiveDay(next);
  if (lastActive === null || next.current === 0) return next;

  const missed = studyDaysBetween(lastActive, today) - 1;
  if (missed <= 0) return next;

  if (missed <= next.freezes) {
    const newFrozen: Date[] = [];
    for (let offset = missed; offset >= 1; offset--) {
      newFrozen.push(studyDayOffset(lastActive, offset));
    }
    return {
      ...next,
      freezes: next.freezes - missed,
      frozenDays: trim([...newFrozen, ...next.frozenDays], today),
    };
  }

  // More days missed than freezes can cover. Freezes are kept, not burned.
  return { ...next, current: 0 };
}

/**
 * Records [count] finished reviews at [now]. Expects [s] to have been
 * reconcile()d for [now] first.
 */
export function recordStudy(s: StudyStreak, now: Date, count: number): StudyStreak {
  if (count <= 0) return s;

  const today = studyDayStart(now);
  const studiedToday =
    s.lastStudiedAt !== null && studyDaysBetween(s.lastStudiedAt, now) === 0;
  const lastActive = lastActiveDay(s);

  let current: number;
  if (studiedToday) {
    current = Math.max(s.current, 1);
  } else if (
    s.current > 0 &&
    lastActive !== null &&
    studyDaysBetween(lastActive, today) === 1
  ) {
    current = s.current + 1;
  } else {
    current = 1;
  }

  const earned = current > s.current && current % DAYS_PER_FREEZE === 0;

  return {
    ...s,
    current,
    longest: Math.max(current, s.longest),
    reviewsToday: (studiedToday ? s.reviewsToday : 0) + count,
    lastStudiedAt: now,
    recentStudyDays: trim(
      [today, ...s.recentStudyDays.filter((d) => studyDaysBetween(d, today) !== 0)],
      today,
    ),
    freezes: earned ? Math.min(s.freezes + 1, MAX_FREEZES) : s.freezes,
  };
}

/** The last seven study days, oldest first, ending on today. */
export function week(s: StudyStreak, now: Date): StreakDay[] {
  const today = studyDayStart(now);
  const contains = (days: Date[], day: Date) =>
    days.some((d) => studyDaysBetween(d, day) === 0);

  const result: StreakDay[] = [];
  for (let back = 6; back >= 0; back--) {
    const day = studyDayOffset(today, -back);
    if (contains(s.recentStudyDays, day)) result.push("studied");
    else if (contains(s.frozenDays, day)) result.push("frozen");
    else result.push("missed");
  }
  return result;
}

/** How many missed days freezes covered in the run ending yesterday. */
export function justCovered(s: StudyStreak, now: Date): number {
  const today = studyDayStart(now);
  let count = 0;
  for (let back = 1; back <= s.frozenDays.length; back++) {
    const day = studyDayOffset(today, -back);
    if (!s.frozenDays.some((d) => studyDaysBetween(d, day) === 0)) break;
    count++;
  }
  return count;
}

/** Study days until the next freeze, or null when the bank is full. */
export function daysToNextFreeze(s: StudyStreak): number | null {
  if (s.freezes >= MAX_FREEZES) return null;
  return DAYS_PER_FREEZE - (s.current % DAYS_PER_FREEZE);
}
