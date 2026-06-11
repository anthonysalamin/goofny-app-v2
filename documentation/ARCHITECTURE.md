# Goofny V2 — Architecture

This document describes how the Goofny iOS app is structured today: layers, data flow, backend integration, and security boundaries.

---

## System overview

Goofny is a native iOS app (SwiftUI, iOS 17+) backed by a live Supabase project. Users authenticate, create pet profiles, browse a global discovery feed, vote for pets, and compete on country-based leaderboards. Rankings and royal titles (King / Queen) are computed in PostgreSQL views — not in the client.

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                        │
│  ┌──────────┐  ┌─────────────┐  ┌──────────┐  ┌─────────────┐  │
│  │  Views   │→ │ ViewModels  │→ │ Services │→ │ Supabase    │  │
│  │ (SwiftUI)│  │ (@MainActor)│  │ (structs)│  │ Manager     │  │
│  └──────────┘  └─────────────┘  └──────────┘  └──────┬──────┘  │
└───────────────────────────────────────────────────────┼─────────┘
                                                        │
                        ┌───────────────────────────────┼───────────────────────────────┐
                        │              Supabase (GOOFNY V2, ap-southeast-1)             │
                        │  Auth │ PostgreSQL + RLS │ Storage │ Realtime │ RPC          │
                        └───────────────────────────────────────────────────────────────┘
```

| Layer | Technology |
|---|---|
| Client | SwiftUI, MVVM, Swift 5.9, async/await |
| Backend | Supabase (project `mfvrhacaqtizpdkqxpfm`, Singapore) |
| Database | PostgreSQL with Row Level Security |
| Auth | Supabase Auth (email/password + OAuth) |
| Storage | Supabase Storage (`pet-avatars` public bucket) |
| Realtime | Supabase Realtime on `pets` table |

---

## Architectural pattern: MVVM

The app follows **Model–View–ViewModel** with a thin **Service** layer between ViewModels and Supabase.

| Layer | Responsibility | Location |
|---|---|---|
| **View** | SwiftUI UI, navigation, user input | `Goofny/Views/` |
| **ViewModel** | UI state, orchestration, error handling | `Goofny/ViewModels/` |
| **Service** | Supabase API calls (no UI state) | `Goofny/Services/` |
| **Model** | Codable structs, enums, helpers | `Goofny/Models/` |
| **Core** | Shared Supabase client singleton | `Goofny/Core/` |
| **Config** | URLs, keys, bucket names | `Goofny/Config/` |

ViewModels are `@MainActor` `ObservableObject` types. Services are stateless `struct`s that read `SupabaseManager.shared.client`. Views observe ViewModels via `@StateObject` / `@EnvironmentObject` and never call Supabase directly.

---

## App entry and navigation

### Bootstrap (`GoofnyApp.swift`)

1. `GoofnyApp` creates a single `AuthViewModel` and injects it via `.environmentObject(auth)`.
2. `RootView` switches on `auth.state`:
   - `.loading` → spinner
   - `.signedOut` → `AuthFlowView`
   - `.signedIn` → `MainTabView`
3. `.onOpenURL` forwards OAuth callbacks (`goofny://auth-callback`) to `SupabaseManager.shared.client.auth.handle(url)`.
4. `.task { await auth.observeAuthState() }` subscribes to Supabase auth state changes for the app lifetime.

### Main tabs (`MainTabView.swift`)

| Tab | View | Purpose |
|---|---|---|
| Home | `HomeFeedView` | Discovery feed, search, filters, voting |
| Leaderboard | `LeaderboardView` | Global / country rankings |
| Add Pet | `AddPetTabView` → `PetFormView` | Create new pet; resets form and returns to Home on save |
| Profile | `ProfileView` | User stats, royal titles, my pets list |

Deep navigation uses `NavigationStack` with `Pet` as the navigation value type. Pet detail is reachable from Home, Leaderboard, and Profile.

---

## Authentication flow

```
User action (login / OAuth)
        │
        ▼
AuthViewModel ──► AuthService ──► Supabase Auth
        │
        ▼
authStateChanges stream
        │
        ├── initialSession → validate !session.isExpired
        ├── signedIn / tokenRefreshed → load profile
        └── signedOut / userDeleted → clear profile
        │
        ▼
RootView updates → MainTabView or AuthFlowView
```

**Session handling:** `SupabaseManager` opts into `emitLocalSessionAsInitialSession: true`. The locally cached session is emitted on launch even if expired; `AuthViewModel` checks `session.isExpired` and waits for `.tokenRefreshed` before treating the user as signed in.

**Profile provisioning:** On `auth.users` insert, a Postgres trigger (`handle_new_user`) creates a matching `profiles` row. The client reads/updates profiles via `AuthService`.

**OAuth:** Google and Facebook use `signInWithOAuth` with redirect `goofny://auth-callback`. Provider credentials must be configured manually in the Supabase Dashboard (see [CURRENT_STATE.md](./CURRENT_STATE.md)).

---

## Data flow by feature

### Discovery feed

```
HomeFeedView
    → FeedViewModel
        → PetService.fetchFeed()     // ranked_pets or trending_pets view
        → VoteService.votedPetIDs()  // user's existing votes
        → RealtimeService            // live votes_count updates on pets table
```

- Pagination: 20 pets per page, infinite scroll via `loadMoreIfNeeded`.
- Search: 350 ms debounce on pet name (`ilike`).
- Sort modes query different tables/orderings:
  - **Newest** → `ranked_pets`, `created_at desc`
  - **Most Voted** → `ranked_pets`, `votes_count desc`
  - **Trending** → `trending_pets`, `recent_votes desc`

### Voting

```
VoteButton tap
    → FeedViewModel.vote() / PetDetailViewModel.vote()
        → VoteService.vote(petID:)
            → RPC cast_vote(p_pet_id)
                → INSERT votes (ON CONFLICT DO NOTHING)
                → trigger sync_votes_count updates pets.votes_count
                → returns new count
```

Optimistic UI in the feed: vote state and count update immediately; rolls back on error. Duplicate votes are impossible at the DB level (`unique(voter_id, pet_id)`).

### Pet CRUD

```
PetFormView
    → PetFormViewModel
        → StorageService.uploadAvatar()   // pet-avatars/{userId}/{uuid}.jpg
        → PetService.createPet() / updatePet() / deletePet()
        → PetService health record methods (edit mode)
        → NotificationService (vaccine reminders)
```

Avatar upload path uses **lowercase** UUID strings to match RLS policies (`auth.uid()::text` is lowercase).

### Rankings and titles

Rankings are **not computed in the app**. They come from the `ranked_pets` view:

- `global_rank` — rank within species (all countries)
- `country_rank` — rank within species + country
- `title` — `King` (top male) or `Queen` (top female) per country/species/sex, only when `votes_count > 0`

`LeaderboardViewModel` reuses `PetService.fetchFeed()` with `sort: .mostVoted` and species/country filters.

### Health records (private)

Vaccinations and medical conditions are stored in dedicated tables. RLS restricts **read** access to the pet owner only. The `ranked_pets` view additionally nulls `notes` for non-owners. `PetDetailViewModel` only fetches health data when `userID == pet.ownerId`.

### Local notifications

`NotificationService` schedules iOS local notifications (not push) for vaccine renewals: 14 days before due date and on the due date at 10:00 local time. Permission is requested when the user enables a reminder in `VaccineFormView`.

---

## Service layer reference

| Service | Role |
|---|---|
| `AuthService` | Sign up/in/out, OAuth, password reset, profile CRUD |
| `PetService` | Feed queries, pet CRUD, vaccinations, medical conditions |
| `VoteService` | `cast_vote` RPC, fetch user's voted pet IDs |
| `StorageService` | Avatar upload to `pet-avatars` bucket |
| `RealtimeService` | Subscribe to `pets` UPDATE events for live vote counts |
| `NotificationService` | Local UNUserNotificationCenter scheduling |

All services access Supabase through the shared client:

```swift
// Goofny/Core/SupabaseManager.swift
final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
}
```

---

## ViewModel layer reference

| ViewModel | Backs | Key state |
|---|---|---|
| `AuthViewModel` | Global auth | `state`, `profile`, `errorMessage` |
| `FeedViewModel` | Home feed | `pets`, `filters`, `sort`, `votedPetIDs` |
| `PetDetailViewModel` | Pet detail | `pet`, health records, `hasVoted` |
| `PetFormViewModel` | Add/Edit pet | Form fields, avatar, pending health records |
| `MyPetsViewModel` | Profile | `pets`, computed stats/titles |
| `LeaderboardViewModel` | Leaderboard | `scope`, `species`, `country`, `pets` |

---

## Security model (client perspective)

The publishable (anon) Supabase key ships in `AppConfig.swift`. Security relies on:

1. **Row Level Security** on all public tables
2. **SECURITY DEFINER** RPCs with internal `auth.uid()` checks (`cast_vote`)
3. **SECURITY INVOKER** views so RLS applies to the calling user (`ranked_pets`, `trending_pets`)
4. **Storage policies** scoped to `pet-avatars/{auth.uid()}/`
5. **Revoked execute** on internal trigger functions

The client never holds service-role credentials. See [DATABASE.md](./DATABASE.md) for full policy definitions.

---

## Project generation

The Xcode project is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen):

- Target: `Goofny` (iOS 17+, iPhone only)
- Bundle ID: `com.goofny.app`
- Dependency: `supabase-swift` ≥ 2.0.0
- URL scheme: `goofny` (OAuth callbacks)
- Light mode enforced

---

## Design decisions

| Decision | Rationale |
|---|---|
| Stateless service structs | Simple, testable, no shared mutable service state |
| Views for rankings (`ranked_pets`, `trending_pets`) | Titles and ranks stay correct without client recalculation |
| `cast_vote` RPC | Atomic vote + count return; hides insert details |
| Realtime on `pets` only | Vote count changes propagate via `votes_count` column updates |
| Birth date + derived age | `birth_date` is source of truth; `age` kept for sorting/backfill |
| Pending health records on create | Pet must exist before FK-linked vaccinations/conditions |
| Species-specific vaccine catalog | Client-side `VaccineCatalog` with veterinary defaults |

---

## Related docs

- [FEATURES.md](./FEATURES.md) — user-facing capabilities
- [DATABASE.md](./DATABASE.md) — schema, RLS, migrations
- [CURRENT_STATE.md](./CURRENT_STATE.md) — maturity, gaps, manual setup
