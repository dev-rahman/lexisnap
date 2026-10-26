"use client";

import { useRouter } from "next/navigation";

import { Avatar } from "@/components/ui/Avatar";
import { BrandMark } from "@/components/brand/BrandMark";
import { useAppSelector } from "@/store/hooks";

/** The main-shell top bar: wordmark + a floating avatar button to /profile. */
export function TopBar() {
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);

  return (
    <header className="flex items-center justify-between px-5 pb-2 pt-4 safe-top">
      <BrandMark size="sm" />
      <button
        onClick={() => router.push("/profile")}
        aria-label="Profile"
        className="rounded-full ring-2 ring-transparent transition active:scale-95"
      >
        <Avatar
          src={user?.avatarUrl}
          name={user?.fullName}
          email={user?.email}
          size={38}
        />
      </button>
    </header>
  );
}
