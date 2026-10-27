import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

type Variant = "primary" | "secondary" | "ghost" | "success" | "danger";
type Size = "sm" | "md" | "lg";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  fullWidth?: boolean;
  loading?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
}

// Each variant = fill colour + a darker "lip" rendered as a bottom box-shadow.
// Pressing removes the lip and translates down (handled by .btn3d + active:).
const VARIANTS: Record<Variant, string> = {
  primary:
    "bg-coral text-white shadow-[0_4px_0_rgb(var(--coral-dark))] hover:brightness-[1.03] active:shadow-[0_1px_0_rgb(var(--coral-dark))]",
  success:
    "bg-success text-white shadow-[0_4px_0_rgb(var(--success-dark))] hover:brightness-[1.03] active:shadow-[0_1px_0_rgb(var(--success-dark))]",
  danger:
    "bg-error text-white shadow-[0_4px_0_rgb(var(--error-dark))] hover:brightness-[1.03] active:shadow-[0_1px_0_rgb(var(--error-dark))]",
  secondary:
    "bg-card text-ink border-2 border-border shadow-[0_4px_0_rgb(var(--border))] hover:border-coral/40 active:shadow-[0_1px_0_rgb(var(--border))]",
  ghost:
    "bg-transparent text-ink-soft hover:bg-ink/5 active:translate-y-0 active:scale-[0.98]",
};

const SIZES: Record<Size, string> = {
  sm: "h-10 px-4 text-sm",
  md: "h-12 px-5 text-[15px]",
  lg: "h-14 px-7 text-lg",
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  {
    variant = "primary",
    size = "md",
    fullWidth,
    loading,
    leftIcon,
    rightIcon,
    className,
    children,
    disabled,
    ...props
  },
  ref,
) {
  return (
    <button
      ref={ref}
      disabled={disabled || loading}
      className={cn(
        "btn3d",
        VARIANTS[variant],
        SIZES[size],
        fullWidth && "w-full",
        className,
      )}
      {...props}
    >
      {loading ? (
        <span className="h-5 w-5 animate-spin rounded-full border-[2.5px] border-current border-t-transparent" />
      ) : (
        leftIcon
      )}
      {children}
      {!loading && rightIcon}
    </button>
  );
});
