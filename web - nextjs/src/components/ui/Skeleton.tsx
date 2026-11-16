import { cn } from "@/lib/utils/cn";

/** A shimmering placeholder block for loading states. */
export function Skeleton({ className }: { className?: string }) {
  return (
    <div className={cn("animate-pulse rounded-xl bg-surface", className)} />
  );
}
