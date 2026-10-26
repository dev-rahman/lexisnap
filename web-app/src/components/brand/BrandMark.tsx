import { cn } from "@/lib/utils/cn";

/** The LexiSnap wordmark: an ink tile with a coral folded corner + name. */
export function BrandMark({
  size = "md",
  showName = true,
  className,
}: {
  size?: "sm" | "md" | "lg";
  showName?: boolean;
  className?: string;
}) {
  const tile = size === "lg" ? "h-14 w-14" : size === "sm" ? "h-8 w-8" : "h-10 w-10";
  const text = size === "lg" ? "text-3xl" : size === "sm" ? "text-lg" : "text-xl";
  return (
    <div className={cn("flex items-center gap-2.5", className)}>
      <div className={cn("relative overflow-hidden rounded-lg bg-panel", tile)}>
        <span className="absolute inset-0 flex items-center justify-center font-bold text-white">
          L
        </span>
        {/* coral folded corner */}
        <span
          className="absolute right-0 top-0 h-1/3 w-1/3 bg-accent"
          style={{ clipPath: "polygon(100% 0, 0 0, 100% 100%)" }}
        />
      </div>
      {showName && (
        <span className={cn("font-bold tracking-tight text-ink", text)}>
          LexiSnap
        </span>
      )}
    </div>
  );
}
