import { Outlet } from "react-router-dom";

import { BottomNav } from "./BottomNav";
import { Sidebar } from "./Sidebar";

/** The authed shell: sidebar on desktop, floating bottom nav on mobile, and a
 *  centered content column for the routed page. */
export function AppLayout() {
  return (
    <div className="app-wash min-h-dvh bg-paper">
      <div className="mx-auto flex max-w-content">
        <Sidebar />
        <main className="min-w-0 flex-1 px-4 pb-28 pt-5 sm:px-6 md:px-8 md:pb-10 md:pt-8">
          <Outlet />
        </main>
      </div>
      <BottomNav />
    </div>
  );
}
