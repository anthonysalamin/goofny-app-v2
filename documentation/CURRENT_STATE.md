# Goofny V2 — Current State

Snapshot of project maturity, what works today, what still needs manual setup, and known limitations. Last aligned with the codebase and migrations as of June 2026.

---

## Summary

Goofny V2 is a **functional MVP** — a complete SwiftUI iOS app wired to a **live, migrated Supabase backend**. Core loops work end-to-end: register → add pets → browse feed → vote → see rankings and titles.

| Area | Status |
|---|---|
| iOS app code | ✅ Complete for MVP scope |
| Supabase schema | ✅ Migrated (8 migration files) |
| Email/password auth | ✅ Works out of the box |
| OAuth (Google / Facebook) | ⚠️ Code ready; dashboard config required |
| App Store readiness | ⚠️ Not yet — no TestFlight/App Store metadata in repo |
| Physical device testing | ✅ Supported (code signing configured in `project.yml`) |

---

## Repository layout

```
goofny-app-v2/
├── Goofny/                    # SwiftUI app source (34 Swift files)
│   ├── GoofnyApp.swift
│   ├── Config/
│   ├── Core/
│   ├── Models/
│   ├── Services/              # 6 services
│   ├── ViewModels/            # 6 view models
│   └── Views/                 # Auth, Feed, PetDetail, Pets, Leaderboard, Profile, Components
├── supabase/migrations/       # 8 SQL migrations (applied to live project)
├── documentation/             # Architecture, features, database, this file
├── project.yml                # XcodeGen definition
├── README.md
└── steps.md                   # iPhone developer mode notes
```

**Generated (not in git):** `Goofny.xcodeproj` — run `xcodegen generate` to create.

**Untracked assets:** `Goofny/Assets.xcassets/` contains `AppIcon.appiconset` (app icon configured in `project.yml`).

---

## What works today

### End-to-end user flows

1. **Sign up / sign in** with email and password
2. **Create a pet** with photo, breed, birth date, location, optional health records
3. **Browse the feed** with search, filters, and three sort modes
4. **Vote once per pet** with optimistic UI and live count updates
5. **View pet details** including ranks and titles
6. **Edit or delete** owned pets
7. **Manage vaccinations** with catalog defaults and local renewal reminders
8. **View leaderboards** — global or by country, dogs or cats
9. **See profile stats** — pet count, total votes, best rank, royal titles
10. **Update display name** and sign out from Settings

### Backend (live)

| Component | Project | Region |
|---|---|---|
| Supabase | GOOFNY V2 | `ap-southeast-1` (Singapore) |
| Project ref | `mfvrhacaqtizpdkqxpfm` | |
| URL | `https://mfvrhacaqtizpdkqxpfm.supabase.co` | |

All migrations applied. RLS active. Realtime enabled on `pets` and `votes`. Storage bucket `pet-avatars` provisioned.

### Client configuration

| Setting | Value |
|---|---|
| iOS deployment target | 17.0 |
| Bundle ID | `com.goofny.app` |
| URL scheme | `goofny` |
| Supabase SDK | `supabase-swift` ≥ 2.0.0 |
| UI style | Light mode only |
| Device family | iPhone only |

---

## Manual setup still required

### Supabase Dashboard → Authentication

| Task | Status | Impact if skipped |
|---|---|---|
| Enable **Google** provider + OAuth credentials | ❌ Manual | Google sign-in button fails |
| Enable **Facebook** provider + app credentials | ❌ Manual | Facebook sign-in button fails |
| Add redirect URL `goofny://auth-callback` | ❌ Manual | OAuth callbacks fail |

Email/password and password reset work without these steps.

### Local development

| Task | Command / action |
|---|---|
| Install XcodeGen | `brew install xcodegen` |
| Generate Xcode project | `xcodegen generate` (from repo root) |
| Open project | `Goofny.xcodeproj` |
| Run on device | Enable Developer Mode on iPhone (see `steps.md`) |

### App Store (not started)

- No `Fastlane`, CI, or App Store Connect configuration in repo
- Terms/Privacy links point to `goofny.com` (must exist before submission)
- No App Store screenshots, metadata, or review notes

---

## Known limitations

### Product / feature gaps

| Limitation | Detail |
|---|---|
| No remote push notifications | Only local vaccine reminders via `UNUserNotificationCenter` |
| No social features | No comments, follows, or separate likes |
| No monetization | No featured pets or premium tiers |
| Leaderboard not realtime | Refreshes on pull-to-refresh or filter change only |
| Camera not in UI | `NSCameraUsageDescription` is set but avatar picker uses PhotosPicker only |
| Users cannot vote for own pets from detail | Vote button hidden for owner (`!isOwner` check) — feed still shows vote button |
| No admin panel | All management via Supabase Dashboard or SQL |
| No offline mode | Requires network for all data operations |
| No unit / UI tests | Test target not configured in `project.yml` |

### Technical notes

| Topic | Detail |
|---|---|
| Anon key in source | Publishable key in `AppConfig.swift` is intentional; RLS protects data |
| `age` vs `birth_date` | Both stored; birth date is preferred for display; age computed on save |
| Vote on own pet (feed) | Feed does not block voting for own pets — only pet detail hides the button |
| Avatar bucket is public | Objects accessible by URL; upload/delete restricted by RLS |
| Health records on create | Pending vaccinations/conditions saved after pet insert (FK requirement) |
| Notification permission | Requested when user enables a vaccine reminder, not on first launch |

---

## Screen inventory

| Screen | File | Wired to backend |
|---|---|---|
| Login | `AuthFlowView.swift` | ✅ |
| Register | `AuthFlowView.swift` | ✅ |
| Forgot password | `AuthFlowView.swift` | ✅ |
| Home feed | `HomeFeedView.swift` | ✅ |
| Filter sheet | `FilterSheetView.swift` | ✅ (client-side filters → query) |
| Pet detail | `PetDetailView.swift` | ✅ |
| Add / Edit pet | `PetFormView.swift` | ✅ |
| Vaccine form | `VaccineFormView.swift` | ✅ |
| Breed picker | `BreedPickerView.swift` | N/A (local catalog) |
| Leaderboard | `LeaderboardView.swift` | ✅ |
| Profile | `ProfileView.swift` | ✅ |
| Settings | `SettingsView.swift` | ✅ |

---

## Dependency graph (runtime)

```
GoofnyApp
 └── AuthViewModel ── AuthService
      └── RootView
           ├── AuthFlowView
           └── MainTabView
                ├── HomeFeedView ── FeedViewModel ── PetService, VoteService, RealtimeService
                ├── LeaderboardView ── LeaderboardViewModel ── PetService
                ├── AddPetTabView ── PetFormView ── PetFormViewModel ── PetService, StorageService, NotificationService
                └── ProfileView ── MyPetsViewModel ── PetService
```

All services → `SupabaseManager.shared.client` → Supabase cloud.

---

## Migration history (applied)

| # | Migration | Status |
|---|---|---|
| 1 | `initial_schema` | ✅ Applied |
| 2 | `rankings_and_titles` | ✅ Applied |
| 3 | `rls_policies_and_storage` | ✅ Applied |
| 4 | `security_hardening` | ✅ Applied |
| 5 | `storage_policy_case_insensitive` | ✅ Applied |
| 6 | `add_birth_date` | ✅ Applied |
| 7 | `private_health_records` | ✅ Applied |
| 8 | `vaccine_module_v2` | ✅ Applied |

No pending migrations in the repo.

---

## Suggested next steps

Priority-ordered based on current gaps:

1. **Configure OAuth providers** in Supabase Dashboard (Google, Facebook) and verify `goofny://auth-callback`
2. **Test on physical device** with real accounts and multiple users voting
3. **Block self-voting in feed** if product rule should match pet detail behavior
4. **Add TestFlight pipeline** — CI build, signing, upload
5. **Leaderboard realtime** — subscribe to `pets` updates in `LeaderboardViewModel` (pattern exists in feed)
6. **Push notifications** — for vote milestones, title changes, or vaccine reminders when app is closed

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — technical design
- [FEATURES.md](./FEATURES.md) — complete feature list with status
- [DATABASE.md](./DATABASE.md) — schema and security reference
- [README.md](../README.md) — getting started guide
- [prompt.md](./prompt.md) — original product specification
