# Goofny V2 — Database

PostgreSQL schema for the live Supabase project **GOOFNY V2** (`mfvrhacaqtizpdkqxpfm`, `ap-southeast-1`). All migrations in `supabase/migrations/` have been applied to production.

---

## Entity relationship diagram

```
auth.users
    │
    │ 1:1 (trigger on insert)
    ▼
profiles ─────────────────────────────┐
    │                               │
    │ 1:N                           │ voter_id
    ▼                               │
  pets ◄────────────────────────────┼── votes
    │                               │
    ├── 1:N vaccinations            │
    └── 1:N medical_conditions      │
                                    │
ranked_pets (view) ◄── pets         │
trending_pets (view) ◄── ranked_pets + votes (7-day window)

storage.buckets: pet-avatars (public)
  └── objects: {user_id}/{uuid}.jpg
```

---

## Tables

### `profiles`

Mirrors authenticated users. Created automatically on sign-up.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, FK → `auth.users(id)` ON DELETE CASCADE |
| `email` | `text` | NOT NULL |
| `display_name` | `text` | Nullable |
| `created_at` | `timestamptz` | NOT NULL, default `now()` |

**Trigger:** `on_auth_user_created` → `handle_new_user()` inserts a profile row with email and display name from `raw_user_meta_data` (falls back to email local-part).

---

### `pets`

Core pet profile data.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` |
| `owner_id` | `uuid` | NOT NULL, FK → `profiles(id)` ON DELETE CASCADE |
| `name` | `text` | NOT NULL, length 1–50 |
| `species` | `text` | NOT NULL, CHECK `('dog','cat')` |
| `sex` | `text` | NOT NULL, CHECK `('male','female')` |
| `breed` | `text` | NOT NULL |
| `age` | `integer` | NOT NULL, CHECK 0–50 |
| `birth_date` | `date` | Nullable (added in migration `20260611100000`) |
| `country` | `text` | NOT NULL — ISO 3166-1 alpha-2 |
| `city` | `text` | NOT NULL |
| `avatar_url` | `text` | Nullable |
| `notes` | `text` | Nullable — owner-only in views |
| `votes_count` | `integer` | NOT NULL, default 0 |
| `created_at` | `timestamptz` | NOT NULL, default `now()` |

**Indexes:** `owner_id`, `country`, `species`, `votes_count DESC`, `created_at DESC`

---

### `vaccinations`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` |
| `pet_id` | `uuid` | NOT NULL, FK → `pets(id)` ON DELETE CASCADE |
| `vaccine_name` | `text` | NOT NULL |
| `vaccination_date` | `date` | NOT NULL |
| `protection_months` | `integer` | NOT NULL, default 12, CHECK 1–120 |
| `reminder_enabled` | `boolean` | NOT NULL, default false |

**Index:** `pet_id`

---

### `medical_conditions`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` |
| `pet_id` | `uuid` | NOT NULL, FK → `pets(id)` ON DELETE CASCADE |
| `condition_name` | `text` | NOT NULL |
| `notes` | `text` | Nullable |

**Index:** `pet_id`

---

### `votes`

Immutable vote records. One per user per pet.

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` |
| `voter_id` | `uuid` | NOT NULL, FK → `profiles(id)` ON DELETE CASCADE |
| `pet_id` | `uuid` | NOT NULL, FK → `pets(id)` ON DELETE CASCADE |
| `created_at` | `timestamptz` | NOT NULL, default `now()` |

**Unique constraint:** `(voter_id, pet_id)`

**Indexes:** `pet_id`, `created_at DESC`

---

## Views

### `ranked_pets`

`SECURITY INVOKER` — RLS policies of the calling user apply.

Computes rankings and titles at query time:

| Output column | Source |
|---|---|
| All `pets` columns | `p.*` (with `notes` masked for non-owners) |
| `global_rank` | `rank()` over `(species)` ordered by `votes_count DESC, created_at ASC` |
| `country_rank` | `rank()` over `(species, country)` same ordering |
| `title` | `King` if top male in country/species with votes > 0; `Queen` if top female |

**Notes privacy:** `notes` is `NULL` unless `owner_id = auth.uid()`.

### `trending_pets`

Extends `ranked_pets` with:

| Column | Source |
|---|---|
| `recent_votes` | Count of votes in the last 7 days per pet (0 if none) |

Used by the feed when sort mode is **Trending**.

---

## Functions and triggers

| Object | Type | Purpose |
|---|---|---|
| `handle_new_user()` | Trigger function | Auto-create `profiles` row on `auth.users` INSERT |
| `sync_votes_count()` | Trigger function | Increment/decrement `pets.votes_count` on vote INSERT/DELETE |
| `votes_count_sync` | Trigger | AFTER INSERT OR DELETE on `votes` |
| `cast_vote(p_pet_id uuid)` | RPC | Insert vote (idempotent), return new `votes_count` |

### `cast_vote` behavior

```sql
-- Requires authenticated user (raises if auth.uid() is null)
INSERT INTO votes (voter_id, pet_id)
VALUES (auth.uid(), p_pet_id)
ON CONFLICT (voter_id, pet_id) DO NOTHING;

SELECT votes_count FROM pets WHERE id = p_pet_id;
RETURN new_count;
```

- **SECURITY DEFINER** with `search_path = public`
- Execute granted to `authenticated` only (revoked from `anon`, `public`)
- Internal trigger functions also revoked from API roles

---

## Row Level Security

RLS is enabled on all public tables.

### `profiles`

| Policy | Operation | Rule |
|---|---|---|
| `profiles_select` | SELECT | Everyone (`true`) |
| `profiles_update_own` | UPDATE | `auth.uid() = id` |

### `pets`

| Policy | Operation | Rule |
|---|---|---|
| `pets_select` | SELECT | Everyone |
| `pets_insert_own` | INSERT | `auth.uid() = owner_id` |
| `pets_update_own` | UPDATE | `auth.uid() = owner_id` |
| `pets_delete_own` | DELETE | `auth.uid() = owner_id` |

### `vaccinations`

| Policy | Operation | Rule |
|---|---|---|
| `vaccinations_modify_own` | ALL | Pet owner only (via subquery on `pets.owner_id`) |

> Public SELECT policy was **removed** in `20260611110000_private_health_records.sql`. Only owners can read vaccination rows.

### `medical_conditions`

| Policy | Operation | Rule |
|---|---|---|
| `medical_modify_own` | ALL | Pet owner only |

> Public SELECT policy removed — same as vaccinations.

### `votes`

| Policy | Operation | Rule |
|---|---|---|
| `votes_select` | SELECT | Everyone |
| `votes_insert_own` | INSERT | `auth.uid() = voter_id` |

No UPDATE or DELETE policies — votes are permanent.

---

## Storage

### Bucket: `pet-avatars`

| Property | Value |
|---|---|
| Public | `true` (objects served by direct URL) |
| Path pattern | `{user_id}/{uuid}.jpg` |
| Content type | `image/jpeg` |

### Storage policies

| Policy | Operation | Rule |
|---|---|---|
| `avatar_upload_own` | INSERT | Authenticated; folder[1] (lowercased) = `auth.uid()::text` |
| `avatar_update_own` | UPDATE | Same folder ownership check |
| `avatar_delete_own` | DELETE | Same folder ownership check |

> `avatar_public_read` was **dropped** in security hardening — public bucket serves files by URL without listing.

**Case sensitivity fix:** Policies use `lower(foldername)` because Swift's `UUID.uuidString` is uppercase while Postgres `auth.uid()::text` is lowercase.

---

## Realtime

Tables added to `supabase_realtime` publication:

- `public.votes`
- `public.pets`

The iOS app subscribes to `pets` UPDATE events and reads `votes_count` changes. Vote inserts on the `votes` table are published but not consumed client-side today.

---

## Migrations (chronological)

| File | Description |
|---|---|
| `20260610152618_initial_schema.sql` | Tables: profiles, pets, vaccinations, medical_conditions, votes; vote count sync trigger; profile auto-create trigger |
| `20260610152646_rankings_and_titles.sql` | Views: `ranked_pets`, `trending_pets`; RPC: `cast_vote` |
| `20260610152718_rls_policies_and_storage.sql` | RLS on all tables; `pet-avatars` bucket + policies; Realtime publication |
| `20260610153500_security_hardening.sql` | Revoke execute on internal functions; restrict `cast_vote` to authenticated; drop public storage read policy |
| `20260611000000_storage_policy_case_insensitive.sql` | Lowercase folder matching for avatar RLS |
| `20260611100000_add_birth_date.sql` | `birth_date` column on pets; recreate views |
| `20260611110000_private_health_records.sql` | Remove public read on health tables; mask `notes` in `ranked_pets` |
| `20260611120000_vaccine_module_v2.sql` | `protection_months`, `reminder_enabled` on vaccinations |

---

## Client ↔ database mapping

| Swift model | Table / view | Notes |
|---|---|---|
| `Profile` | `profiles` | |
| `Pet` | `pets`, `ranked_pets`, `trending_pets` | Ranking fields optional |
| `PetPayload` | `pets` (insert/update) | |
| `Vaccination` | `vaccinations` | Dates as `"yyyy-MM-dd"` strings |
| `MedicalCondition` | `medical_conditions` | |
| `Vote` | `votes` | Rarely decoded directly; IDs fetched for voted state |

### Query patterns (via `PetService`)

| App feature | Table / view |
|---|---|
| Feed (newest / most voted) | `ranked_pets` |
| Feed (trending) | `trending_pets` |
| Pet detail | `ranked_pets` |
| My pets | `ranked_pets` WHERE `owner_id` |
| Leaderboard | `ranked_pets` filtered + ordered |
| Create/update pet | `pets` |
| Vote | RPC `cast_vote` |

---

## Data integrity rules

| Rule | Enforcement |
|---|---|
| One vote per user per pet | `UNIQUE(voter_id, pet_id)` + `ON CONFLICT DO NOTHING` |
| Vote count accuracy | `sync_votes_count` trigger |
| Species/sex validity | CHECK constraints on `pets` |
| Pet name length | CHECK 1–50 characters |
| Age bounds | CHECK 0–50 |
| Protection months bounds | CHECK 1–120 |
| Cascade deletes | Deleting user → profiles → pets → vaccinations, conditions, votes |
| Titles require votes | `votes_count > 0` in view CASE expression |

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — how the app queries this schema
- [FEATURES.md](./FEATURES.md) — user-facing behavior backed by these tables
- [CURRENT_STATE.md](./CURRENT_STATE.md) — live deployment status
