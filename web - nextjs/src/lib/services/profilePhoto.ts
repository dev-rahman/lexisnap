// Profile photo upload — port of supabase_profile_photo_service.dart.
// Shrinks to 256px (canvas) before uploading to the public `avatars` bucket
// under avatars/<uid>/<timestamp>.jpg, then prunes older files.

import { getSupabaseBrowserClient } from "@/lib/supabase/client";

const BUCKET = "avatars";
const MAX_DIM = 256;
const QUALITY = 0.7;

async function shrinkToJpeg(file: File): Promise<Blob> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, MAX_DIM / Math.max(bitmap.width, bitmap.height));
  const w = Math.round(bitmap.width * scale);
  const h = Math.round(bitmap.height * scale);
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas unavailable");
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close();
  return await new Promise<Blob>((resolve, reject) =>
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error("Encode failed"))),
      "image/jpeg",
      QUALITY,
    ),
  );
}

/** Uploads the photo and returns its public URL. */
export async function uploadProfilePhoto(userId: string, file: File): Promise<string> {
  const supabase = getSupabaseBrowserClient();
  const blob = await shrinkToJpeg(file);
  const path = `${userId}/${Date.now()}.jpg`;

  const { error } = await supabase.storage.from(BUCKET).upload(path, blob, {
    contentType: "image/jpeg",
    cacheControl: "31536000",
    upsert: false,
  });
  if (error) throw new Error(error.message);

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  await pruneOldPhotos(userId, path);
  return data.publicUrl;
}

/** Removes every photo under the user's folder except [keep]. */
export async function pruneOldPhotos(userId: string, keepPath?: string): Promise<void> {
  const supabase = getSupabaseBrowserClient();
  const { data, error } = await supabase.storage.from(BUCKET).list(userId);
  if (error || !data) return;
  const toRemove = data
    .map((f: { name: string }) => `${userId}/${f.name}`)
    .filter((p: string) => p !== keepPath);
  if (toRemove.length > 0) {
    await supabase.storage.from(BUCKET).remove(toRemove);
  }
}
