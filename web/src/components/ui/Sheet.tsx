import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
  type ReactNode,
} from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";

import { cn } from "@/lib/utils/cn";
import { useT } from "@/providers/I18nProvider";

// Drag the mobile bottom sheet down past this many px — or flick it down
// faster than FLICK_VELOCITY (px/ms) — to dismiss it.
const DRAG_DISMISS_PX = 110;
const FLICK_VELOCITY = 0.55;

type Release = "snap" | "close" | null;

/** A modal that renders as a centered dialog on desktop and a bottom sheet on
 *  mobile. It animates both in and out (sliding up/down on mobile, a scale-fade
 *  on desktop), can be swiped down to dismiss on touch, and closes on backdrop
 *  click or Escape. */
export function Sheet({
  open,
  onClose,
  title,
  children,
  footer,
  size = "md",
}: {
  open: boolean;
  onClose: () => void;
  title?: string;
  children: ReactNode;
  footer?: ReactNode;
  size?: "sm" | "md" | "lg";
}) {
  const t = useT();
  // Stays true through the exit animation so the sheet isn't yanked out of the
  // DOM the instant `open` flips to false.
  const [rendered, setRendered] = useState(open);
  const [leaving, setLeaving] = useState(false);
  const [entered, setEntered] = useState(false);

  // Mobile swipe-to-dismiss state.
  const [dragY, setDragY] = useState(0);
  const [dragging, setDragging] = useState(false);
  const [release, setRelease] = useState<Release>(null);
  const drag = useRef<{ startY: number; lastY: number; lastT: number } | null>(null);

  // Enter / exit lifecycle.
  useEffect(() => {
    if (open) {
      setRendered(true);
      setLeaving(false);
      setEntered(false);
      setDragY(0);
      setDragging(false);
      setRelease(null);
    } else if (rendered) {
      setLeaving(true);
    }
  }, [open, rendered]);

  // Escape to close + lock body scroll while visible.
  useEffect(() => {
    if (!rendered) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [rendered, onClose]);

  const finalize = useCallback(() => {
    // Only tear down if the parent still wants it closed — guards against a
    // re-open that lands mid-exit.
    if (!open) {
      setRendered(false);
      setLeaving(false);
      setRelease(null);
      setDragY(0);
    }
  }, [open]);

  const onPointerDown = (e: ReactPointerEvent) => {
    if (!e.isPrimary || leaving) return;
    drag.current = { startY: e.clientY, lastY: e.clientY, lastT: performance.now() };
    setDragging(true);
    setRelease(null);
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  };

  const onPointerMove = (e: ReactPointerEvent) => {
    if (!dragging || !drag.current) return;
    const dy = e.clientY - drag.current.startY;
    drag.current.lastY = e.clientY;
    drag.current.lastT = performance.now();
    // Only downward drag moves the sheet; pulling up meets light resistance.
    setDragY(dy > 0 ? dy : dy * 0.25);
  };

  const onPointerUp = (e: ReactPointerEvent) => {
    if (!dragging || !drag.current) return;
    const now = performance.now();
    const dt = Math.max(1, now - drag.current.lastT);
    const velocity = (e.clientY - drag.current.lastY) / dt;
    const shouldClose = dragY > DRAG_DISMISS_PX || velocity > FLICK_VELOCITY;
    drag.current = null;
    setDragging(false);
    if (shouldClose) {
      setRelease("close");
      onClose();
    } else {
      setRelease("snap");
    }
  };

  if (!rendered) return null;

  const maxW = { sm: "sm:max-w-sm", md: "sm:max-w-md", lg: "sm:max-w-xl" }[size];

  // The panel is driven inline while the user is dragging or the gesture is
  // settling; otherwise CSS keyframes handle the enter/exit.
  const inlineDriven = dragging || release !== null;
  const panelStyle: CSSProperties | undefined = dragging
    ? { transform: `translateY(${dragY}px)`, transition: "none" }
    : release === "snap"
      ? { transform: "translateY(0)", transition: "transform 0.3s cubic-bezier(0.4,0,0.2,1)" }
      : release === "close"
        ? { transform: "translateY(100%)", transition: "transform 0.26s cubic-bezier(0.4,0,0.2,1)" }
        : undefined;

  const panelAnim = inlineDriven
    ? ""
    : leaving
      ? "animate-sheet-out sm:animate-soft-out"
      : !entered
        ? "animate-sheet-in sm:animate-soft-in"
        : "";

  // Backdrop dims less as the sheet is dragged clear of the screen.
  const backdropStyle: CSSProperties | undefined =
    dragging || release === "close"
      ? { opacity: Math.max(0, 1 - dragY / 320), transition: dragging ? "none" : "opacity 0.28s ease-out" }
      : undefined;

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      <div
        className={cn(
          "absolute inset-0 bg-ink/50 backdrop-blur-sm dark:bg-black/70",
          !inlineDriven && (leaving ? "animate-fade-out" : "animate-fade-in"),
        )}
        style={backdropStyle}
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        style={panelStyle}
        onAnimationEnd={(e) => {
          if (e.target !== e.currentTarget) return; // ignore bubbled child anims
          if (leaving && !inlineDriven) finalize();
          else if (!leaving) setEntered(true);
        }}
        onTransitionEnd={(e) => {
          if (e.target !== e.currentTarget) return; // ignore bubbled child transitions
          if (release === "close") finalize();
          else if (release === "snap") {
            setRelease(null);
            setDragY(0);
            setEntered(true);
          }
        }}
        className={cn(
          "relative z-10 flex max-h-[90dvh] w-full flex-col overflow-hidden bg-card shadow-card-lift",
          "rounded-t-4xl sm:rounded-4xl pb-safe will-change-transform",
          panelAnim,
          maxW,
        )}
      >
        {/* Grab handle — the swipe-to-dismiss affordance (touch / mobile only). */}
        <div
          className="flex shrink-0 cursor-grab touch-none justify-center pt-3 pb-1 active:cursor-grabbing sm:hidden"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          <span className="h-1.5 w-10 rounded-full bg-ink/15" aria-hidden />
        </div>

        {title && (
          <div className="flex items-center justify-between border-b border-border px-6 py-4 sm:pt-4">
            <h2 className="font-display text-lg font-bold text-ink">{title}</h2>
            <button
              onClick={onClose}
              aria-label={t("common_close")}
              className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-ink-muted transition-colors hover:bg-ink/5 hover:text-ink"
            >
              <X size={20} />
            </button>
          </div>
        )}
        <div className="flex-1 overflow-y-auto px-6 py-5">{children}</div>
        {footer && (
          <div className="border-t border-border px-6 py-4">{footer}</div>
        )}
      </div>
    </div>,
    document.body,
  );
}
