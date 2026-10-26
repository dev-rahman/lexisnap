"use client";

import { Flame, Snowflake } from "lucide-react";

import type { StreakDay } from "@/lib/domain/streakRules";
import { cn } from "@/lib/utils/cn";

const DAY_LETTERS = ["S", "M", "T", "W", "T", "F", "S"];

/** The last 7 study days, oldest first ending today. Ports week_strip.dart. */
export function WeekStrip({ week }: { week: StreakDay[] }) {
  const today = new Date();
  // week[6] is today; map each cell back to a weekday letter.
  const letters = week.map((_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() - (week.length - 1 - i));
    return DAY_LETTERS[d.getDay()];
  });

  return (
    <div className="flex items-end justify-between gap-1.5">
      {week.map((day, i) => (
        <div key={i} className="flex flex-1 flex-col items-center gap-1">
          <div
            className={cn(
              "flex h-9 w-9 items-center justify-center rounded-full text-xs font-bold",
              day === "studied" && "bg-accent text-white",
              day === "frozen" && "bg-hue-sky/25 text-hue-sky",
              day === "missed" && "bg-white/10 text-white/40",
            )}
          >
            {day === "studied" ? (
              <Flame size={16} />
            ) : day === "frozen" ? (
              <Snowflake size={16} />
            ) : (
              ""
            )}
          </div>
          <span className="text-[11px] text-white/60">{letters[i]}</span>
        </div>
      ))}
    </div>
  );
}
