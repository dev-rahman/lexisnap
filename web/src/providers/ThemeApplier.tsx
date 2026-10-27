import { useEffect } from "react";

import { useAppSelector } from "@/store/hooks";

/** Reflects the persisted theme choice onto <html data-theme>. System mode
 *  follows the OS and updates live when it changes. */
export function ThemeApplier() {
  const theme = useAppSelector((s) => s.prefs.theme);

  useEffect(() => {
    const root = document.documentElement;
    const mql = window.matchMedia("(prefers-color-scheme: dark)");

    const apply = () => {
      const resolved =
        theme === "system" ? (mql.matches ? "dark" : "light") : theme;
      root.setAttribute("data-theme", resolved);
      const meta = document.querySelector('meta[name="theme-color"]');
      if (meta) {
        meta.setAttribute("content", resolved === "dark" ? "#101322" : "#F15A32");
      }
    };

    apply();
    if (theme === "system") {
      mql.addEventListener("change", apply);
      return () => mql.removeEventListener("change", apply);
    }
  }, [theme]);

  return null;
}
