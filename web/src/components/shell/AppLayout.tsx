import { Outlet } from "react-router-dom";

import { BottomNav } from "./BottomNav";
import { TopBar } from "./TopBar";

/** The authed shell: a slim top bar, a centered wide content column, and the
 *  floating bottom nav on every breakpoint (no sidebar). */
export function AppLayout() {
  return (
    <div className="app-wash min-h-dvh bg-paper">
      <TopBar />
      <main className="mx-auto w-full max-w-wide px-4 pb-32 pt-6 sm:px-6 lg:px-8">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  );
}
