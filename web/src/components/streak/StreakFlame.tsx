import { cn } from "@/lib/utils/cn";

/** A flame that grows a touch with the streak and goes grey when the streak is
 *  cold (0). Used on the home hero and streak surfaces. */
export function StreakFlame({
  count,
  size = 40,
  className,
}: {
  count: number;
  size?: number;
  className?: string;
}) {
  const alive = count > 0;
  // Grow gently with streak length, capped so it never dominates.
  const scale = alive ? Math.min(1.35, 1 + Math.log10(count + 1) * 0.22) : 1;

  return (
    <span
      className={cn("relative inline-grid place-items-center", className)}
      style={{ width: size, height: size }}
      aria-hidden
    >
      <svg
        viewBox="0 0 32 32"
        width={size}
        height={size}
        style={{ transform: `scale(${scale})` }}
        className={cn("origin-bottom", alive && "animate-flame-flicker")}
      >
        <defs>
          <linearGradient id="flame-g" x1="0" y1="1" x2="0" y2="0">
            <stop offset="0%" stopColor="rgb(var(--coral))" />
            <stop offset="55%" stopColor="rgb(var(--flame))" />
            <stop offset="100%" stopColor="rgb(var(--flame))" />
          </linearGradient>
        </defs>
        <path
          d="M16 2c1.5 5-3.5 6.5-3.5 11 0 1.8 1 3 1 3S12 15 11 14c-2 2.5-4 5-4 8.5C7 27.7 11 30 16 30s9-2.6 9-7.8c0-5.2-4.2-7.7-5.6-11.4C18.3 7.6 18.8 4.7 16 2Z"
          fill={alive ? "url(#flame-g)" : "rgb(var(--ink-muted))"}
          opacity={alive ? 1 : 0.4}
        />
        {alive && (
          <path
            d="M16 14c1 3.5-2 4.2-2 7 0 2 1.8 3.4 4 3.4s3.6-1.6 3.6-3.8c0-2.7-2.3-3.9-3.1-6.1-.5 1.2-1.6 1.5-2.5-.5Z"
            fill="rgb(var(--flame))"
            opacity="0.85"
          />
        )}
      </svg>
    </span>
  );
}
