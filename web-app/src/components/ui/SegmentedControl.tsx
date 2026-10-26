"use client";

import { cn } from "@/lib/utils/cn";

/** A compact pill-group selector (theme, filters, modes). */
export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  className,
}: {
  options: { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
  className?: string;
}) {
  return (
    <div className={cn("flex gap-1 rounded-full bg-surface p-1", className)}>
      {options.map((o) => (
        <button
          key={o.value}
          onClick={() => onChange(o.value)}
          className={cn(
            "flex-1 rounded-full px-3 py-2 text-sm font-semibold transition",
            value === o.value
              ? "bg-card text-ink shadow-sm"
              : "text-ink-muted hover:text-ink",
          )}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}
