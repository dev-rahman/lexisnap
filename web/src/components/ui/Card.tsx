import { forwardRef, type HTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  interactive?: boolean;
  padded?: boolean;
}

export const Card = forwardRef<HTMLDivElement, CardProps>(function Card(
  { interactive, padded = true, className, ...props },
  ref,
) {
  return (
    <div
      ref={ref}
      className={cn(
        "card-surface",
        padded && "p-5",
        interactive && "hover-lift cursor-pointer hover:shadow-card-lift",
        className,
      )}
      {...props}
    />
  );
});
