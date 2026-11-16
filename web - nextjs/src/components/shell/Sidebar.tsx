"use client";

import { usePathname, useRouter } from "next/navigation";
import { Home, Layers, ScanLine } from "lucide-react";

import { Avatar } from "@/components/ui/Avatar";
import { BrandMark } from "@/components/brand/BrandMark";
import { cn } from "@/lib/utils/cn";
import { useAppSelector } from "@/store/hooks";

const NAV = [
  { href: "/home", label: "Home", icon: Home },
  { href: "/decks", label: "Decks", icon: Layers },
];

/** Desktop/tablet left rail (hidden below md). */
export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);

  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r border-border bg-card px-4 py-6 md:flex">
      <div className="px-2">
        <BrandMark size="sm" />
      </div>

      <nav className="mt-9 flex flex-1 flex-col gap-1.5">
        {NAV.map(({ href, label, icon: Icon }) => {
          const active = pathname.startsWith(href);
          return (
            <button
              key={href}
              onClick={() => router.push(href)}
              className={cn(
                "flex items-center gap-3 rounded-2xl px-3.5 py-3 text-[15px] font-semibold transition",
                active
                  ? "bg-accent/12 text-accent"
                  : "text-ink-muted hover:bg-surface hover:text-ink",
              )}
            >
              <Icon size={20} />
              {label}
            </button>
          );
        })}

        <button
          onClick={() => router.push("/scan")}
          className="mt-2 flex items-center gap-3 rounded-2xl bg-accent px-3.5 py-3 text-[15px] font-semibold text-white shadow-sm shadow-accent/25 transition hover:bg-accent-600 active:scale-[0.98]"
        >
          <ScanLine size={20} />
          Scan
        </button>
      </nav>

      <button
        onClick={() => router.push("/profile")}
        className="flex items-center gap-3 rounded-2xl p-2 text-left transition hover:bg-surface"
      >
        <Avatar src={user?.avatarUrl} name={user?.fullName} email={user?.email} size={38} />
        <span className="min-w-0 flex-1">
          <span className="block truncate text-sm font-semibold text-ink">
            {user?.fullName ?? "Account"}
          </span>
          <span className="block truncate text-xs text-ink-muted">{user?.email}</span>
        </span>
      </button>
    </aside>
  );
}
