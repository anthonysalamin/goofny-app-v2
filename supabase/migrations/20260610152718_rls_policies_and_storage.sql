-- ============================================================
-- GOOFNY V2 — RLS policies + storage bucket
-- ============================================================

alter table public.profiles enable row level security;
alter table public.pets enable row level security;
alter table public.vaccinations enable row level security;
alter table public.medical_conditions enable row level security;
alter table public.votes enable row level security;

-- profiles: everyone can read, users edit only their own
create policy "profiles_select" on public.profiles
  for select using (true);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- pets: public read; owners insert/update/delete their own
create policy "pets_select" on public.pets
  for select using (true);
create policy "pets_insert_own" on public.pets
  for insert with check (auth.uid() = owner_id);
create policy "pets_update_own" on public.pets
  for update using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "pets_delete_own" on public.pets
  for delete using (auth.uid() = owner_id);

-- vaccinations / medical_conditions: public read; owner of pet manages
create policy "vaccinations_select" on public.vaccinations
  for select using (true);
create policy "vaccinations_modify_own" on public.vaccinations
  for all using (exists (select 1 from public.pets p where p.id = pet_id and p.owner_id = auth.uid()))
  with check (exists (select 1 from public.pets p where p.id = pet_id and p.owner_id = auth.uid()));

create policy "medical_select" on public.medical_conditions
  for select using (true);
create policy "medical_modify_own" on public.medical_conditions
  for all using (exists (select 1 from public.pets p where p.id = pet_id and p.owner_id = auth.uid()))
  with check (exists (select 1 from public.pets p where p.id = pet_id and p.owner_id = auth.uid()));

-- votes: public read; users create their own votes; no update; no delete
create policy "votes_select" on public.votes
  for select using (true);
create policy "votes_insert_own" on public.votes
  for insert with check (auth.uid() = voter_id);
-- (no update/delete policies => votes are immutable)

-- Storage: public bucket for pet avatars
insert into storage.buckets (id, name, public)
values ('pet-avatars', 'pet-avatars', true)
on conflict (id) do nothing;

create policy "avatar_public_read" on storage.objects
  for select using (bucket_id = 'pet-avatars');
create policy "avatar_upload_own" on storage.objects
  for insert with check (
    bucket_id = 'pet-avatars'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "avatar_update_own" on storage.objects
  for update using (
    bucket_id = 'pet-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "avatar_delete_own" on storage.objects
  for delete using (
    bucket_id = 'pet-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Realtime on votes & pets so vote counts update live
alter publication supabase_realtime add table public.votes;
alter publication supabase_realtime add table public.pets;
