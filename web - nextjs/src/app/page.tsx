"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { BrandMark } from "@/components/brand/BrandMark";
import { useAppSelector } from "@/store/hooks";

/**
 * Splash gate — ports SplashController: once the session is known, routes to
 * /home (signed in), /onboarding (first run) or /login.
 */
export default function SplashPage() {
  const router = useRouter();
  const initialized = useAppSelector((s) => s.auth.initialized);
  const user = useAppSelector((s) => s.auth.user);
  const onboardingSeen = useAppSelector((s) => s.prefs.onboardingSeen);

  useEffect(() => {
    if (!initialized) return;
    if (user) router.replace("/home");
    else if (!onboardingSeen) router.replace("/onboarding");
    else router.replace("/login");
  }, [initialized, user, onboardingSeen, router]);

  return (
    <main className="flex min-h-dvh items-center justify-center bg-paper">
      <BrandMark size="lg" />
    </main>
  );
}
