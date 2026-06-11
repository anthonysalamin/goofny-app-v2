# Goofny

## Overview

Goofny is a mobile-first iOS application that allows pet lovers to create profiles for their dogs and cats, discover pets from around the world, vote for the cutest pets, and compete for national rankings.

The platform combines social discovery, pet profiles, and gamified leaderboards where the most popular pets earn prestigious titles within their country.

---

# Objectives

Build a scalable, production-ready iOS application that:

- Allows users to register and manage pet profiles.
- Enables pet discovery through a public feed.
- Provides voting and ranking systems.
- Creates country-based competitions.
- Supports future growth and monetization.

---

# Authentication

Users must be able to create an account and sign in using:

- Email & Password
- Google Sign-In
- Facebook Login

Authentication should be managed through Supabase Auth.

---

# User Accounts

Each user can:

- Create an account
- Edit their profile
- Register multiple pets
- Manage pet information
- View their pets' rankings and statistics

---

# Pet Profiles

Each pet profile should include:

## Required Fields

- Profile Photo (Avatar)
- Name
- Species (Dog or Cat)
- Sex (Male or Female)
- Breed
- Age
- Country of Residence
- City of Residence

## Optional Fields

- Vaccination Records
- Medical Conditions
- Additional Notes

## Metadata

- Registration Date
- Total Votes
- Current Rank
- Current Title (if applicable)

---

# Pet Discovery Feed

Users can browse all registered pets.

Each card should display:

- Pet Photo
- Name
- Breed
- Country
- Vote Count
- Current Rank

---

# Search & Filtering

The discovery feed must support filtering by:

- Species (Dog / Cat)
- Country
- City
- Breed
- Sex

Additional features:

- Search by pet name
- Sort by newest
- Sort by most voted
- Sort by trending

---

# Voting System

Users can vote for pets they find cutest.

## Rules

- One vote per pet per user
- Duplicate votes are not allowed
- Vote counts update in real time
- Users cannot vote for the same pet multiple times

## Vote Tracking

Store:

- User ID
- Pet ID
- Vote Timestamp

---

# Rankings

Goofny should maintain country-based rankings.

## Dog Rankings

Top-ranked dogs in each country receive titles:

- Highest-ranked male dog → King
- Highest-ranked female dog → Queen

## Cat Rankings

Top-ranked cats in each country receive titles:

- Highest-ranked male cat → King
- Highest-ranked female cat → Queen

Titles should update automatically whenever rankings change.

---

# Leaderboards

Create dedicated leaderboard pages for:

- Global Dogs
- Global Cats
- Country Dogs
- Country Cats

Display:

- Rank
- Pet Name
- Breed
- Vote Count
- Title

---

# Technology Stack

## Frontend

- SwiftUI
- MVVM Architecture
- Async/Await Networking

## Backend

- Supabase (Singapore region)

## Database

- PostgreSQL

## Authentication

- Supabase Auth

## File Storage

- Supabase Storage

## Real-Time Features

- Supabase Realtime

---

# Database Schema

## users

| Field | Type |
|---------|---------|
| id | UUID |
| email | Text |
| created_at | Timestamp |

---

## pets

| Field | Type |
|---------|---------|
| id | UUID |
| owner_id | UUID |
| name | Text |
| species | Text |
| sex | Text |
| breed | Text |
| age | Integer |
| country | Text |
| city | Text |
| avatar_url | Text |
| created_at | Timestamp |

---

## vaccinations

| Field | Type |
|---------|---------|
| id | UUID |
| pet_id | UUID |
| vaccine_name | Text |
| vaccination_date | Date |

---

## medical_conditions

| Field | Type |
|---------|---------|
| id | UUID |
| pet_id | UUID |
| condition_name | Text |
| notes | Text |

---

## votes

| Field | Type |
|---------|---------|
| id | UUID |
| voter_id | UUID |
| pet_id | UUID |
| created_at | Timestamp |

Constraint:

- Unique(voter_id, pet_id)

---

# Security

Implement Supabase Row Level Security (RLS):

## Users

- Can edit only their own profile.

## Pets

- Owners can edit their own pets.
- Everyone can read public pet profiles.

## Votes

- Users can create votes.
- Users cannot modify existing votes.
- Duplicate voting must be prevented at database level.

---

# UI Screens

## Authentication

- Login
- Register
- Forgot Password

## Main Application

- Home Feed
- Search & Filters
- Pet Details
- Add Pet
- Edit Pet
- User Profile
- Notifications (Future)
- Leaderboards
- Settings

---

# Future Features

## Social Features

- Comments
- Likes
- Pet Following
- User Following

## Monetization

- Featured Pets
- Premium Profiles
- Sponsored Placements

## AI Features

- Breed Detection
- Health Insights
- AI-generated Pet Descriptions

## Gamification

- Daily Challenges
- Seasonal Competitions
- Achievement Badges

---

# Deliverables

The implementation should include:

1. Complete SwiftUI application
2. Supabase backend integration
3. Database schema and migrations
4. Authentication system
5. Pet management system
6. Voting and ranking engine
7. Real-time leaderboard updates
8. Responsive and polished UI
9. Error handling and loading states
10. Production-ready architecture suitable for App Store release

---

# Success Criteria

A user should be able to:

1. Register an account.
2. Add one or more pets.
3. Browse pets worldwide.
4. Vote for their favorite pets.
5. View rankings and leaderboards.
6. Earn King or Queen titles based on popularity.
7. Enjoy a fast, secure, and engaging experience.