import type { ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

/** A rounded, tinted square that holds an icon. Sizes stay consistent across
 *  the app so list rows and headers line up. */
export function IconTile({
  children,
  className,
  size = "md",
}: {
  children: ReactNode;
  className?: string;
  size?: "sm" | "md" | "lg";
}) {
  const dim =
    size === "lg" ? "h-12 w-12" : size === "sm" ? "h-9 w-9" : "h-10 w-10";
  return (
    <span
      className={cn(
        "inline-flex shrink-0 items-center justify-center rounded-xl",
        dim,
        className ?? "bg-surface text-ink-muted",
      )}
    >
      {children}
    </span>
  );
}
