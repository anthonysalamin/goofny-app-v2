-- Add birth_date to pets; age stays for backward compatibility / sorting
alter table public.pets add column birth_date date;

-- Recreate views to expose the new column
drop view if exists public.trending_pets;
drop view if exists public.ranked_pets;

create view public.ranked_pets
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
  r.country, r.city, r.avatar_url, r.notes, r.votes_count, r.created_at,
  r.global_rank, r.country_rank,
  case
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'male' then 'King'
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'female' then 'Queen'
    else null
  end as title
from ranked r;

create view public.trending_pets
with (security_invoker = on)
as
select
  rp.*,
  coalesce(v.recent_votes, 0) as recent_votes
from public.ranked_pets rp
left join (
  select pet_id, count(*) as recent_votes
  from public.votes
  where created_at > now() - interval '7 days'
  group by pet_id
) v on v.pet_id = rp.id;
