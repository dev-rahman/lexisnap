import { cn } from "@/lib/utils/cn";

/** Animated LexiSnap logo used as the app's loading indicator (replaces the
 *  plain spinner). The icon tile bobs while a soft scan-line sweeps across it —
 *  echoing the "snap a page, scan the words" idea — with the wordmark pulsing
 *  below. Honours prefers-reduced-motion (animations are frozen globally). */
export function BrandLoader({
  size = 64,
  label,
  showWord = true,
  className,
}: {
  size?: number;
  label?: string;
  showWord?: boolean;
  className?: string;
}) {
  const radius = size * 0.22;
  return (
    <div
      role="status"
      aria-label="Loading"
      className={cn("flex flex-col items-center gap-4", className)}
    >
      <div className="animate-[bob_1.6s_ease-in-out_infinite]">
        <div
          className="relative overflow-hidden shadow-card-lift"
          style={{ width: size, height: size, borderRadius: radius }}
        >
          <img
            src="/icon.png"
            alt="LexiSnap"
            width={size}
            height={size}
            style={{ width: size, height: size }}
            className="block"
          />
          {/* Scanner highlight sweeping vertically across the mark. */}
          <span
            aria-hidden
            className="pointer-events-none absolute inset-x-0 top-1/2 h-[3px] animate-[scan-sweep_1.5s_ease-in-out_infinite] bg-white/85 blur-[1px]"
            style={{ boxShadow: "0 0 12px 2px rgba(255,255,255,0.55)" }}
          />
        </div>
      </div>

      {showWord && (
        <span className="animate-pulse font-display text-lg font-bold tracking-tight text-ink">
          Lexi<span className="text-coral">Snap</span>
        </span>
      )}

      {label && (
        <p className="-mt-1 font-display text-sm font-semibold text-ink-muted">
          {label}
        </p>
      )}
    </div>
  );
}
