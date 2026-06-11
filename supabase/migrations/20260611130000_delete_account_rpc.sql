-- Self-service account deletion.
-- Deleting auth.users cascades: profiles -> pets -> vaccinations,
-- medical_conditions, votes (and votes cast by the user via voter_id).
-- Storage rows can't be deleted via SQL (platform protection);
-- the app deletes avatar files through the Storage API before calling this.
create or replace function public.delete_account()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Remove the user; all app data cascades from here
  delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_account() from anon, public;
grant execute on function public.delete_account() to authenticated;
