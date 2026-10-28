// Authed shell UI state: which bottom-nav tab is active, and whether the nav
// bar is minimised on scroll. Mirrors MainController in the Flutter app.

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

export type ShellTab = "home" | "decks";

export interface ShellState {
  tab: ShellTab;
  navBarMinimized: boolean;
  /** The "take photo / choose image" scan picker dialog. */
  scanPickerOpen: boolean;
  /** Hide the floating bottom nav (e.g. while a contextual action bar — like
   *  deck multi-select — occupies the bottom). */
  bottomNavHidden: boolean;
}

const initialState: ShellState = {
  tab: "home",
  navBarMinimized: false,
  scanPickerOpen: false,
  bottomNavHidden: false,
};

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
    openScanPicker(state) {
      state.scanPickerOpen = true;
    },
    closeScanPicker(state) {
      state.scanPickerOpen = false;
    },
    setBottomNavHidden(state, action: PayloadAction<boolean>) {
      state.bottomNavHidden = action.payload;
    },
  },
});

export const {
  setTab,
  setNavBarMinimized,
  openScanPicker,
  closeScanPicker,
  setBottomNavHidden,
} = shellSlice.actions;
export default shellSlice.reducer;
