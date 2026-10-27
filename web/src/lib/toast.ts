// Tiny toast emitter — port of AppSnackbar. Usable from anywhere (components,
// controller hooks, services), not just React, via a module-level listener.

export type ToastTone = "success" | "error" | "warning" | "info";

export interface ToastMessage {
  id: number;
  message: string;
  tone: ToastTone;
}

type Listener = (toast: ToastMessage) => void;

const listeners = new Set<Listener>();
let nextId = 1;

export function onToast(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function emit(message: string, tone: ToastTone) {
  const toast: ToastMessage = { id: nextId++, message, tone };
  listeners.forEach((l) => l(toast));
}

export const toast = {
  success: (m: string) => emit(m, "success"),
  error: (m: string) => emit(m, "error"),
  warning: (m: string) => emit(m, "warning"),
  info: (m: string) => emit(m, "info"),
};
