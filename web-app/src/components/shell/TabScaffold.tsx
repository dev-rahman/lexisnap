"use client";

import type { ReactNode } from "react";

import { BottomNav } from "./BottomNav";
import { TopBar } from "./TopBar";

/** The Home/Decks tab frame: top bar, scrollable content, bottom nav. */
export function TabScaffold({
  active,
  children,
}: {
  active: "home" | "decks";
  children: ReactNode;
}) {
  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col">
      <TopBar />
      <main className="flex-1 px-5 pb-24 pt-2">{children}</main>
      <BottomNav active={active} />
    </div>
  );
}
