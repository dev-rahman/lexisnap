"use client";

import type { ReactNode } from "react";

import { ServiceWorkerRegister } from "./ServiceWorkerRegister";
import { Sidebar } from "./Sidebar";

/** Authed frame: a left sidebar on md+ screens, offsetting the content.
 *  On phones the sidebar is hidden and pages supply their own bottom bar. */
export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-dvh bg-paper md:pl-64">
      <ServiceWorkerRegister />
      <Sidebar />
      {children}
    </div>
  );
}
