# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Goofny V2 is a native iOS mobile app (SwiftUI, iOS 17+) for a pet-centric social platform. Users create profiles for their dogs/cats, vote for pets, and compete in country-based rankings. Backend is live on Supabase (project `mfvrhacaqtizpdkqxpfm`, Singapore region).

## Essential Commands

### Project Setup
```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Generate Xcode project from project.yml
xcodegen generate

# Open project in Xcode
open Goofny.xcodeproj
```

Then build and run in Xcode on iOS 17+ simulator or device.

### Development
- **Build:** Cmd+B in Xcode
- **Run:** Cmd+R in Xcode (builds + launches in simulator/device)
- **Clean build folder:** Cmd+Shift+K in Xcode

**Note:** There is no automated test suite in this codebase. Testing is done manually in Xcode.

## Architecture

### MVVM Pattern
```
Views (SwiftUI) → ViewModels (@MainActor) → Services (structs) → SupabaseManager → Supabase
```

**Key principles:**
- **Views**: Stateless SwiftUI, observe ViewModels via `@StateObject`/`@EnvironmentObject`
- **ViewModels**: `@MainActor` `ObservableObject`, manage state with `@Published`, orchestrate business logic
- **Services**: Stateless structs, encapsulate Supabase API calls, no UI state
- **SupabaseManager**: Singleton (`SupabaseManager.shared.client`) providing shared Supabase client
- **Models**: Codable structs that decode directly from Supabase responses

### Directory Structure
```
Goofny/
├── GoofnyApp.swift              # App entry, auth routing, OAuth deep link handling
├── Config/AppConfig.swift       # Supabase URL, key, redirect URL, bucket names
├── Core/SupabaseManager.swift   # Singleton Supabase client
├── Models/                      # Data models (Pet, Profile, Vote, Vaccination, etc.)
├── Services/                    # Data layer: Auth, Pet, Vote, Storage, Realtime, Notification
├── ViewModels/                  # MVVM orchestration layer
└── Views/                       # SwiftUI UI components
    ├── Auth/                    # Login, register, forgot password
    ├── Feed/                    # Home feed, pet cards, filters
    ├── PetDetail/               # Pet profile page
    ├── Pets/                    # Add/Edit pet forms, health records
    ├── Leaderboard/             # Rankings
    ├── Profile/                 # User stats, my pets, settings
    └── Components/              # Reusable UI (cards, badges, buttons)
```

### Authentication Flow
1. User action (sign in/up/OAuth) → `AuthViewModel` → `AuthService` → Supabase Auth
2. `SupabaseManager.client.auth.authStateChanges` monitored continuously
3. On state change: `RootView` switches between loading spinner, `AuthFlowView`, or `MainTabView`
4. OAuth callbacks (`goofny://auth-callback`) handled by `.onOpenURL` in `GoofnyApp.swift`
5. Profile auto-created via database trigger (`handle_new_user`) on sign-up

### Key Data Flows

**Feed and Voting:**
- `FeedViewModel` fetches from `ranked_pets` or `trending_pets` database views (20 per page)
- `RealtimeService` subscribes to live `votes_count` updates via Supabase Realtime
- Voting: optimistic UI update → `VoteService.vote()` → RPC `cast_vote(p_pet_id)` → database update
- Duplicate votes prevented by `UNIQUE(voter_id, pet_id)` constraint

**Pet Management:**
- `PetFormViewModel` handles form state and validation
- `StorageService` uploads avatars to `pet-avatars/{userId}/{uuid}.jpg` (lowercase UUID)
- `PetService.createPet()` inserts pet with vaccination/condition records
- Health records (vaccinations, medical conditions) RLS-restricted to pet owner only

**Rankings and Titles:**
- Computed server-side in `ranked_pets` view (not client-side)
- `global_rank`: rank within species across all countries
- `country_rank`: rank within species + country
- `title`: King (top male) or Queen (top female) per country/species/sex (only if votes > 0)

## Database Architecture

**Backend:** Supabase PostgreSQL with Row Level Security (RLS)

**Core tables:**
- `profiles` – User accounts (1:1 with auth.users)
- `pets` – Pet profiles with species, breed, location, vote count
- `vaccinations` – Health records (owner-only via RLS)
- `medical_conditions` – Pet health notes (owner-only via RLS)
- `votes` – Vote records (unique per user per pet)

**Database views:**
- `ranked_pets` – Adds computed rankings and King/Queen titles
- `trending_pets` – Extends ranked_pets with 7-day vote trend

**RPC functions:**
- `cast_vote(p_pet_id)` – Atomic: INSERT vote + return updated vote count
- `delete_account()` – Cascades deletion of user and all their data
- `handle_new_user()` – Trigger: auto-creates profile on sign-up
- `sync_votes_count()` – Trigger: keeps pets.votes_count in sync

**Security model:**
- All tables have RLS enabled
- Publishable key ships in app; data protected by RLS, not secrecy
- Storage policies scoped to `{user_id}/` folder
- Health records private to pet owner
- Votes are insert-only (no update/delete)

## Configuration

**AppConfig.swift** contains:
- Supabase URL: `https://mfvrhacaqtizpdkqxpfm.supabase.co`
- Publishable anon key (safe to ship, RLS protected)
- OAuth redirect URL: `goofny://auth-callback`
- Avatar bucket: `pet-avatars`

**project.yml** (XcodeGen):
- Defines iOS target, bundle ID (`com.goofny.app`), deployment target (iOS 17+)
- SPM dependency: `supabase-swift` ≥ 2.0.0
- URL scheme: `goofny` (for OAuth callbacks)

**Info.plist:**
- Permissions: Photo library, Camera
- URL schemes: `goofny`
- Light mode enforced

## Important Patterns & Conventions

### When Adding New Features

1. **Models**: Add Codable structs in `Models/` with proper CodingKeys for snake_case database columns
2. **Service**: Create/extend service struct in `Services/` for Supabase API calls
3. **ViewModel**: Create `@MainActor` ObservableObject in `ViewModels/` with `@Published` state
4. **View**: Create SwiftUI view in appropriate `Views/` subdirectory, observe ViewModel
5. **Database**: Add migration SQL file to `supabase/migrations/` if schema changes needed

### Code Style
- Use async/await (not callbacks)
- Services are stateless structs (not classes)
- ViewModels are `@MainActor` classes conforming to `ObservableObject`
- Models use explicit `CodingKeys` enum for Postgres snake_case mapping
- Avatar paths use lowercase UUID strings (`UUID().uuidString.lowercased()`) to match RLS

### Common Gotchas

**Storage RLS case sensitivity:**
- Swift `UUID().uuidString` is uppercase
- Postgres `auth.uid()::text` is lowercase
- Always use `.lowercased()` when creating avatar paths

**Health records privacy:**
- Vaccinations and medical conditions are owner-only via RLS
- Only fetch health data when `userID == pet.ownerId`
- `ranked_pets` view nulls `notes` field for non-owners

**Realtime subscriptions:**
- Subscribe to `pets` table for vote count updates
- Remember to unsubscribe in `deinit` or when view disappears

**Search debouncing:**
- Use 350ms debounce on search text to reduce server load
- Implemented via `.task(id: searchText)` with `Task.sleep`

**Optimistic UI updates:**
- Update UI immediately for better UX
- Roll back on error
- Example: voting increments count immediately, reverts if RPC fails

## Backend (Supabase)

**Status:** Live and production-ready
**Region:** Singapore (ap-southeast-1)
**Project ID:** mfvrhacaqtizpdkqxpfm

**Manual setup remaining (in Supabase Dashboard):**
1. Google OAuth provider credentials (Auth → Providers → Google)
2. Facebook OAuth provider credentials (Auth → Providers → Facebook)
3. Add redirect URL `goofny://auth-callback` (Auth → URL Configuration)

All database migrations in `supabase/migrations/` are applied to production.

## Related Documentation

- `README.md` – Quick start, stack overview, features
- `documentation/ARCHITECTURE.md` – Detailed system design, data flows, security model
- `documentation/DATABASE.md` – Full schema, RLS policies, views, functions, migrations
- `documentation/FEATURES.md` – User-facing capabilities
- `documentation/CURRENT_STATE.md` – Deployment status and setup notes
