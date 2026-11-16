// Authed shell UI state: which bottom-nav tab is active, and whether the nav
// bar is minimised on scroll. Mirrors MainController in the Flutter app.

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

export type ShellTab = "home" | "decks";

export interface ShellState {
  tab: ShellTab;
  navBarMinimized: boolean;
}

const initialState: ShellState = { tab: "home", navBarMinimized: false };

const shellSlice = createSlice({
  name: "shell",
  initialState,
  reducers: {
    setTab(state, action: PayloadAction<ShellTab>) {
      state.tab = action.payload;
    },
    setNavBarMinimized(state, action: PayloadAction<boolean>) {
      state.navBarMinimized = action.payload;
    },
  },
});

export const { setTab, setNavBarMinimized } = shellSlice.actions;
export default shellSlice.reducer;
