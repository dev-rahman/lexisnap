import type { ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

/** A small pill for levels, tags and counts. */
export function Chip({
  children,
  className,
  tone = "neutral",
}: {
  children: ReactNode;
  className?: string;
  tone?: "neutral" | "accent" | "success";
}) {
  const tones = {
    neutral: "bg-surface text-ink-muted",
    accent: "bg-accent/12 text-accent",
    success: "bg-success/12 text-success",
  };
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold",
        tones[tone],
        className,
      )}
    >
      {children}
    </span>
  );
}
