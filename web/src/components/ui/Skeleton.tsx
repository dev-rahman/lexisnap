import { cn } from "@/lib/utils/cn";

/** A loading placeholder with a moving shimmer sweep. Theme-aware: the sweep is
 *  built from the `--ink` channel, so it reads as a soft grey on light paper and
 *  a soft light sheen on dark surfaces. Honours prefers-reduced-motion (the
 *  shimmer animation is disabled globally there, leaving a calm static block). */
export function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "animate-shimmer rounded-2xl bg-[length:200%_100%]",
        "bg-[linear-gradient(90deg,rgb(var(--ink)/0.06)_25%,rgb(var(--ink)/0.13)_50%,rgb(var(--ink)/0.06)_75%)]",
        className,
      )}
    />
  );
}
