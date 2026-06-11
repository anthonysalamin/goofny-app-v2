-- Health records & notes are private to the pet's owner.

-- Drop the public-read policies; the existing FOR ALL owner policies
-- already grant owners select/insert/update/delete.
drop policy if exists "vaccinations_select" on public.vaccinations;
drop policy if exists "medical_select" on public.medical_conditions;

-- Hide notes from non-owners in the views (security_invoker, so auth.uid() is the caller)
create or replace view public.ranked_pets
with (security_invoker = on)
as
with ranked as (
  select
    p.*,
    rank() over (partition by p.species order by p.votes_count desc, p.created_at asc) as global_rank,
    rank() over (partition by p.species, p.country order by p.votes_count desc, p.created_at asc) as country_rank,
    rank() over (partition by p.species, p.country, p.sex order by p.votes_count desc, p.created_at asc) as country_sex_rank
  from public.pets p
)
select
  r.id, r.owner_id, r.name, r.species, r.sex, r.breed, r.age, r.birth_date,
  r.country, r.city, r.avatar_url,
  case when r.owner_id = auth.uid() then r.notes else null end as notes,
  r.votes_count, r.created_at,
  r.global_rank, r.country_rank,
  case
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'male' then 'King'
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'female' then 'Queen'
    else null
  end as title
from ranked r;
