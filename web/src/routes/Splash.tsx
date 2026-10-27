import { Navigate } from "react-router-dom";

import { FullPageSpinner } from "@/components/ui/Spinner";
import { useAppSelector } from "@/store/hooks";

/** Index route: once the session is known, route to home / onboarding / login. */
export function Splash() {
  const { user, initialized } = useAppSelector((s) => s.auth);
  const onboardingSeen = useAppSelector((s) => s.prefs.onboardingSeen);

  if (!initialized) return <FullPageSpinner />;
  if (user) return <Navigate to="/home" replace />;
  return <Navigate to={onboardingSeen ? "/login" : "/onboarding"} replace />;
}
