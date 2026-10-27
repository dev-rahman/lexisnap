import { Home, Layers, ScanLine } from "lucide-react";
import { NavLink, useNavigate } from "react-router-dom";

import { useT } from "@/providers/I18nProvider";
import { cn } from "@/lib/utils/cn";

/** Floating rounded bottom tab bar (mobile <768px) with a centered coral Scan
 *  FAB that lifts above the bar. */
export function BottomNav() {
  const t = useT();
  const navigate = useNavigate();

  const tab = ({ isActive }: { isActive: boolean }) =>
    cn(
      "flex flex-1 flex-col items-center gap-0.5 py-2 text-[11px] font-bold transition-colors",
      isActive ? "text-coral" : "text-ink-muted",
    );

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-40 flex justify-center pb-safe md:hidden">
      <nav className="pointer-events-auto relative mx-4 mb-3 flex w-full max-w-sm items-center rounded-full border border-border bg-card/95 px-3 shadow-card-lift backdrop-blur">
        <NavLink to="/home" className={tab}>
          <Home size={22} />
          {t("nav_home")}
        </NavLink>

        <div className="flex w-20 justify-center">
          <button
            onClick={() => navigate("/scan")}
            aria-label={t("nav_scan")}
            className="btn3d -mt-7 h-16 w-16 rounded-full bg-coral text-white shadow-[0_5px_0_rgb(var(--coral-dark)),0_12px_24px_-6px_rgb(var(--coral)/0.6)] active:shadow-[0_1px_0_rgb(var(--coral-dark))]"
          >
            <ScanLine size={26} />
          </button>
        </div>

        <NavLink to="/decks" className={tab}>
          <Layers size={22} />
          {t("nav_decks")}
        </NavLink>
      </nav>
    </div>
  );
}
