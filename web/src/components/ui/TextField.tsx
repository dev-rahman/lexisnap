import {
  forwardRef,
  useId,
  useState,
  type InputHTMLAttributes,
  type ReactNode,
} from "react";
import { Eye, EyeOff } from "lucide-react";

import { cn } from "@/lib/utils/cn";

export interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string | null;
  hint?: string;
  leftIcon?: ReactNode;
}

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  function TextField(
    { label, error, hint, leftIcon, type = "text", className, id, ...props },
    ref,
  ) {
    const autoId = useId();
    const fieldId = id ?? autoId;
    const [reveal, setReveal] = useState(false);
    const isPassword = type === "password";
    const inputType = isPassword && reveal ? "text" : type;

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={fieldId}
            className="mb-1.5 block text-sm font-semibold text-ink-soft"
          >
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-muted">
              {leftIcon}
            </span>
          )}
          <input
            ref={ref}
            id={fieldId}
            type={inputType}
            className={cn(
              "h-12 w-full rounded-2xl border-2 bg-card px-4 text-[15px] text-ink",
              "placeholder:text-ink-muted/70 transition-colors",
              "focus:outline-none focus:ring-4 focus:ring-coral/15",
              leftIcon && "pl-11",
              isPassword && "pr-11",
              error
                ? "border-error focus:border-error"
                : "border-border focus:border-coral",
              className,
            )}
            aria-invalid={!!error}
            {...props}
          />
          {isPassword && (
            <button
              type="button"
              onClick={() => setReveal((r) => !r)}
              className="absolute right-3 top-1/2 -translate-y-1/2 rounded-lg p-1 text-ink-muted hover:text-ink"
              aria-label={reveal ? "Hide password" : "Show password"}
            >
              {reveal ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          )}
        </div>
        {error ? (
          <p className="mt-1.5 text-sm font-medium text-error">{error}</p>
        ) : hint ? (
          <p className="mt-1.5 text-sm text-ink-muted">{hint}</p>
        ) : null}
      </div>
    );
  },
);
