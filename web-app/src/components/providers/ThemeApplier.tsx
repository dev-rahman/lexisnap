"use client";

import { useEffect } from "react";

import { useAppSelector } from "@/store/hooks";

/**
 * Reflects the user's theme choice onto <html data-theme>. "system" removes
 * the attribute so the prefers-color-scheme rules in globals.css take over.
 */
export function ThemeApplier() {
  const theme = useAppSelector((s) => s.prefs.theme);

  useEffect(() => {
    const root = document.documentElement;
    if (theme === "system") {
      root.removeAttribute("data-theme");
    } else {
      root.setAttribute("data-theme", theme);
    }
  }, [theme]);

  return null;
}
