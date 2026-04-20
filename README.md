# ICTU Community

> A cross-platform mobile app connecting students, lecturers, staff, and administrators at ICT University Yaoundé, Cameroon.

**Stack:** Flutter · Dart · Supabase · Gladia AI  
**Status:** 🟡 In active development  
**Platform:** Android (iOS planned)

---

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Environment Setup](#environment-setup)
- [Running & Building](#running--building)
- [Contributing](#contributing)
- [Team](#team)

---

## Overview

ICTU Community is a university mobile platform providing:

- 📢 **Alerts & Announcements** — CA dates, exam schedules, resits
- 📅 **Timetable** — Live lecture schedule per programme and year
- 📚 **Courses** — Materials, resources, and assignment management
- 🎙️ **Lecture Transcription** — AI-powered audio-to-text via Gladia
- 🗞️ **News & Community Feed** — Campus news and community posts
- 👤 **Role-based Access** — Student, Lecturer, Staff, Admin views

---

## Architecture

The app follows **Feature-First Clean Architecture**:

```
lib/
├── main.dart                  # App entry point (Supabase init)
├── app.dart                   # Root widget, routing
├── core/
│   ├── supabase/              # Supabase client singleton
│   └── theme/                 # App theme & typography
└── features/
    ├── auth/                  # Login, registration, session
    ├── alerts/                # Push alerts & announcements
    ├── community/             # Community feed
    ├── courses/               # Course listings & materials
    ├── home/                  # Dashboard per role
    ├── navigation/            # Bottom nav shell
    ├── news/                  # Campus news
    ├── notifications/         # Notification centre
    ├── profile/               # User profile management
    └── transcription/         # Lecture audio transcription
```

Each feature follows the layer pattern:

```
features/<feature>/
  screens/      # UI pages (routes)
  widgets/      # Reusable components
  controllers/  # State (ValueNotifier / BLoC)
  data/         # Repositories, API calls
```

**Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions)  
**AI:** Gladia API for lecture transcription  
**CI/CD:** GitHub Actions (lint → test → build on every PR to dev)

---

## Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.x (stable channel) |
| Dart | ≥ 3.11.0 |
| Android Studio / VS Code | Latest |
| Supabase CLI | Latest (for Edge Functions) |

### Clone the repo

```bash
git clone https://github.com/ICtu-mobile-app-project/ictu-community-org.git
cd ictu-community-org
```

---

## Environment Setup

This project uses Supabase. You need to configure your credentials before running.

1. Create a `.env` file at the root (it is gitignored):
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. Never commit real keys. Edge Function secrets (`SUPABASE_SERVICE_ROLE_KEY`, `GLADIA_API_KEY`) live only on the Supabase dashboard — see `supabase/README_AUTH_FUNCTIONS.md`.

---

## Running & Building

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Analyze code (must be zero warnings before committing)
flutter analyze

# Format code (run before every commit)
dart format .

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Clear build cache
flutter clean && flutter pub get
```

### Deploy Edge Functions

```bash
supabase functions deploy register
supabase functions deploy login
supabase functions deploy transcribe-audio
```

---

## Contributing

Please read **[CONTRIBUTING.md](./CONTRIBUTING.md)** before opening a branch or PR. Key rules:

- Branch off `dev` using `feat/`, `fix/`, `chore/`, `docs/` prefixes
- Write commits in [Conventional Commits](https://www.conventionalcommits.org/) format
- CI (lint + tests) must be green before requesting review
- At least one approval required to merge

---

## Team

Built by the ICT University Yaoundé student development team.  
For questions, open an issue or reach out via the community channel.
