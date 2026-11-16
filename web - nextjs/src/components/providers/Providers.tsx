"use client";

import type { ReactNode } from "react";

import { AuthListener } from "./AuthListener";
import { I18nProvider } from "./I18nProvider";
import { StoreProvider } from "./StoreProvider";
import { ThemeApplier } from "./ThemeApplier";
import { ToastHost } from "@/components/ui/Toast";

/** All client-side providers, composed once at the app root. */
export function Providers({ children }: { children: ReactNode }) {
  return (
    <StoreProvider>
      <I18nProvider>
        <ThemeApplier />
        <AuthListener />
        {children}
        <ToastHost />
      </I18nProvider>
    </StoreProvider>
  );
}
