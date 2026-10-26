"use client";

import type { ReactNode } from "react";

import { BottomNav } from "./BottomNav";
import { TopBar } from "./TopBar";

/** Home/Decks content frame. Phone: top bar + bottom nav. Wider screens use
 *  the sidebar (from AppShell), so those are hidden and the column widens. */
export function TabScaffold({
  active,
  title,
  children,
}: {
  active: "home" | "decks";
  title?: string;
  children: ReactNode;
}) {
  return (
    <div className="min-h-dvh">
      <div className="md:hidden">
        <TopBar />
      </div>
      <main className="mx-auto w-full max-w-3xl px-5 pb-28 pt-3 md:px-10 md:pb-12 md:pt-10">
        {title && (
          <h1 className="mb-6 hidden text-3xl font-bold text-ink md:block">{title}</h1>
        )}
        {children}
      </main>
      <div className="md:hidden">
        <BottomNav active={active} />
      </div>
    </div>
  );
}
