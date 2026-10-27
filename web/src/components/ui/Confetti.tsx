import { useMemo } from "react";

const COLORS = [
  "rgb(var(--coral))",
  "rgb(var(--flame))",
  "rgb(var(--success))",
  "rgb(var(--hue-violet))",
  "rgb(var(--hue-sky))",
  "rgb(var(--hue-rose))",
];

/** A lightweight CSS confetti burst for celebration moments. Render it (keyed)
 *  to replay. Pointer-events none so it never blocks the UI. */
export function Confetti({ count = 80 }: { count?: number }) {
  const pieces = useMemo(
    () =>
      Array.from({ length: count }, (_, i) => ({
        id: i,
        left: Math.random() * 100,
        delay: Math.random() * 0.5,
        duration: 2.4 + Math.random() * 1.6,
        color: COLORS[i % COLORS.length],
        size: 7 + Math.random() * 7,
        rounded: Math.random() > 0.5,
      })),
    [count],
  );

  return (
    <div className="pointer-events-none fixed inset-0 z-[60] overflow-hidden" aria-hidden>
      {pieces.map((p) => (
        <span
          key={p.id}
          style={{
            position: "absolute",
            top: "-5%",
            left: `${p.left}%`,
            width: p.size,
            height: p.size * 1.3,
            background: p.color,
            borderRadius: p.rounded ? "9999px" : "2px",
            animation: `confetti ${p.duration}s linear ${p.delay}s forwards`,
          }}
        />
      ))}
    </div>
  );
}
