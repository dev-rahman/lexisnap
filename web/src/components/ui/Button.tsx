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

// Flat, calm variants — solid fills with a soft shadow and a gentle press.
const VARIANTS: Record<Variant, string> = {
  primary: "bg-coral text-white shadow-soft hover:brightness-[1.04]",
  success: "bg-success text-white shadow-soft hover:brightness-[1.04]",
  danger: "bg-error text-white shadow-soft hover:brightness-[1.04]",
  secondary: "bg-card text-ink border border-border hover:border-coral/50 hover:bg-coral-soft/40",
  ghost: "bg-transparent text-ink-soft hover:bg-ink/5",
};

const SIZES: Record<Size, string> = {
  sm: "h-10 px-4 text-sm",
  md: "h-11 px-5 text-[15px]",
  lg: "h-13 px-7 text-base",
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
