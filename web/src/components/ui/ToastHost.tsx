import { useEffect, useState } from "react";
import { CheckCircle2, AlertTriangle, XCircle, Info } from "lucide-react";

import { onToast, type ToastMessage, type ToastTone } from "@/lib/toast";
import { cn } from "@/lib/utils/cn";

const TONE: Record<ToastTone, { icon: typeof Info; cls: string }> = {
  success: { icon: CheckCircle2, cls: "text-success" },
  error: { icon: XCircle, cls: "text-error" },
  warning: { icon: AlertTriangle, cls: "text-flame" },
  info: { icon: Info, cls: "text-hue-sky" },
};

/** Listens to the module-level toast emitter and renders stacked toasts. */
export function ToastHost() {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  useEffect(
    () =>
      onToast((toast) => {
        setToasts((prev) => [...prev, toast]);
        setTimeout(() => {
          setToasts((prev) => prev.filter((t) => t.id !== toast.id));
        }, 3600);
      }),
    [],
  );

  return (
    <div className="pointer-events-none fixed inset-x-0 top-0 z-[70] flex flex-col items-center gap-2 px-4 pt-4 safe-top">
      {toasts.map((toast) => {
        const { icon: Icon, cls } = TONE[toast.tone];
        return (
          <div
            key={toast.id}
            className={cn(
              "pointer-events-auto flex w-full max-w-sm items-center gap-3 rounded-2xl border border-border bg-card px-4 py-3 shadow-card-lift",
              "animate-[pop-in_0.25s_ease-out]",
            )}
          >
            <Icon className={cn("shrink-0", cls)} size={22} />
            <p className="text-[15px] font-medium text-ink">{toast.message}</p>
          </div>
        );
      })}
    </div>
  );
}
