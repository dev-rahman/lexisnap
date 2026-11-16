import type { ReactNode } from "react";

/** A circular progress indicator (daily goal). Pure SVG, theme-aware via
 *  currentColor + a track color. */
export function ProgressRing({
  value,
  size = 96,
  stroke = 9,
  trackClassName = "text-white/15",
  barClassName = "text-accent",
  children,
}: {
  value: number; // 0..1
  size?: number;
  stroke?: number;
  trackClassName?: string;
  barClassName?: string;
  children?: ReactNode;
}) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const clamped = Math.max(0, Math.min(1, value));
  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          strokeWidth={stroke}
          className={trackClassName}
          stroke="currentColor"
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          strokeWidth={stroke}
          strokeLinecap="round"
          className={barClassName}
          stroke="currentColor"
          strokeDasharray={c}
          strokeDashoffset={c * (1 - clamped)}
          style={{ transition: "stroke-dashoffset 0.5s cubic-bezier(0.16,1,0.3,1)" }}
        />
      </svg>
      {children && (
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {children}
        </div>
      )}
    </div>
  );
}
