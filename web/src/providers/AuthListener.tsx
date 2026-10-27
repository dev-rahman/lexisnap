import { useEffect } from "react";

import { mapUser } from "@/lib/auth/mapUser";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { isDemo } from "@/lib/demo";
import { demoUser } from "@/lib/data/demoData";
import { useAppDispatch } from "@/store/hooks";
import { setUser } from "@/store/slices/authSlice";
import { reconcileNow } from "@/store/slices/streakSlice";

/** Mirrors the Supabase session into the auth slice and settles the streak on
 *  launch. Renders nothing. */
export function AuthListener() {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(reconcileNow());

    // Demo mode: inject a fake user and skip Supabase entirely.
    if (isDemo()) {
      dispatch(setUser(demoUser));
      return;
    }

    const supabase = getSupabaseBrowserClient();
    supabase.auth.getUser().then(({ data }) => {
      dispatch(setUser(mapUser(data.user)));
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      dispatch(setUser(mapUser(session?.user ?? null)));
    });

    return () => sub.subscription.unsubscribe();
  }, [dispatch]);

  return null;
}
