-- ============================================================
-- GOOFNY V2 — Initial schema
-- ============================================================

-- ---------- profiles (mirrors auth.users) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- pets ----------
create table public.pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 50),
  species text not null check (species in ('dog','cat')),
  sex text not null check (sex in ('male','female')),
  breed text not null,
  age integer not null check (age >= 0 and age <= 50),
  country text not null,        -- ISO 3166-1 alpha-2 code, e.g. 'CH'
  city text not null,
  avatar_url text,
  notes text,
  votes_count integer not null default 0,
  created_at timestamptz not null default now()
);

create index pets_owner_idx on public.pets(owner_id);
create index pets_country_idx on public.pets(country);
create index pets_species_idx on public.pets(species);
create index pets_votes_idx on public.pets(votes_count desc);
create index pets_created_idx on public.pets(created_at desc);

-- ---------- vaccinations ----------
create table public.vaccinations (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  vaccine_name text not null,
  vaccination_date date not null
);
create index vaccinations_pet_idx on public.vaccinations(pet_id);

-- ---------- medical_conditions ----------
create table public.medical_conditions (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  condition_name text not null,
  notes text
);
create index medical_conditions_pet_idx on public.medical_conditions(pet_id);

-- ---------- votes ----------
create table public.votes (
  id uuid primary key default gen_random_uuid(),
  voter_id uuid not null references public.profiles(id) on delete cascade,
  pet_id uuid not null references public.pets(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (voter_id, pet_id)
);
create index votes_pet_idx on public.votes(pet_id);
create index votes_created_idx on public.votes(created_at desc);

-- Keep pets.votes_count in sync
create or replace function public.sync_votes_count()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.pets set votes_count = votes_count + 1 where id = new.pet_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.pets set votes_count = greatest(votes_count - 1, 0) where id = old.pet_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger votes_count_sync
  after insert or delete on public.votes
  for each row execute function public.sync_votes_count();
