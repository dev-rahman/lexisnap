import type { ReactNode } from "react";
import { Navigate } from "react-router-dom";

import { FullPageSpinner } from "@/components/ui/Spinner";
import { useAppSelector } from "@/store/hooks";

/** Gate app routes: wait for the session to resolve, then require a user. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, initialized } = useAppSelector((s) => s.auth);
  if (!initialized) return <FullPageSpinner />;
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

/** Keep signed-in users out of the auth screens. */
export function RedirectIfAuthed({ children }: { children: ReactNode }) {
  const { user, initialized } = useAppSelector((s) => s.auth);
  if (!initialized) return <FullPageSpinner />;
  if (user) return <Navigate to="/home" replace />;
  return <>{children}</>;
}
