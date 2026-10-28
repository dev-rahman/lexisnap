import { Home, Layers, ScanLine } from "lucide-react";
import { NavLink } from "react-router-dom";

import { useT } from "@/providers/I18nProvider";
import { useAppDispatch } from "@/store/hooks";
import { openScanPicker } from "@/store/slices/shellSlice";
import { cn } from "@/lib/utils/cn";

/** Floating rounded bottom tab bar, shown on every breakpoint, with a centered
 *  coral Scan button. Calm — a soft shadow, no chunky 3D lip. */
export function BottomNav() {
  const t = useT();
  const dispatch = useAppDispatch();

  const tab = ({ isActive }: { isActive: boolean }) =>
    cn(
      "flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-semibold transition-colors",
      isActive ? "text-coral" : "text-ink-muted hover:text-ink",
    );

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-40 flex justify-center pb-safe">
      <nav className="pointer-events-auto relative mx-4 mb-4 flex w-full max-w-sm items-center rounded-full border border-border bg-card/90 px-3 shadow-card-lift backdrop-blur-md">
        <NavLink to="/home" className={tab}>
          <Home size={21} strokeWidth={2} />
          {t("nav_home")}
        </NavLink>

        <div className="flex w-20 justify-center">
          <button
            onClick={() => dispatch(openScanPicker())}
            aria-label={t("nav_scan")}
            className="btn3d -mt-6 h-14 w-14 rounded-full bg-coral text-white shadow-pop"
          >
            <ScanLine size={24} />
          </button>
        </div>

        <NavLink to="/decks" className={tab}>
          <Layers size={21} strokeWidth={2} />
          {t("nav_decks")}
        </NavLink>
      </nav>
    </div>
  );
}
