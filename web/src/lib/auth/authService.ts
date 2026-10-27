// Client auth service — port of supabase_auth_service.dart for the web.
// The single place that talks to supabase.auth; UI/controllers call these.
// Google uses the OAuth redirect flow (web) instead of the native ID-token
// flow. Every method throws a plain Error whose message is user-facing.

import { getSupabaseBrowserClient } from "@/lib/supabase/client";

function supa() {
  return getSupabaseBrowserClient();
}

export async function signInWithEmail(
  email: string,
  password: string,
  captchaToken?: string,
): Promise<void> {
  const { error } = await supa().auth.signInWithPassword({
    email: email.trim(),
    password,
    options: captchaToken ? { captchaToken } : undefined,
  });
  if (error) throw new Error(error.message);
}

export async function signUpWithEmail(
  email: string,
  password: string,
  fullName?: string,
  captchaToken?: string,
): Promise<{ hasSession: boolean }> {
  const { data, error } = await supa().auth.signUp({
    email: email.trim(),
    password,
    options: {
      data: fullName ? { full_name: fullName } : undefined,
      captchaToken,
    },
  });
  if (error) throw new Error(error.message);
  return { hasSession: data.session != null };
}

export async function sendPasswordResetEmail(
  email: string,
  captchaToken?: string,
): Promise<void> {
  const { error } = await supa().auth.resetPasswordForEmail(email.trim(), {
    captchaToken,
  });
  if (error) throw new Error(error.message);
}

export async function verifyPasswordResetCode(
  email: string,
  code: string,
): Promise<void> {
  const { error } = await supa().auth.verifyOtp({
    type: "recovery",
    email: email.trim(),
    token: code.trim(),
  });
  if (error) throw new Error(error.message);
}

export async function updatePassword(password: string): Promise<void> {
  const { error } = await supa().auth.updateUser({ password });
  if (error) throw new Error(error.message);
}

export async function reauthenticate(password: string): Promise<void> {
  const email = supa().auth.getUser
    ? (await supa().auth.getUser()).data.user?.email
    : undefined;
  if (!email) throw new Error("Not signed in.");
  const { error } = await supa().auth.signInWithPassword({ email, password });
  if (error) throw new Error(error.message);
}

export async function requestEmailChange(newEmail: string): Promise<void> {
  const { error } = await supa().auth.updateUser({ email: newEmail.trim() });
  if (error) throw new Error(error.message);
}

export async function verifyEmailChangeCode(
  email: string,
  code: string,
): Promise<boolean> {
  const { data, error } = await supa().auth.verifyOtp({
    type: "email_change",
    email: email.trim(),
    token: code.trim(),
  });
  if (error) throw new Error(error.message);
  return data.session != null;
}

export async function updateProfile(fullName: string): Promise<void> {
  const { error } = await supa().auth.updateUser({
    data: { full_name: fullName },
  });
  if (error) throw new Error(error.message);
}

export async function updateProfilePhoto(url: string | null): Promise<void> {
  const { error } = await supa().auth.updateUser({ data: { photo_url: url } });
  if (error) throw new Error(error.message);
}

export async function deleteAccount(): Promise<void> {
  const { error } = await supa().functions.invoke("delete-account");
  if (error) throw new Error(error.message || "Account deletion failed.");
  await supa().auth.signOut({ scope: "local" });
}

export async function signInWithGoogle(): Promise<void> {
  const { error } = await supa().auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${window.location.origin}/auth/callback?next=/home`,
    },
  });
  if (error) throw new Error(error.message);
}

export async function signOut(): Promise<void> {
  const { error } = await supa().auth.signOut();
  if (error) throw new Error(error.message);
}
