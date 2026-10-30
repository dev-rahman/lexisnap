import { Crown, Sparkles } from "lucide-react";
import { Link } from "react-router-dom";

import { CURRENT_TIER, planById } from "@/lib/data/plans";
import { useT } from "@/providers/I18nProvider";

/** A small, always-visible subscription pill in the top bar. For free users it
 *  invites an upgrade; for subscribers it shows their tier. Both route to the
 *  plans page. */
export function UpgradeChip() {
  const t = useT();

  if (CURRENT_TIER === "free") {
    return (
      <Link
        to="/subscription"
        className="inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-coral to-flame px-3 py-1.5 font-display text-xs font-bold text-white shadow-soft transition-[filter] hover:brightness-105 active:scale-[0.97]"
      >
        <Sparkles size={14} />
        {t("nav_upgrade")}
      </Link>
    );
  }

  return (
    <Link
      to="/subscription"
      className="inline-flex items-center gap-1.5 rounded-full bg-hue-violet/12 px-3 py-1.5 font-display text-xs font-bold text-hue-violet transition-colors hover:bg-hue-violet/20 active:scale-[0.97]"
    >
      <Crown size={14} />
      {t(planById(CURRENT_TIER).nameKey)}
    </Link>
  );
}
