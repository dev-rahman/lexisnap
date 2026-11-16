"use client";

import { useEffect } from "react";

/** Registers the PWA/push service worker once on the client. */
export function ServiceWorkerRegister() {
  useEffect(() => {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js").catch(() => {
        // Non-fatal: push/offline simply stay unavailable.
      });
    }
  }, []);
  return null;
}
