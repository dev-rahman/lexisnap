import { cn } from "@/lib/utils/cn";

/** The LexiSnap logo lockup: the app icon mark + wordmark, matching the mobile
 *  app. The icon is the real artwork (navy tile, cream flashcard, coral corner
 *  + scan-line); rounded proportionally in-app like the mobile AppLogo. */
export function BrandMark({
  size = "md",
  showWord = true,
  showIcon = true,
  className,
}: {
  size?: "sm" | "md" | "lg";
  showWord?: boolean;
  showIcon?: boolean;
  className?: string;
}) {
  const dim = { sm: 30, md: 38, lg: 56 }[size];
  const text = { sm: "text-lg", md: "text-xl", lg: "text-3xl" }[size];
  return (
    <div className={cn("flex items-center gap-2.5", className)}>
      {showIcon && (
        <img
          src="/icon.png"
          alt="LexiSnap"
          width={dim}
          height={dim}
          className="shrink-0"
          style={{ width: dim, height: dim, borderRadius: dim * 0.22 }}
        />
      )}
      {showWord && (
        <span className={cn("font-display font-bold tracking-tight text-ink", text)}>
          Lexi<span className="text-coral">Snap</span>
        </span>
      )}
    </div>
  );
}
