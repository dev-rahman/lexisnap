import type { ReactNode } from "react";

import { BrandMark } from "@/components/brand/BrandMark";

/** Two-pane auth layout: a vivid branded panel on desktop, the form on the
 *  right (full-width on mobile). Keeps auth screens premium, never flat. */
export function AuthScaffold({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  return (
    <div className="app-wash min-h-dvh bg-paper">
      <div className="mx-auto flex min-h-dvh max-w-5xl flex-col lg:flex-row lg:items-stretch lg:gap-10 lg:px-6 lg:py-10">
        {/* Brand panel */}
        <div className="relative hidden flex-1 overflow-hidden rounded-4xl bg-gradient-to-br from-coral to-flame p-10 text-white lg:flex lg:flex-col">
          <BrandMark size="md" className="[&_span]:text-white [&_.text-coral]:text-white" />
          <div className="mt-auto">
            <p className="font-display text-4xl font-extrabold leading-tight text-balance">
              Snap a page.
              <br />
              Learn the words
              <br />
              that matter.
            </p>
            <p className="mt-4 max-w-sm text-white/85">
              Point your camera at any text — LexiSnap finds the vocabulary worth
              knowing and turns it into flashcards you'll actually remember.
            </p>
            <div className="mt-8 flex gap-3 text-4xl">
              <span className="animate-float">📸</span>
              <span className="animate-float [animation-delay:0.4s]">✨</span>
              <span className="animate-float [animation-delay:0.8s]">🔥</span>
            </div>
          </div>
        </div>

        {/* Form */}
        <div className="flex flex-1 flex-col justify-center px-5 py-10 sm:px-8">
          <div className="mx-auto w-full max-w-sm">
            <div className="lg:hidden">
              <BrandMark size="md" />
            </div>
            <h1 className="mt-8 font-display text-3xl font-extrabold text-ink lg:mt-0">
              {title}
            </h1>
            {subtitle && <p className="mt-2 text-ink-muted">{subtitle}</p>}
            <div className="mt-7">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
