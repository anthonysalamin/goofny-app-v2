# Goofny V2 — Features

A feature-by-feature reference for the current app. Status reflects what is implemented in code and deployed to the live Supabase project as of the latest migrations.

**Legend:** ✅ Implemented · ⚠️ Partial / requires manual setup · ❌ Not implemented

---

## Authentication

| Feature | Status | Notes |
|---|---|---|
| Email/password sign-up | ✅ | Display name stored in `raw_user_meta_data`; profile auto-created via trigger |
| Email/password sign-in | ✅ | |
| Password reset | ✅ | Sends reset email via Supabase; redirect URL `goofny://auth-callback` |
| Google Sign-In | ⚠️ | Code complete; provider credentials must be configured in Supabase Dashboard |
| Facebook Login | ⚠️ | Code complete; provider credentials must be configured in Supabase Dashboard |
| OAuth deep-link handling | ✅ | `goofny://auth-callback` handled in `GoofnyApp.onOpenURL` |
| Session persistence | ✅ | Local session restored on launch; expired sessions refreshed |
| Sign out | ✅ | Settings → confirmation dialog |
| Email confirmation flow | ✅ | Shows "Check your inbox" when sign-up returns no session |

---

## User profile

| Feature | Status | Notes |
|---|---|---|
| Auto-created profile on registration | ✅ | `profiles` row mirrors `auth.users` |
| Display name editing | ✅ | Settings screen |
| Email display (read-only) | ✅ | |
| Profile stats | ✅ | Pet count, total votes received, best country rank |
| Royal titles showcase | ✅ | Lists crowned pets with country |
| Settings / About links | ✅ | Version 2.0.0, Terms, Privacy links |

---

## Pet profiles

### Core fields

| Field | Status | Notes |
|---|---|---|
| Profile photo (avatar) | ✅ | Required; PhotosPicker; resized to 1024 px, JPEG 80% |
| Name | ✅ | Required; max 50 chars (DB constraint) |
| Species | ✅ | Dog or Cat |
| Sex | ✅ | Male or Female |
| Breed | ✅ | Required; searchable picker from `Breeds` catalog + "Other" |
| Birth date | ✅ | Date picker; age derived automatically |
| Age (stored) | ✅ | Computed from birth date on save; used for display fallback |
| Country | ✅ | ISO 3166-1 alpha-2; full country list from system locale |
| City | ✅ | Required free text |
| Notes | ✅ | Optional; **owner-only** visibility |

### Metadata (computed / stored)

| Field | Status | Notes |
|---|---|---|
| Registration date | ✅ | `created_at` |
| Total votes | ✅ | `votes_count`, kept in sync by DB trigger |
| Global rank | ✅ | From `ranked_pets` view |
| Country rank | ✅ | From `ranked_pets` view |
| Title (King / Queen) | ✅ | Auto-assigned in `ranked_pets` view |

### Pet management

| Feature | Status | Notes |
|---|---|---|
| Add pet (dedicated tab) | ✅ | Resets form and navigates to Home on save |
| Edit pet | ✅ | From pet detail (owner only) |
| Delete pet | ✅ | From edit form; cascades health records and votes |
| Multiple pets per user | ✅ | No limit enforced |
| Avatar upload to Supabase Storage | ✅ | `pet-avatars/{userId}/{uuid}.jpg` |

---

## Health records

| Feature | Status | Notes |
|---|---|---|
| Vaccination records | ✅ | Name, date, protection duration, reminder toggle |
| Species-specific vaccine catalog | ✅ | `VaccineCatalog` with veterinary defaults (DHPP, FVRCP, Rabies, etc.) |
| Custom protection duration | ✅ | 1–120 months; defaults from catalog |
| Overdue / due-soon indicators | ✅ | Computed client-side (`isOverdue`, `isDueSoon`) |
| Medical conditions | ✅ | Name + optional notes |
| Add health records during pet creation | ✅ | Held as pending until pet is saved |
| Owner-only visibility | ✅ | RLS + `ranked_pets` view masks notes for non-owners |
| Vaccine renewal reminders | ✅ | Local iOS notifications: 14 days before + on due date |

---

## Discovery feed (Home)

| Feature | Status | Notes |
|---|---|---|
| Browse all pets | ✅ | Paginated (20 per page), infinite scroll |
| Pull-to-refresh | ✅ | |
| Pet cards | ✅ | Photo, name, breed, country, rank, title badge, vote button |
| Navigate to pet detail | ✅ | |
| Search by pet name | ✅ | Debounced 350 ms, case-insensitive |
| Filter by species | ✅ | |
| Filter by country | ✅ | |
| Filter by city | ✅ | Partial match (`ilike`) |
| Filter by breed | ✅ | Partial match (`ilike`) |
| Filter by sex | ✅ | |
| Sort: Newest | ✅ | |
| Sort: Most Voted | ✅ | |
| Sort: Trending | ✅ | Votes in last 7 days (`trending_pets` view) |
| Empty states | ✅ | No pets / no filter results |
| Auto-refresh on tab return | ✅ | Reloads when returning from Add Pet |

---

## Voting

| Feature | Status | Notes |
|---|---|---|
| One-tap vote from feed | ✅ | Heart button on pet card |
| Vote from pet detail | ✅ | Full-width button (non-owner pets) |
| One vote per pet per user | ✅ | `unique(voter_id, pet_id)` + `ON CONFLICT DO NOTHING` |
| Votes are immutable | ✅ | No update/delete RLS policies on `votes` |
| Optimistic UI (feed) | ✅ | Reverts on error |
| Voted state persistence | ✅ | Loaded from `votes` table on feed init |
| Live vote count updates | ✅ | Supabase Realtime on `pets` table |
| Haptic feedback on vote | ✅ | `sensoryFeedback(.success)` |

---

## Rankings and titles

| Feature | Status | Notes |
|---|---|---|
| Global rank (per species) | ✅ | `ranked_pets.global_rank` |
| Country rank (per species) | ✅ | `ranked_pets.country_rank` |
| King title (top male per country/species) | ✅ | Requires `votes_count > 0` |
| Queen title (top female per country/species) | ✅ | Requires `votes_count > 0` |
| Automatic title updates | ✅ | Computed at query time in SQL view |
| Title badges in UI | ✅ | Feed cards, detail, profile, leaderboard |

**Tie-breaking:** Higher votes win; equal votes broken by earlier `created_at`.

---

## Leaderboards

| Feature | Status | Notes |
|---|---|---|
| Global Dogs | ✅ | Scope: Global, Species: Dog |
| Global Cats | ✅ | Scope: Global, Species: Cat |
| Country Dogs | ✅ | Scope: By Country + country picker |
| Country Cats | ✅ | Scope: By Country + country picker |
| Top 100 pets per query | ✅ | Sorted by `votes_count desc` |
| Medal icons for top 3 | ✅ | 🥇 🥈 🥉 |
| Pull-to-refresh | ✅ | |
| Navigate to pet detail | ✅ | |

---

## UI / UX

| Feature | Status | Notes |
|---|---|---|
| Tab bar navigation | ✅ | Home, Leaderboard, Add Pet, Profile |
| Light mode only | ✅ | Enforced in `project.yml` |
| Loading states | ✅ | Progress views on feed, leaderboard, profile |
| Error alerts | ✅ | Feed, pet detail, auth errors |
| Toast component | ✅ | `ToastView` exists (available for future use) |
| Empty state component | ✅ | `EmptyStateView` reused across screens |
| Async image loading | ✅ | `PetAvatarView` with placeholder |
| Animated vote counts | ✅ | `.contentTransition(.numericText())` |

---

## Not implemented (planned / future)

These appear in the original product spec (`documentation/prompt.md`) but are **not** in the current codebase:

| Feature | Status |
|---|---|
| Push notifications (remote) | ❌ Only local vaccine reminders exist |
| In-app notifications center | ❌ |
| Comments on pets | ❌ |
| Likes (separate from votes) | ❌ |
| Pet / user following | ❌ |
| Featured / sponsored pets | ❌ |
| Premium profiles / monetization | ❌ |
| Breed detection (AI) | ❌ |
| Health insights (AI) | ❌ |
| Daily challenges / achievements | ❌ |
| Realtime leaderboard refresh | ❌ Leaderboard reloads on pull-to-refresh or filter change only |
| Android / web clients | ❌ iOS only |
| Apple Sign-In | ❌ |
| Camera capture for avatar | ⚠️ `NSCameraUsageDescription` set; UI uses PhotosPicker only |

---

## Feature map by screen

```
AuthFlowView
├── LoginView          → email/password, Google, Facebook, forgot password link
├── RegisterView       → display name, email, password
└── ForgotPasswordView → reset email

MainTabView
├── HomeFeedView       → feed, search, filters, sort, vote, pet detail
├── LeaderboardView    → global/country rankings by species
├── AddPetTabView      → PetFormView (create mode)
└── ProfileView        → stats, titles, my pets, settings
    └── SettingsView   → display name, sign out, about

PetDetailView          → full profile, vote, owner health records, edit
PetFormView            → add/edit pet, avatar, health records, delete
VaccineFormView        → add/edit vaccination with catalog + reminders
FilterSheetView        → species, country, city, breed, sex filters
BreedPickerView        → searchable breed list
```

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — how features are wired technically
- [DATABASE.md](./DATABASE.md) — persistence layer behind features
- [CURRENT_STATE.md](./CURRENT_STATE.md) — deployment status and gaps
