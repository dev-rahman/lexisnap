// Reactive auth state. Not persisted — the Supabase client owns the session;
// this slice just mirrors the current user into the component tree (the web
// equivalent of GetX's UserService Rxn<AppUser>).

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

import type { AppUser } from "@/lib/data/models";

export interface AuthState {
  user: AppUser | null;
  /** false until the first onAuthStateChange / getUser resolves. */
  initialized: boolean;
}

const initialState: AuthState = { user: null, initialized: false };

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setUser(state, action: PayloadAction<AppUser | null>) {
      state.user = action.payload;
      state.initialized = true;
    },
  },
});

export const { setUser } = authSlice.actions;
export default authSlice.reducer;
