"use client";

import Image from "next/image";

import { cn } from "@/lib/utils/cn";

/** Initials from a name or email — port of lib/app/core/utils/initials.dart. */
export function initialsFor(name?: string | null, email?: string | null): string {
  const source = (name ?? "").trim() || (email ?? "").trim();
  if (!source) return "?";
  const parts = source.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
  return source.slice(0, 2).toUpperCase();
}

export function Avatar({
  src,
  name,
  email,
  size = 40,
  className,
}: {
  src?: string | null;
  name?: string | null;
  email?: string | null;
  size?: number;
  className?: string;
}) {
  const dimension = { width: size, height: size };
  if (src) {
    return (
      <Image
        src={src}
        alt={name ?? "Avatar"}
        {...dimension}
        className={cn("rounded-full object-cover", className)}
        unoptimized
      />
    );
  }
  return (
    <span
      style={dimension}
      className={cn(
        "inline-flex items-center justify-center rounded-full bg-panel font-semibold text-white",
        className,
      )}
    >
      {initialsFor(name, email)}
    </span>
  );
}
