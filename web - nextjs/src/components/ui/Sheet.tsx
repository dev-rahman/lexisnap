"use client";

import { useEffect, type ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

/**
 * A bottom sheet on phones, a centered dialog on wider screens. Used for the
 * app's many sheet flows (scan destination, study mode, pickers, confirms).
 */
export function Sheet({
  open,
  onClose,
  title,
  children,
  className,
}: {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  className?: string;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center" role="dialog" aria-modal="true">
      <div className="absolute inset-0 animate-fade-in bg-ink/40 backdrop-blur-sm" onClick={onClose} />
      <div
        className={cn(
          "relative z-10 w-full max-w-md animate-slide-up bg-card p-5 pb-7 shadow-pop",
          "rounded-t-3xl sm:rounded-3xl sm:p-6",
          className,
        )}
      >
        <div className="mx-auto mb-4 h-1.5 w-10 rounded-full bg-border sm:hidden" />
        {title && <h2 className="mb-4 text-lg font-bold text-ink">{title}</h2>}
        {children}
      </div>
    </div>
  );
}

/** A yes/no confirmation dialog. */
export function ConfirmSheet({
  open,
  onClose,
  title,
  message,
  confirmLabel,
  cancelLabel,
  danger,
  onConfirm,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  message?: string;
  confirmLabel: string;
  cancelLabel: string;
  danger?: boolean;
  onConfirm: () => void;
}) {
  return (
    <Sheet open={open} onClose={onClose} title={title}>
      {message && <p className="mb-5 text-[15px] leading-relaxed text-ink-muted">{message}</p>}
      <div className="flex gap-3">
        <button
          onClick={onClose}
          className="h-12 flex-1 rounded-full border border-border bg-card font-semibold text-ink transition hover:bg-surface"
        >
          {cancelLabel}
        </button>
        <button
          onClick={() => {
            onConfirm();
            onClose();
          }}
          className={cn(
            "h-12 flex-1 rounded-full font-semibold text-white transition active:scale-[0.97]",
            danger ? "bg-error" : "bg-accent",
          )}
        >
          {confirmLabel}
        </button>
      </div>
    </Sheet>
  );
}
