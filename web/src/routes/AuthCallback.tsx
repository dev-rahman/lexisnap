import { useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { FullPageSpinner } from "@/components/ui/Spinner";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";

/** Lands here after the Google OAuth redirect. `detectSessionInUrl` on the
 *  client stores the session automatically; we just wait for it, then go on. */
export function AuthCallback() {
  const navigate = useNavigate();
  const [params] = useSearchParams();

  useEffect(() => {
    const next = params.get("next") ?? "/home";
    const supabase = getSupabaseBrowserClient();

    let done = false;
    const go = () => {
      if (done) return;
      done = true;
      navigate(next, { replace: true });
    };

    supabase.auth.getSession().then(({ data }) => {
      if (data.session) go();
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_e, session) => {
      if (session) go();
    });
    const timeout = setTimeout(() => navigate("/login", { replace: true }), 6000);
    return () => {
      clearTimeout(timeout);
      sub.subscription.unsubscribe();
    };
  }, [navigate, params]);

  return <FullPageSpinner />;
}
