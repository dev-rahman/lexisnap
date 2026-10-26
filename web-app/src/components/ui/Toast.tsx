"use client";

import { useEffect, useState } from "react";

import { onToast, type ToastMessage, type ToastTone } from "@/lib/toast";

const TONE_BG: Record<ToastTone, string> = {
  // Muted/darkened registers so they read as one family (see app_colors.dart).
  success: "bg-confirm",
  error: "bg-alert",
  warning: "bg-caution",
  info: "bg-notice",
};

const DURATION = 3400;

export function ToastHost() {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  useEffect(() => {
    return onToast((t) => {
      setToasts((prev) => [...prev, t]);
      setTimeout(() => {
        setToasts((prev) => prev.filter((x) => x.id !== t.id));
      }, DURATION);
    });
  }, []);

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-[100] flex flex-col items-center gap-2 p-4 safe-bottom">
      {toasts.map((t) => (
        <div
          key={t.id}
          className={`pointer-events-auto w-full max-w-sm rounded-md px-4 py-3 text-sm font-medium text-white shadow-lg ${TONE_BG[t.tone]}`}
          role="status"
        >
          {t.message}
        </div>
      ))}
    </div>
  );
}
