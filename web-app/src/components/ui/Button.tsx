"use client";

import { forwardRef, type ButtonHTMLAttributes } from "react";

import { cn } from "@/lib/utils/cn";
import { Spinner } from "./Spinner";

type Variant = "primary" | "secondary" | "soft" | "ghost" | "danger";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  fullWidth?: boolean;
}

// Coral `primary` is the single primary action on a screen — keep it rare.
const VARIANTS: Record<Variant, string> = {
  primary:
    "bg-accent text-white shadow-sm shadow-accent/25 hover:bg-accent-600 active:bg-accent-600 disabled:opacity-55",
  secondary:
    "bg-card text-ink border border-border hover:bg-surface disabled:opacity-55",
  soft: "bg-accent/12 text-accent hover:bg-accent/20 disabled:opacity-55",
  ghost: "bg-transparent text-ink-muted hover:bg-surface hover:text-ink disabled:opacity-45",
  danger: "bg-error text-white hover:brightness-95 disabled:opacity-55",
};

const SIZES: Record<Size, string> = {
  sm: "h-9 px-3.5 text-sm",
  md: "h-11 px-4 text-sm",
  lg: "h-[52px] px-6 text-[15px]",
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
        "inline-flex select-none items-center justify-center gap-2 rounded-full font-semibold transition duration-150 active:scale-[0.97] disabled:pointer-events-none",
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
