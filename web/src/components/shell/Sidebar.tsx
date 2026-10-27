import { Home, Layers, ScanLine } from "lucide-react";
import { NavLink, useNavigate } from "react-router-dom";

import { BrandMark } from "@/components/brand/BrandMark";
import { Avatar } from "@/components/ui/Avatar";
import { useT } from "@/providers/I18nProvider";
import { useAppSelector } from "@/store/hooks";
import { cn } from "@/lib/utils/cn";

/** Desktop/tablet left rail (≥768px). */
export function Sidebar() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAppSelector((s) => s.auth.user);

  const link = ({ isActive }: { isActive: boolean }) =>
    cn(
      "flex items-center gap-3 rounded-2xl px-4 py-3 font-display text-[15px] font-bold transition-colors",
      isActive
        ? "bg-coral-soft text-coral"
        : "text-ink-soft hover:bg-ink/5 hover:text-ink",
    );

  return (
    <aside className="sticky top-0 hidden h-dvh w-[248px] shrink-0 flex-col border-r border-border bg-card/70 px-4 py-6 backdrop-blur md:flex">
      <div className="px-2">
        <BrandMark />
      </div>

      <nav className="mt-8 flex flex-col gap-1.5">
        <NavLink to="/home" className={link}>
          <Home size={21} /> {t("nav_home")}
        </NavLink>
        <NavLink to="/decks" className={link}>
          <Layers size={21} /> {t("nav_decks")}
        </NavLink>
      </nav>

      <button
        onClick={() => navigate("/scan")}
        className="btn3d mt-4 h-13 w-full bg-coral py-3.5 text-white shadow-[0_4px_0_rgb(var(--coral-dark))] active:shadow-[0_1px_0_rgb(var(--coral-dark))]"
      >
        <ScanLine size={20} /> {t("nav_scan")}
      </button>

      <div className="mt-auto">
        <NavLink
          to="/profile"
          className={({ isActive }) =>
            cn(
              "flex items-center gap-3 rounded-2xl p-2.5 transition-colors",
              isActive ? "bg-ink/5" : "hover:bg-ink/5",
            )
          }
        >
          <Avatar name={user?.fullName} email={user?.email} src={user?.avatarUrl} size={40} />
          <div className="min-w-0">
            <p className="truncate font-display text-sm font-bold text-ink">
              {user?.fullName ?? t("profile_your_account")}
            </p>
            <p className="truncate text-xs text-ink-muted">{user?.email}</p>
          </div>
        </NavLink>
      </div>
    </aside>
  );
}
