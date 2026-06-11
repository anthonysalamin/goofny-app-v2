# Goofny V2 🐶🐱

A mobile-first iOS app where pet lovers create profiles for their dogs and cats, vote for the cutest pets, and compete in country-based rankings. Top pets earn **King** 👑 and **Queen** 💎 titles in their country.

## Stack

| Layer | Technology |
|---|---|
| Frontend | SwiftUI (iOS 17+), MVVM, async/await |
| Backend | Supabase — project **GOOFNY V2** (`mfvrhacaqtizpdkqxpfm`, Singapore) |
| Database | PostgreSQL with RLS |
| Auth | Supabase Auth (email/password + Google + Facebook OAuth) |
| Storage | Supabase Storage (`pet-avatars` public bucket) |
| Realtime | Supabase Realtime (live vote counts) |

## Project structure

```
Goofny/
├── GoofnyApp.swift            # App entry + auth routing + OAuth deep links
├── Config/AppConfig.swift     # Supabase URL/key, redirect URL
├── Core/SupabaseManager.swift # Shared Supabase client
├── Models/                    # Pet, Profile, Vote, Vaccination, …, Country/Breeds helpers
├── Services/                  # Auth, Pet, Vote, Storage, Realtime (data layer)
├── ViewModels/                # MVVM view models (@MainActor, ObservableObject)
└── Views/
    ├── Auth/                  # Login, Register, Forgot Password
    ├── Feed/                  # Home feed, pet cards, filter sheet
    ├── PetDetail/             # Pet profile page with voting
    ├── Pets/                  # Add/Edit pet form (photos, health records)
    ├── Leaderboard/           # Global & country leaderboards
    ├── Profile/               # My pets, stats, titles, settings
    └── Components/            # Shared UI (avatars, badges, vote button)
supabase/migrations/           # Database schema (already applied to the live project)
project.yml                    # XcodeGen project definition
```

## Getting started

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. From the repo root: `xcodegen generate`
3. Open `Goofny.xcodeproj` — Xcode resolves the `supabase-swift` package automatically.
4. Build & run on iOS 17+.

(Alternative without XcodeGen: create a new iOS App project in Xcode named "Goofny", drag the `Goofny/` folder in, add the `supabase-swift` package, set the `goofny` URL scheme, and add photo-library/camera usage descriptions.)

## Backend — already live

The Supabase project is created and migrated. The anon/publishable key in `AppConfig.swift` is safe to ship; Row Level Security protects all data:

- Pets/votes/profiles publicly readable; only owners can modify their pets.
- Votes are insert-only with a `unique(voter_id, pet_id)` constraint — duplicate votes are impossible at the database level.
- `cast_vote(p_pet_id)` RPC handles voting atomically and returns the new count.
- `ranked_pets` view computes global rank, country rank, and King/Queen titles at query time, so **titles update automatically** as votes change.
- `trending_pets` view ranks by votes in the last 7 days.
- Realtime is enabled on `pets` and `votes` for live vote counts in the feed.

### Remaining manual setup (Supabase Dashboard → Authentication)

1. **Google**: enable the Google provider and add OAuth client credentials.
2. **Facebook**: enable the Facebook provider and add app credentials.
3. **Redirect URL**: add `goofny://auth-callback` under Authentication → URL Configuration → Redirect URLs.

Email/password auth works out of the box.

## Features

- Email/password + Google + Facebook sign-in, password reset
- Multi-pet profiles: photo, name, species, sex, breed, age, country, city, optional vaccinations / medical conditions / notes
- Discovery feed with pagination, pull-to-refresh, and live vote counts
- Search by name; filter by species, country, city, breed, sex; sort by newest / most voted / trending
- One-tap voting (one vote per pet per user, enforced server-side)
- Leaderboards: Global Dogs, Global Cats, Country Dogs, Country Cats
- Automatic King/Queen titles per country, species, and sex
- Profile with stats (pets, total votes, best rank) and royal titles
