import type { ButtonHTMLAttributes, ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

export interface ChipProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  selected?: boolean;
  leading?: ReactNode;
}

/** A selectable pill used for scan word selection and filters. */
export function Chip({ selected, leading, className, children, ...props }: ChipProps) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border-2 px-3.5 py-2 text-sm font-semibold",
        "transition-all duration-150 active:scale-95",
        selected
          ? "border-coral bg-coral text-white shadow-[0_3px_0_rgb(var(--coral-dark))]"
          : "border-border bg-card text-ink-soft hover:border-coral/40 hover:text-ink",
        className,
      )}
      {...props}
    >
      {leading}
      {children}
    </button>
  );
}
