"use client";

import { forwardRef, type ButtonHTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";
import { Spinner } from "./Spinner";

type Variant = "primary" | "secondary" | "ghost" | "danger";
type Size = "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  fullWidth?: boolean;
}

// Coral `primary` is the single primary action on a screen — keep it rare
// (see the visual-direction note). Everything else uses surface/ghost.
const VARIANTS: Record<Variant, string> = {
  primary:
    "bg-accent text-white hover:bg-accent-600 active:bg-accent-600 disabled:opacity-60",
  secondary:
    "bg-surface text-ink border border-border hover:brightness-95 disabled:opacity-60",
  ghost: "bg-transparent text-ink hover:bg-surface disabled:opacity-50",
  danger: "bg-error text-white hover:brightness-95 disabled:opacity-60",
};

const SIZES: Record<Size, string> = {
  md: "h-11 px-4 text-sm",
  lg: "h-14 px-5 text-base",
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = "secondary",
      size = "lg",
      loading = false,
      fullWidth = false,
      className,
      children,
      disabled,
      ...props
    },
    ref,
  ) => (
    <button
      ref={ref}
      disabled={disabled || loading}
      className={cn(
        "inline-flex select-none items-center justify-center gap-2 rounded-md font-semibold transition active:scale-[0.98]",
        VARIANTS[variant],
        SIZES[size],
        fullWidth && "w-full",
        className,
      )}
      {...props}
    >
      {loading ? <Spinner className="h-5 w-5" /> : children}
    </button>
  ),
);
Button.displayName = "Button";
