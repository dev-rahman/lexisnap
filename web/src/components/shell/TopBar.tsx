import { Link } from "react-router-dom";

import { BrandMark } from "@/components/brand/BrandMark";
import { Avatar } from "@/components/ui/Avatar";
import { useAppSelector } from "@/store/hooks";

/** Slim top bar shown on every width now that the sidebar is gone: brand on
 *  the left, a profile avatar on the right. Calm and unobtrusive. */
export function TopBar() {
  const user = useAppSelector((s) => s.auth.user);
  return (
    <header className="sticky top-0 z-30 border-b border-border/60 bg-paper/80 backdrop-blur-md safe-top">
      <div className="mx-auto flex h-16 max-w-wide items-center justify-between px-4 sm:px-6 lg:px-8">
        <Link to="/home" aria-label="Home">
          <BrandMark size="sm" />
        </Link>
        <Link to="/profile" aria-label="Profile" className="rounded-full transition-opacity hover:opacity-80">
          <Avatar name={user?.fullName} email={user?.email} src={user?.avatarUrl} size={36} />
        </Link>
      </div>
    </header>
  );
}
