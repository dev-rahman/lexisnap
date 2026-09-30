-- Profile photos: a public bucket with one folder per user,
-- avatars/<user id>/<timestamp>.jpg.
--
-- Public because an avatar is shown wherever the user is, and a public URL
-- can be cached; the unguessable user id in the path is the only "secret".
-- Writes are limited to the user's own folder by the policies below.
--
-- The app shrinks photos to 256px before uploading, which lands around
-- 15-30 KB. The 256 KB limit is the server-side backstop for anything that
-- skips the app.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  262144,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Listing is needed to clear out a user's older photos; reading a photo
-- itself goes through the public URL and needs no policy.
create policy "Users list their own profile photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users upload their own profile photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users delete their own profile photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
