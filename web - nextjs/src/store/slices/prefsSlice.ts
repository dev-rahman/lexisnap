// User preferences: theme, UI locale, study mode, onboarding flag.
// Persisted (redux-persist) so they survive reloads — the web equivalent of
// the ThemeService / LocaleService / StudyPreferencesService / OnboardingService
// SharedPreferences stores in the Flutter app.

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

import type { StudyMode } from "@/lib/data/models";
import { FALLBACK_LOCALE, type AppLocale } from "@/lib/i18n";

export type ThemeChoice = "system" | "light" | "dark";

export interface PrefsState {
  theme: ThemeChoice;
  locale: AppLocale;
  studyMode: StudyMode;
  onboardingSeen: boolean;
  reminderEnabled: boolean;
  reminderHour: number;
  reminderMinute: number;
}

const initialState: PrefsState = {
  theme: "system",
  locale: FALLBACK_LOCALE,
  studyMode: "smart",
  onboardingSeen: false,
  reminderEnabled: false,
  reminderHour: 19,
  reminderMinute: 30,
};

const prefsSlice = createSlice({
  name: "prefs",
  initialState,
  reducers: {
    setTheme(state, action: PayloadAction<ThemeChoice>) {
      state.theme = action.payload;
    },
    setLocale(state, action: PayloadAction<AppLocale>) {
      state.locale = action.payload;
    },
    setStudyMode(state, action: PayloadAction<StudyMode>) {
      state.studyMode = action.payload;
    },
    markOnboardingSeen(state) {
      state.onboardingSeen = true;
    },
    setReminder(
      state,
      action: PayloadAction<{ enabled: boolean; hour: number; minute: number }>,
    ) {
      state.reminderEnabled = action.payload.enabled;
      state.reminderHour = action.payload.hour;
      state.reminderMinute = action.payload.minute;
    },
  },
});

export const {
  setTheme,
  setLocale,
  setStudyMode,
  markOnboardingSeen,
  setReminder,
} = prefsSlice.actions;
export default prefsSlice.reducer;
