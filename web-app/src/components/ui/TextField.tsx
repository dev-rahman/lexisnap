"use client";

import { forwardRef, type InputHTMLAttributes, type ReactNode } from "react";

import { cn } from "@/lib/utils/cn";

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string | null;
  trailing?: ReactNode;
}

export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(
  ({ label, error, trailing, className, id, ...props }, ref) => {
    const inputId = id ?? props.name;
    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="mb-1.5 block text-sm font-medium text-ink-muted"
          >
            {label}
          </label>
        )}
        <div className="relative">
          <input
            ref={ref}
            id={inputId}
            className={cn(
              "h-12 w-full rounded-md border bg-surface px-3.5 text-ink outline-none transition placeholder:text-ink-muted/60",
              "focus:border-accent focus:ring-2 focus:ring-accent/30",
              error ? "border-error" : "border-border",
              trailing && "pr-11",
              className,
            )}
            {...props}
          />
          {trailing && (
            <div className="absolute inset-y-0 right-2 flex items-center">
              {trailing}
            </div>
          )}
        </div>
        {error && <p className="mt-1 text-sm text-alert">{error}</p>}
      </div>
    );
  },
);
TextField.displayName = "TextField";
