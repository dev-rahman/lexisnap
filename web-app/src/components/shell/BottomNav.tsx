"use client";

import { useRouter } from "next/navigation";
import { Home, Layers, ScanLine } from "lucide-react";

import { cn } from "@/lib/utils/cn";

type Tab = "home" | "decks";

/**
 * The authed shell's bottom bar: Home / Scan (center, coral) / Decks.
 * Ports AppBottomNavBar — kept compact (the spacing note) with the scan
 * action as the single coral accent.
 */
export function BottomNav({ active }: { active: Tab }) {
  const router = useRouter();

  return (
    <nav className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-paper/95 backdrop-blur safe-bottom">
      <div className="mx-auto flex h-16 max-w-md items-center justify-around px-6">
        <NavItem
          icon={<Home size={24} />}
          label="Home"
          active={active === "home"}
          onClick={() => router.push("/home")}
        />
        <button
          onClick={() => router.push("/scan")}
          aria-label="Scan"
          className="-mt-6 flex h-14 w-14 items-center justify-center rounded-full bg-accent text-white shadow-lg shadow-accent/30 transition active:scale-95"
        >
          <ScanLine size={26} />
        </button>
        <NavItem
          icon={<Layers size={24} />}
          label="Decks"
          active={active === "decks"}
          onClick={() => router.push("/decks")}
        />
      </div>
    </nav>
  );
}

function NavItem({
  icon,
  label,
  active,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "flex w-16 flex-col items-center gap-0.5 text-xs font-medium transition",
        active ? "text-ink" : "text-ink-muted",
      )}
    >
      {icon}
      {label}
    </button>
  );
}
