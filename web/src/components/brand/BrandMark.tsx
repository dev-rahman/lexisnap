import { cn } from "@/lib/utils/cn";

/** The LexiSnap logo lockup: a coral scanner/spark glyph + wordmark. */
export function BrandMark({
  size = "md",
  showWord = true,
  className,
}: {
  size?: "sm" | "md" | "lg";
  showWord?: boolean;
  className?: string;
}) {
  const dim = { sm: 28, md: 36, lg: 56 }[size];
  const text = { sm: "text-lg", md: "text-xl", lg: "text-3xl" }[size];
  return (
    <div className={cn("flex items-center gap-2.5", className)}>
      <span
        className="grid shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-coral to-flame text-white shadow-pop"
        style={{ width: dim, height: dim }}
      >
        <svg viewBox="0 0 24 24" width={dim * 0.62} height={dim * 0.62} fill="none">
          <path
            d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"
            stroke="currentColor"
            strokeWidth="2.2"
            strokeLinecap="round"
          />
          <circle cx="12" cy="12" r="3" fill="currentColor" />
        </svg>
      </span>
      {showWord && (
        <span className={cn("font-display font-extrabold tracking-tight text-ink", text)}>
          Lexi<span className="text-coral">Snap</span>
        </span>
      )}
    </div>
  );
}
