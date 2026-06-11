-- Make avatar storage policies case-insensitive on the user-id folder
-- (Swift's UUID.uuidString is uppercase; auth.uid()::text is lowercase)

drop policy if exists "avatar_upload_own" on storage.objects;
create policy "avatar_upload_own" on storage.objects
  for insert with check (
    bucket_id = 'pet-avatars'
    and auth.role() = 'authenticated'
    and lower((storage.foldername(name))[1]) = auth.uid()::text
  );

drop policy if exists "avatar_update_own" on storage.objects;
create policy "avatar_update_own" on storage.objects
  for update using (
    bucket_id = 'pet-avatars'
    and lower((storage.foldername(name))[1]) = auth.uid()::text
  );

drop policy if exists "avatar_delete_own" on storage.objects;
create policy "avatar_delete_own" on storage.objects
  for delete using (
    bucket_id = 'pet-avatars'
    and lower((storage.foldername(name))[1]) = auth.uid()::text
  );
