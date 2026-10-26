// Converts between the serialisable streak state (ISO strings, for Redux /
// redux-persist) and the Date-based StudyStreak the pure rules operate on.

import type { StudyStreak } from "./streakRules";

export interface SerializableStreak {
  current: number;
  longest: number;
  reviewsToday: number;
  dailyGoal: number;
  lastStudiedAt: string | null;
  recentStudyDays: string[];
  freezes: number;
  frozenDays: string[];
}

export function streakToDomain(s: SerializableStreak): StudyStreak {
  return {
    current: s.current,
    longest: s.longest,
    reviewsToday: s.reviewsToday,
    dailyGoal: s.dailyGoal,
    lastStudiedAt: s.lastStudiedAt ? new Date(s.lastStudiedAt) : null,
    recentStudyDays: s.recentStudyDays.map((d) => new Date(d)),
    freezes: s.freezes,
    frozenDays: s.frozenDays.map((d) => new Date(d)),
  };
}

export function streakToState(s: StudyStreak): SerializableStreak {
  return {
    current: s.current,
    longest: s.longest,
    reviewsToday: s.reviewsToday,
    dailyGoal: s.dailyGoal,
    lastStudiedAt: s.lastStudiedAt ? s.lastStudiedAt.toISOString() : null,
    recentStudyDays: s.recentStudyDays.map((d) => d.toISOString()),
    freezes: s.freezes,
    frozenDays: s.frozenDays.map((d) => d.toISOString()),
  };
}
