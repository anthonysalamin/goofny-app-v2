-- ============================================================
-- GOOFNY V2 — Security hardening (advisor fixes)
-- ============================================================

-- Trigger functions should never be callable via the API
revoke execute on function public.handle_new_user() from anon, authenticated, public;
revoke execute on function public.sync_votes_count() from anon, authenticated, public;

-- cast_vote: only signed-in users may call it (it also checks auth.uid() internally)
revoke execute on function public.cast_vote(uuid) from anon, public;
grant execute on function public.cast_vote(uuid) to authenticated;

-- Public bucket serves objects by URL; no need to allow listing all files
drop policy if exists "avatar_public_read" on storage.objects;
