import { lazy, Suspense, type ComponentType } from "react";
import { createBrowserRouter } from "react-router-dom";

import { AppLayout } from "@/components/shell/AppLayout";
import { FullPageSpinner } from "@/components/ui/Spinner";
import { RequireAuth, RedirectIfAuthed } from "@/providers/RouteGuards";
import { Splash } from "@/routes/Splash";
import { AuthCallback } from "@/routes/AuthCallback";
import { Home } from "@/routes/app/Home";
import { Decks } from "@/routes/app/Decks";
import { DeckDetail } from "@/routes/app/DeckDetail";

// Code-split the less-frequent / heavy routes (Scan pulls in Tesseract OCR).
const named = <T extends string>(p: Promise<Record<T, ComponentType>>, key: T) =>
  lazy(() => p.then((m) => ({ default: m[key] })));

const Onboarding = named(import("@/routes/Onboarding"), "Onboarding");
const Login = named(import("@/routes/auth/Login"), "Login");
const Signup = named(import("@/routes/auth/Signup"), "Signup");
const ForgotPassword = named(import("@/routes/auth/ForgotPassword"), "ForgotPassword");
const Scan = named(import("@/routes/app/Scan"), "Scan");
const Study = named(import("@/routes/app/Study"), "Study");
const Listen = named(import("@/routes/app/Listen"), "Listen");
const Profile = named(import("@/routes/app/Profile"), "Profile");
const EditProfile = named(import("@/routes/app/EditProfile"), "EditProfile");
const ChangeEmail = named(import("@/routes/app/ChangeEmail"), "ChangeEmail");
const DeleteAccount = named(import("@/routes/app/DeleteAccount"), "DeleteAccount");
const Help = named(import("@/routes/app/Help"), "Help");

const lz = (el: React.ReactNode) => (
  <Suspense fallback={<FullPageSpinner />}>{el}</Suspense>
);
const authed = (el: React.ReactNode) => <RequireAuth>{lz(el)}</RequireAuth>;
const guestOnly = (el: React.ReactNode) => <RedirectIfAuthed>{lz(el)}</RedirectIfAuthed>;

export const router = createBrowserRouter([
  { path: "/", element: <Splash /> },
  { path: "/auth/callback", element: <AuthCallback /> },
  { path: "/onboarding", element: lz(<Onboarding />) },

  { path: "/login", element: guestOnly(<Login />) },
  { path: "/signup", element: guestOnly(<Signup />) },
  { path: "/forgot-password", element: guestOnly(<ForgotPassword />) },

  // Immersive full-screen flows (no shell chrome).
  { path: "/scan", element: authed(<Scan />) },
  { path: "/study", element: authed(<Study />) },
  { path: "/listen", element: authed(<Listen />) },

  // Shell routes.
  {
    element: <RequireAuth><AppLayout /></RequireAuth>,
    children: [
      { path: "/home", element: <Home /> },
      { path: "/decks", element: <Decks /> },
      { path: "/deck/:id", element: <DeckDetail /> },
      { path: "/profile", element: lz(<Profile />) },
      { path: "/edit-profile", element: lz(<EditProfile />) },
      { path: "/change-email", element: lz(<ChangeEmail />) },
      { path: "/delete-account", element: lz(<DeleteAccount />) },
      { path: "/help", element: lz(<Help />) },
    ],
  },

  { path: "*", element: <Splash /> },
]);
