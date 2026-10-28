import { cn } from "@/lib/utils/cn";
import { BrandLoader } from "@/components/brand/BrandLoader";

/** Small inline spinner, used inside buttons and compact controls where an
 *  animated logo would be out of place. */
export function Spinner({ className }: { className?: string }) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={cn(
        "inline-block h-6 w-6 animate-spin rounded-full border-[3px] border-coral/25 border-t-coral",
        className,
      )}
    />
  );
}

/** Full-screen loading state: the animated LexiSnap logo instead of a ring. */
export function FullPageSpinner() {
  return (
    <div className="app-wash flex min-h-dvh items-center justify-center bg-paper">
      <BrandLoader />
    </div>
  );
}
