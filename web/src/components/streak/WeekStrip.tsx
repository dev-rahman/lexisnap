import { Flame, Snowflake } from "lucide-react";

import type { StreakDay } from "@/lib/domain/streakRules";
import { cn } from "@/lib/utils/cn";

/** The 7-day streak strip. `days` runs oldest→today (index 6 = today). Studied
 *  days glow, frozen days show a snowflake, missed days are dim. */
export function WeekStrip({
  days,
  tone = "light",
}: {
  days: StreakDay[];
  tone?: "light" | "onColor";
}) {
  const today = new Date();
  const labels = days.map((_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (days.length - 1 - i));
    return d.toLocaleDateString(undefined, { weekday: "narrow" });
  });

  return (
    <div className="flex items-end justify-between gap-1.5">
      {days.map((status, i) => {
        const isToday = i === days.length - 1;
        return (
          <div key={i} className="flex flex-1 flex-col items-center gap-1.5">
            <div
              className={cn(
                "grid h-9 w-9 place-items-center rounded-full text-sm transition-transform",
                status === "studied" &&
                  "bg-flame text-white shadow-[0_0_14px_-2px_rgb(var(--flame))]",
                status === "frozen" && "bg-hue-sky/20 text-hue-sky",
                status === "missed" &&
                  (tone === "onColor"
                    ? "bg-white/15 text-white/50"
                    : "bg-ink/5 text-ink-muted"),
                isToday && "ring-2 ring-offset-2 ring-flame ring-offset-transparent",
              )}
            >
              {status === "studied" && <Flame size={16} fill="currentColor" />}
              {status === "frozen" && <Snowflake size={16} />}
              {status === "missed" && <span className="h-1.5 w-1.5 rounded-full bg-current" />}
            </div>
            <span
              className={cn(
                "text-[11px] font-bold",
                tone === "onColor" ? "text-white/70" : "text-ink-muted",
              )}
            >
              {labels[i]}
            </span>
          </div>
        );
      })}
    </div>
  );
}
