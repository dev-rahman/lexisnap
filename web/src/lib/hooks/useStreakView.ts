import { useMemo } from "react";

import {
  daysToNextFreeze,
  goalMet,
  goalProgress,
  justCovered,
  week,
  type StreakDay,
  type StudyStreak,
} from "@/lib/domain/streakRules";
import { streakToDomain } from "@/lib/domain/streakSerialize";
import { useAppSelector } from "@/store/hooks";

export interface StreakView {
  streak: StudyStreak;
  week: StreakDay[];
  justCovered: number;
  daysToNextFreeze: number | null;
  goalMet: boolean;
  goalProgress: number;
}

/** Derives the display-ready streak from the persisted slice. */
export function useStreakView(): StreakView {
  const state = useAppSelector((s) => s.streak);
  return useMemo(() => {
    const now = new Date();
    const streak = streakToDomain(state);
    return {
      streak,
      week: week(streak, now),
      justCovered: justCovered(streak, now),
      daysToNextFreeze: daysToNextFreeze(streak),
      goalMet: goalMet(streak),
      goalProgress: goalProgress(streak),
    };
  }, [state]);
}
