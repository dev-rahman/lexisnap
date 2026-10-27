import { cn } from "@/lib/utils/cn";

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

export function FullPageSpinner() {
  return (
    <div className="app-wash flex min-h-dvh items-center justify-center bg-paper">
      <Spinner className="h-9 w-9" />
    </div>
  );
}
