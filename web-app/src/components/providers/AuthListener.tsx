"use client";

import { useEffect } from "react";

import { mapUser } from "@/lib/auth/mapUser";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { setUser } from "@/store/slices/authSlice";
import { reconcileNow } from "@/store/slices/streakSlice";
import { useAppDispatch } from "@/store/hooks";

/**
 * Mirrors the Supabase session into the auth slice (like GetX's UserService),
 * and reconciles the streak on load and when the tab regains focus (a phone
 * PWA is resumed far more often than cold-started).
 */
export function AuthListener() {
  const dispatch = useAppDispatch();

  useEffect(() => {
    const supabase = getSupabaseBrowserClient();

    supabase.auth.getUser().then(({ data }) => {
      dispatch(setUser(mapUser(data.user)));
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      dispatch(setUser(mapUser(session?.user ?? null)));
    });

    dispatch(reconcileNow());
    const onVisible = () => {
      if (document.visibilityState === "visible") dispatch(reconcileNow());
    };
    document.addEventListener("visibilitychange", onVisible);

    return () => {
      sub.subscription.unsubscribe();
      document.removeEventListener("visibilitychange", onVisible);
    };
  }, [dispatch]);

  return null;
}
