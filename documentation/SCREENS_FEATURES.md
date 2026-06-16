# Goofny — iOS App Screens & Features

A social app where pet owners showcase their dogs and cats, vote for the cutest, and compete in daily country-based rankings. Top pets earn **King** or **Queen** titles in their country.

**Voting model:** single-pet feed with a vote button · max **10 votes per day** · votes and rankings **reset daily**.

**Main tab bar (3 tabs):** Home Feed · Rankings · My Profile

---

## Onboarding & Auth

### Splash / Launch
- Logo animation reveal
- Session check, auto-login if a valid session exists

### Welcome / Intro Carousel
- 2–3 swipeable slides explaining the concept (showcase your pet, vote daily, win King/Queen titles)
- "Get Started" and "Log in" CTAs

### Sign Up / Log In
- Sign in with Apple, Google, email/password
- Toggle between login and signup
- "Forgot password" flow

### Country & Profile Setup
- Pick country (drives rankings)
- Username, profile photo
- Accept terms & privacy

### Add Your First Pet
- Pet name, species (dog/cat), breed, birthday
- Photo upload
- "Skip for now" option

---

## Tab 1 — Home Feed (Vote + Discover)

The core screen. Browse and vote on pets, plus search and discovery built in.

### Home Feed (single-pet vote)
- One pet shown at a time — full-card photo, name, country flag, breed, owner
- Single **Vote** button per pet; tap to vote, card advances to the next pet
- **Daily vote counter** always visible (e.g. "7 / 10 votes left today")
- Optional skip / next without voting
- Filters: species (dogs / cats), scope (Global / My Country)
- Pull to refresh

### Discover (within Home Feed)
- Search pets, users, and countries
- Trending pets today, rising stars
- Browse by breed or country
- Accessible via a search bar / Discover toggle at the top of the feed

### Daily Limit Reached (blocked state)
- Appears after the 10th vote: "You're out of votes! Come back tomorrow 🐾"
- Countdown timer to next reset
- CTAs: view rankings, share the app, check your pet's rank
- (Optional, later) "Get extra votes" via premium or invite a friend

### Pet Detail
- Full photo gallery, name, breed, age
- Owner link (→ Other User Profile)
- Today's vote count, current rank, country, King/Queen badge if held
- Share, report / block

### Other User Profile
- Their pets, titles won, best ranks
- Follow / unfollow

---

## Tab 2 — Rankings  

### Rankings / Leaderboard
- Tabs: Global · My Country · By Species (dogs vs cats)
- Daily standings: rank position and vote totals
- Trend arrows vs yesterday
- "Resets in [countdown]" banner
- Tap any pet → Pet Detail

### King & Queen Showcase
- Current daily title-holders per country (top dog + top cat)
- Hall of fame / past daily winners
- Countdown to today's results lock / next reset

### My Pet's Rank
- Where your pet stands today
- Votes received, position vs yesterday
- Votes behind the pet ranked above

---

## Tab 3 — My Profile

### My Profile
- Avatar, username, country
- Stats: total votes received, pets owned, titles won, best rank
- Grid of owned pets
- Edit profile button
- Entry points to Pet Management and Settings

### Pet Management
- List of your pets — add / edit / delete
- Upload and reorder photos, edit details
- Set which pet is "active in today's competition"

### Add / Edit Pet
- Name, species, breed, birthday
- Photo upload / crop
- Delete pet (with confirmation)

### Settings
- Account, change country
- Notification preferences (esp. daily reset reminder)
- Privacy, blocked users, theme

### Subscription / Premium *(optional, if monetized)*
- Extra daily votes, boost your pet's visibility, remove ads
- Plans and purchase

### Help / About
- FAQ, contact support
- Terms, privacy policy
- App version
- Log out / delete account

---

## System / Background

### Push Notifications *(system-level, no tab)*
- "Your votes have refreshed — come vote!" (daily reset reminder)
- Title won / lost, rank changes, votes your pet received, new followers
- Managed via Settings → notification preferences

---

## Key flows

- **Daily vote loop:** Home Feed → vote up to 10× → Daily Limit Reached → (next day) → push reminder → Home Feed
- **Discovery:** Home Feed → search / trending → Pet Detail → Other User Profile
- **Compete:** Rankings → My Pet's Rank / King & Queen Showcase
- **Manage:** My Profile → Pet Management → Add / Edit Pet