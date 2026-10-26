"use client";

import { useEffect, type ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

/**
 * A bottom sheet on phones, a centered card on wider screens. Used for the
 * many bottom-sheet flows in the app (scan source, study mode, language
 * picker, confirmations). The drag handle is hand-sized tight, per the
 * spacing note.
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
    <div
      className="fixed inset-0 z-50 flex items-end justify-center sm:items-center"
      role="dialog"
      aria-modal="true"
    >
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div
        className={cn(
          "relative z-10 w-full max-w-md animate-[slideUp_.2s_ease] bg-paper p-5 pb-6 shadow-2xl",
          "rounded-t-xl sm:rounded-xl",
          className,
        )}
      >
        <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-border sm:hidden" />
        {title && (
          <h2 className="mb-3 text-lg font-bold text-ink">{title}</h2>
        )}
        {children}
      </div>
      <style>{`@keyframes slideUp{from{transform:translateY(16px);opacity:.6}to{transform:translateY(0);opacity:1}}`}</style>
    </div>
  );
}

/** A yes/no confirmation sheet. */
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
      {message && <p className="mb-5 text-sm text-ink-muted">{message}</p>}
      <div className="flex gap-3">
        <button
          onClick={onClose}
          className="h-12 flex-1 rounded-md border border-border bg-surface font-semibold text-ink"
        >
          {cancelLabel}
        </button>
        <button
          onClick={() => {
            onConfirm();
            onClose();
          }}
          className={cn(
            "h-12 flex-1 rounded-md font-semibold text-white",
            danger ? "bg-error" : "bg-accent",
          )}
        >
          {confirmLabel}
        </button>
      </div>
    </Sheet>
  );
}
