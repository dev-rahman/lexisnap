import type { HTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  interactive?: boolean;
  inset?: boolean;
}

/** The base surface: white card, hairline border, soft shadow. */
export function Card({ interactive, inset, className, ...props }: CardProps) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-border bg-card shadow-card",
        inset ? "p-5" : "",
        interactive &&
          "cursor-pointer transition duration-200 hover:-translate-y-0.5 hover:shadow-pop active:translate-y-0 active:scale-[0.995]",
        className,
      )}
      {...props}
    />
  );
}
