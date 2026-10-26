"use client";

import { useRouter } from "next/navigation";
import { Home, Layers, ScanLine } from "lucide-react";

import { cn } from "@/lib/utils/cn";

type Tab = "home" | "decks";

/** Floating phone tab bar: Home · Scan (coral) · Decks. */
export function BottomNav({ active }: { active: Tab }) {
  const router = useRouter();
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-0 z-30 flex justify-center px-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
      <nav className="shadow-pop pointer-events-auto flex items-center gap-1 rounded-full border border-border bg-card/90 px-2 py-2 backdrop-blur-lg">
        <Item icon={<Home size={22} />} label="Home" active={active === "home"} onClick={() => router.push("/home")} />
        <button
          onClick={() => router.push("/scan")}
          aria-label="Scan"
          className="mx-1 flex h-12 w-12 items-center justify-center rounded-full bg-accent text-white shadow-sm shadow-accent/30 transition active:scale-90"
        >
          <ScanLine size={24} />
        </button>
        <Item icon={<Layers size={22} />} label="Decks" active={active === "decks"} onClick={() => router.push("/decks")} />
      </nav>
    </div>
  );
}

function Item({
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
        "flex h-12 w-16 flex-col items-center justify-center gap-0.5 rounded-full text-[11px] font-semibold transition",
        active ? "text-accent" : "text-ink-muted",
      )}
    >
      {icon}
      {label}
    </button>
  );
}
