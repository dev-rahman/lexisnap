import type { ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

export function EmptyState({
  emoji,
  title,
  description,
  action,
  className,
}: {
  emoji: string;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center rounded-3xl border-2 border-dashed border-border px-6 py-12 text-center",
        className,
      )}
    >
      <div className="mb-4 grid h-20 w-20 animate-float place-items-center rounded-3xl bg-coral-soft text-5xl">
        <span>{emoji}</span>
      </div>
      <h3 className="font-display text-xl font-extrabold text-ink">{title}</h3>
      {description && (
        <p className="mt-1.5 max-w-xs text-[15px] text-ink-muted">{description}</p>
      )}
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}
