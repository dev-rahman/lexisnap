import { useState } from "react";

import { cn } from "@/lib/utils/cn";

function initials(name: string | null, email: string | null): string {
  const base = (name ?? email ?? "?").trim();
  const parts = base.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return base.slice(0, 2).toUpperCase();
}

export interface AvatarProps {
  name?: string | null;
  email?: string | null;
  src?: string | null;
  size?: number;
  className?: string;
}

export function Avatar({ name, email, src, size = 44, className }: AvatarProps) {
  const [failed, setFailed] = useState(false);
  const showImg = src && !failed;
  return (
    <div
      className={cn(
        "relative flex shrink-0 items-center justify-center overflow-hidden rounded-full bg-gradient-to-br from-coral to-flame font-display font-bold text-white",
        className,
      )}
      style={{ width: size, height: size, fontSize: size * 0.4 }}
    >
      {showImg ? (
        <img
          src={src}
          alt=""
          className="h-full w-full object-cover"
          onError={() => setFailed(true)}
        />
      ) : (
        <span>{initials(name ?? null, email ?? null)}</span>
      )}
    </div>
  );
}
