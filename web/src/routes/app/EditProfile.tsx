import { useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Camera, ChevronRight, Lock, Mail, Trash2, User } from "lucide-react";

import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { TextField } from "@/components/ui/TextField";
import { PageHeader } from "@/components/shell/PageHeader";
import { mapUser } from "@/lib/auth/mapUser";
import {
  reauthenticate,
  updatePassword,
  updateProfile,
  updateProfilePhoto,
} from "@/lib/auth/authService";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";
import { uploadProfilePhoto } from "@/lib/services/profilePhoto";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { setUser } from "@/store/slices/authSlice";

export function EditProfile() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.auth.user);
  const fileRef = useRef<HTMLInputElement>(null);

  const [name, setName] = useState(user?.fullName ?? "");
  const [savingName, setSavingName] = useState(false);
  const [uploading, setUploading] = useState(false);

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [savingPassword, setSavingPassword] = useState(false);

  async function refreshUser() {
    const { data } = await getSupabaseBrowserClient().auth.getUser();
    dispatch(setUser(mapUser(data.user)));
  }

  async function onSaveName() {
    setSavingName(true);
    try {
      await updateProfile(name.trim());
      await refreshUser();
      toast.success(t("profile_name_updated"));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setSavingName(false);
    }
  }

  async function onPickPhoto(file?: File) {
    if (!file || !user) return;
    setUploading(true);
    try {
      const url = await uploadProfilePhoto(user.id, file);
      await updateProfilePhoto(url);
      await refreshUser();
      toast.success(t("common_success"));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setUploading(false);
    }
  }

  async function onSavePassword() {
    if (!newPassword) return;
    setSavingPassword(true);
    try {
      if (user?.hasPassword) await reauthenticate(currentPassword);
      await updatePassword(newPassword);
      setCurrentPassword("");
      setNewPassword("");
      toast.success(t("common_success"));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setSavingPassword(false);
    }
  }

  return (
    <div className="mx-auto max-w-xl">
      <PageHeader title={t("profile_edit_profile")} />

      <div className="space-y-5">
        {/* Avatar */}
        <div className="flex flex-col items-center">
          <button
            onClick={() => fileRef.current?.click()}
            className="group relative"
            disabled={uploading}
          >
            <Avatar name={user?.fullName} email={user?.email} src={user?.avatarUrl} size={104} />
            <span className="absolute -bottom-1 -right-1 grid h-9 w-9 place-items-center rounded-full border-4 border-paper bg-coral text-white">
              <Camera size={16} />
            </span>
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => onPickPhoto(e.target.files?.[0])}
          />
        </div>

        {/* Name */}
        <Card className="space-y-3">
          <TextField
            label={t("common_full_name")}
            leftIcon={<User size={18} />}
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <Button
            onClick={onSaveName}
            loading={savingName}
            disabled={!name.trim() || name.trim() === user?.fullName}
          >
            {t("common_save")}
          </Button>
        </Card>

        {/* Password */}
        <Card className="space-y-3">
          <h2 className="font-display text-lg font-extrabold text-ink">
            {t("forgot_password_new_password")}
          </h2>
          {user?.hasPassword && (
            <TextField
              label={t("common_password")}
              type="password"
              leftIcon={<Lock size={18} />}
              autoComplete="current-password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
            />
          )}
          <TextField
            label={t("forgot_password_new_password")}
            type="password"
            leftIcon={<Lock size={18} />}
            autoComplete="new-password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
          />
          <Button
            variant="secondary"
            onClick={onSavePassword}
            loading={savingPassword}
            disabled={!newPassword}
          >
            {t("common_save")}
          </Button>
        </Card>

        {/* Account links */}
        <Card padded={false} className="divide-y divide-border overflow-hidden">
          <button
            onClick={() => navigate("/change-email")}
            className="flex w-full items-center gap-3 px-4 py-3.5 hover:bg-ink/[0.03]"
          >
            <span className="grid h-9 w-9 place-items-center rounded-xl bg-hue-sky/15 text-hue-sky">
              <Mail size={18} />
            </span>
            <span className="flex-1 text-left font-semibold text-ink">
              {t("email_change_title")}
            </span>
            <ChevronRight size={18} className="text-ink-muted" />
          </button>
          <button
            onClick={() => navigate("/delete-account")}
            className="flex w-full items-center gap-3 px-4 py-3.5 hover:bg-error/5"
          >
            <span className="grid h-9 w-9 place-items-center rounded-xl bg-error/15 text-error">
              <Trash2 size={18} />
            </span>
            <span className="flex-1 text-left font-semibold text-error">
              {t("delete_title")}
            </span>
            <ChevronRight size={18} className="text-error/60" />
          </button>
        </Card>
      </div>
    </div>
  );
}
