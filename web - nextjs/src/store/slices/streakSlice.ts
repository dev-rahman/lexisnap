// Study-day streaks + today's review count — on-device only (persisted), as
// in the Flutter StreakService. All the rules live in the pure streakRules
// module; this slice owns storage/serialisation and timing only.

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

import { DEFAULT_DAILY_GOAL, reconcile, recordStudy } from "@/lib/domain/streakRules";
import {
  streakToDomain as toDomain,
  streakToState as toState,
  type SerializableStreak,
} from "@/lib/domain/streakSerialize";

/** Serialisable mirror of StudyStreak (Dates as ISO strings). */
export type StreakState = SerializableStreak;

const initialState: StreakState = {
  current: 0,
  longest: 0,
  reviewsToday: 0,
  dailyGoal: DEFAULT_DAILY_GOAL,
  lastStudiedAt: null,
  recentStudyDays: [],
  freezes: 0,
  frozenDays: [],
};

const streakSlice = createSlice({
  name: "streak",
  initialState,
  reducers: {
    /** Run on launch/resume: settle any missed days before showing numbers. */
    reconcileNow(state) {
      const next = reconcile(toDomain(state), new Date());
      return toState(next);
    },
    /** Fold finished reviews into today's tally. */
    recordReviews(state, action: PayloadAction<number>) {
      const count = action.payload;
      if (count <= 0) return state;
      const now = new Date();
      const next = recordStudy(reconcile(toDomain(state), now), now, count);
      return toState(next);
    },
    setDailyGoal(state, action: PayloadAction<number>) {
      state.dailyGoal = Math.min(100, Math.max(5, action.payload));
    },
    resetStreak() {
      return initialState;
    },
  },
});

export const { reconcileNow, recordReviews, setDailyGoal, resetStreak } =
  streakSlice.actions;
export default streakSlice.reducer;
