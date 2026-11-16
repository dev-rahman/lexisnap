"use client";

import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { Camera, ChevronRight } from "lucide-react";

import { PageShell } from "@/components/shell/PageShell";

import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { Sheet } from "@/components/ui/Sheet";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import * as auth from "@/lib/auth/authService";
import { pruneOldPhotos, uploadProfilePhoto } from "@/lib/services/profilePhoto";
import { toast } from "@/lib/toast";
import { useAppSelector } from "@/store/hooks";

export default function EditProfilePage() {
  const t = useT();
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);
  const [name, setName] = useState("");
  const [saving, setSaving] = useState(false);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [pwdOpen, setPwdOpen] = useState(false);
  const fileInput = useRef<HTMLInputElement>(null);

  useEffect(() => setName(user?.fullName ?? ""), [user?.fullName]);

  async function saveName() {
    if (!name.trim() || name.trim() === user?.fullName) return;
    setSaving(true);
    try {
      await auth.updateProfile(name.trim());
      toast.success(t("profile_name_updated"));
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setSaving(false);
    }
  }

  async function onPhoto(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !user) return;
    setPhotoBusy(true);
    try {
      const url = await uploadProfilePhoto(user.id, file);
      await auth.updateProfilePhoto(url);
      toast.success(t("photo_updated"));
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setPhotoBusy(false);
    }
  }

  async function removePhoto() {
    if (!user) return;
    setPhotoBusy(true);
    try {
      await auth.updateProfilePhoto(null);
      await pruneOldPhotos(user.id);
      toast.success(t("photo_removed"));
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setPhotoBusy(false);
    }
  }

  return (
    <PageShell title={t("edit_profile_title")}>
      <div>
        {/* Photo */}
        <div className="mb-6 flex flex-col items-center gap-3 py-4">
          <div className="relative">
            <Avatar src={user?.avatarUrl} name={user?.fullName} email={user?.email} size={96} />
            <button
              onClick={() => fileInput.current?.click()}
              disabled={photoBusy}
              className="absolute -bottom-1 -right-1 flex h-9 w-9 items-center justify-center rounded-full bg-accent text-white shadow"
              aria-label={t("photo_take")}
            >
              <Camera size={18} />
            </button>
          </div>
          <input ref={fileInput} type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={onPhoto} />
          {user?.hasOwnPhoto && (
            <button onClick={removePhoto} disabled={photoBusy} className="text-sm font-medium text-error">
              {t("photo_remove")}
            </button>
          )}
        </div>

        {/* Name */}
        <TextField label={t("edit_profile_name")} value={name} onChange={(e) => setName(e.target.value)} />
        <Button variant="primary" fullWidth className="mt-3" loading={saving} onClick={saveName}>
          {t("common_save")}
        </Button>

        {/* Account rows */}
        <div className="mt-6 overflow-hidden rounded-xl border border-border">
          <Row label={t("common_email")} value={user?.email ?? ""} onClick={() => router.push("/change-email")} />
          <Row label={user?.hasPassword ? t("password_change_title") : t("password_set_title")} onClick={() => setPwdOpen(true)} />
        </div>

        {/* Danger zone */}
        <div className="mt-6">
          <div className="mb-2 text-xs font-semibold uppercase text-error">{t("edit_profile_danger_zone")}</div>
          <button
            onClick={() => router.push("/delete-account")}
            className="flex w-full items-center justify-between rounded-xl border border-error/40 bg-error/5 px-4 py-3.5 font-semibold text-error"
          >
            {t("edit_profile_delete_account")}
            <ChevronRight size={18} />
          </button>
        </div>
      </div>

      <PasswordSheet open={pwdOpen} onClose={() => setPwdOpen(false)} hasPassword={user?.hasPassword ?? false} />
    </PageShell>
  );
}

function Row({ label, value, onClick }: { label: string; value?: string; onClick: () => void }) {
  return (
    <button onClick={onClick} className="flex w-full items-center gap-3 border-b border-border bg-surface px-4 py-3.5 text-left last:border-b-0">
      <span className="flex-1 font-medium text-ink">{label}</span>
      {value && <span className="max-w-[55%] truncate text-sm text-ink-muted">{value}</span>}
      <ChevronRight size={18} className="text-ink-muted" />
    </button>
  );
}

function PasswordSheet({ open, onClose, hasPassword }: { open: boolean; onClose: () => void; hasPassword: boolean }) {
  const t = useT();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [busy, setBusy] = useState(false);

  async function save() {
    if (next.length < 8) {
      toast.error(t("validator_password_too_short"));
      return;
    }
    setBusy(true);
    try {
      if (hasPassword) {
        try {
          await auth.reauthenticate(current);
        } catch {
          toast.error(t("password_wrong_current"));
          return;
        }
      }
      await auth.updatePassword(next);
      toast.success(t("forgot_password_updated"));
      onClose();
      setCurrent("");
      setNext("");
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <Sheet open={open} onClose={onClose} title={hasPassword ? t("password_change_title") : t("password_set_title")}>
      {!hasPassword && <p className="mb-3 text-sm text-ink-muted">{t("password_set_body")}</p>}
      <div className="space-y-3">
        {hasPassword && (
          <TextField type="password" label={t("password_current")} value={current} onChange={(e) => setCurrent(e.target.value)} />
        )}
        <TextField type="password" label={t("forgot_password_new_password")} value={next} onChange={(e) => setNext(e.target.value)} />
      </div>
      <Button variant="primary" fullWidth className="mt-4" loading={busy} onClick={save}>
        {t("common_save")}
      </Button>
    </Sheet>
  );
}
