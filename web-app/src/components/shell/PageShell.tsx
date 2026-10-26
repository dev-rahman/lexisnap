"use client";

import { useRouter } from "next/navigation";
import type { ReactNode } from "react";
import { ChevronLeft } from "lucide-react";

import { cn } from "@/lib/utils/cn";

/**
 * Secondary-page frame (inside AppShell): a sticky header with a back button
 * and title, plus a centered, responsive content column. Replaces the ad-hoc
 * mobile-only headers so every inner screen reads well on web, tablet and
 * phone.
 */
export function PageShell({
  title,
  actions,
  onBack,
  children,
  maxWidth = "max-w-2xl",
}: {
  title: string;
  actions?: ReactNode;
  onBack?: () => void;
  children: ReactNode;
  maxWidth?: string;
}) {
  const router = useRouter();
  return (
    <div className="min-h-dvh">
      <header className="sticky top-0 z-20 border-b border-border bg-paper/80 backdrop-blur-lg safe-top">
        <div className={cn("mx-auto flex h-14 w-full items-center gap-2 px-4 md:px-8", maxWidth)}>
          <button
            onClick={onBack ?? (() => router.back())}
            aria-label="Back"
            className="-ml-1.5 rounded-lg p-1.5 text-ink transition hover:bg-surface"
          >
            <ChevronLeft size={24} />
          </button>
          <h1 className="flex-1 truncate text-lg font-bold text-ink">{title}</h1>
          {actions}
        </div>
      </header>
      <main className={cn("mx-auto w-full px-5 pb-16 pt-5 md:px-8 md:pt-7", maxWidth)}>
        {children}
      </main>
    </div>
  );
}
