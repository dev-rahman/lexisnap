import type { ReactNode } from "react";

import type { DeckHue } from "@/lib/domain/deckHue";
import { cn } from "@/lib/utils/cn";
import { HUE_BG, HUE_TINT, HUE_TEXT } from "@/lib/utils/hueClasses";

/** A soft rounded square holding an icon, tinted by a deck hue or coral. */
export function IconTile({
  children,
  hue,
  solid,
  size = "md",
  className,
}: {
  children: ReactNode;
  hue?: DeckHue;
  solid?: boolean;
  size?: "sm" | "md" | "lg";
  className?: string;
}) {
  const sizes = {
    sm: "h-9 w-9 rounded-xl text-[18px]",
    md: "h-12 w-12 rounded-2xl text-[22px]",
    lg: "h-16 w-16 rounded-3xl text-[30px]",
  };
  const color = hue
    ? solid
      ? cn(HUE_BG[hue], "text-white")
      : cn(HUE_TINT[hue], HUE_TEXT[hue])
    : solid
      ? "bg-coral text-white"
      : "bg-coral-soft text-coral";
  return (
    <div
      className={cn(
        "grid shrink-0 place-items-center font-display font-bold",
        sizes[size],
        color,
        className,
      )}
    >
      {children}
    </div>
  );
}
