-- ============================================================
-- GOOFNY V2 — Rankings, titles, trending
-- ============================================================

-- Ranked pets view: global + country rank, automatic King/Queen titles.
-- Titles update automatically because they are computed at query time.
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
  r.id, r.owner_id, r.name, r.species, r.sex, r.breed, r.age,
  r.country, r.city, r.avatar_url, r.notes, r.votes_count, r.created_at,
  r.global_rank, r.country_rank,
  case
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'male' then 'King'
    when r.country_sex_rank = 1 and r.votes_count > 0 and r.sex = 'female' then 'Queen'
    else null
  end as title
from ranked r;

-- Trending: votes received in the last 7 days
create or replace view public.trending_pets
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

-- RPC: cast a vote (idempotent-safe, returns new count)
create or replace function public.cast_vote(p_pet_id uuid)
returns integer
language plpgsql
security definer set search_path = public
as $$
declare
  new_count integer;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.votes (voter_id, pet_id)
  values (auth.uid(), p_pet_id)
  on conflict (voter_id, pet_id) do nothing;

  select votes_count into new_count from public.pets where id = p_pet_id;
  return new_count;
end;
$$;
