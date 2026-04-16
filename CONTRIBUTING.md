# Contributing to ICTU Community

Welcome! This document explains how to contribute to the ICTU Community mobile app. Please read it before opening a branch, writing a commit, or submitting a pull request.

---

## Table of Contents
1. [Branching Strategy](#branching-strategy)
2. [Commit Convention](#commit-convention)
3. [Pull Request Process](#pull-request-process)
4. [Code Style](#code-style)
5. [Running the Project Locally](#running-the-project-locally)

---

## Branching Strategy

We follow a **GitFlow-inspired** model with two long-lived branches:

| Branch    | Purpose                                              |
|-----------|------------------------------------------------------|
| `main`    | Production-ready code only. Never commit here directly. |
| `develop` | Integration branch. All features merge here first.  |

### Short-lived branch naming

Always branch off `develop`. Use the following prefixes:

| Prefix     | When to use                          | Example                              |
|------------|--------------------------------------|--------------------------------------|
| `feat/`    | New feature                          | `feat/alerts-push-notifications`     |
| `fix/`     | Bug fix                              | `fix/timetable-monday-overflow`      |
| `chore/`   | Tooling, deps, config, CI changes    | `chore/update-supabase-sdk`          |
| `docs/`    | Documentation only                   | `docs/update-api-endpoints`          |
| `refactor/`| Code restructure, no behaviour change| `refactor/auth-repository-cleanup`   |
| `test/`    | Adding or fixing tests               | `test/courses-widget-tests`          |

**Rules:**
- Use **kebab-case** only — no PascalCase, no spaces.
- Keep names short but descriptive.
- Delete your branch after it is merged.

---

## Commit Convention

We use **[Conventional Commits](https://www.conventionalcommits.org/)**.

### Format
```
type(scope): short imperative description

[optional body — explain WHY, not what]

[optional footer — e.g. Closes #42]
```

### Types

| Type       | When to use                                      |
|------------|--------------------------------------------------|
| `feat`     | A new feature visible to users                   |
| `fix`      | A bug fix                                        |
| `chore`    | Maintenance — deps, config, tooling              |
| `docs`     | Documentation changes only                       |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test`     | Adding or updating tests                         |
| `style`    | Formatting, whitespace (no logic changes)        |
| `perf`     | Performance improvement                          |

### Scope (optional but encouraged)

Use the feature folder name: `auth`, `timetable`, `alerts`, `community`, `courses`, `profile`, `transcription`, `notifications`, `news`.

### Good examples
```
feat(alerts): add push notification for CA announcements
fix(timetable): resolve Monday schedule overflow on small screens
chore(deps): upgrade supabase_flutter to 2.10.2
docs(api): document transcribe-audio edge function response
refactor(auth): extract token refresh logic into AuthRepository
test(courses): add widget tests for CourseCard component
```

### Bad examples ❌
```
bug fixes
timetable bug fix 2
update
WIP
```

---

## Pull Request Process

1. **Always branch off `develop`**, never off `main`.
2. Keep PRs focused — one feature or fix per PR.
3. Fill in the PR template completely before requesting review.
4. Ensure the CI pipeline is green (lint + tests must pass).
5. At least **one approval** is required before merging.
6. **Squash-merge** into `develop` to keep history clean.
7. Delete your branch after merge.

### Merging to `main`
Only the project lead merges `develop` → `main`, and only for a production release. This is tagged with a version (e.g. `v1.0.0`).

---

## Code Style

- Run `dart format .` before every commit.
- Run `flutter analyze` and fix all warnings before pushing.
- No `print()` statements in production code — use a logger.
- No hardcoded secrets, URLs, or API keys in Dart files. Use environment variables or Supabase secrets.
- Follow the **feature-first** folder structure in `lib/features/<feature>/`:
  - `screens/` — pages/routes
  - `widgets/` — reusable UI components
  - `controllers/` — state management (`ValueNotifier` / BLoC)
  - `data/` — repositories, API wrappers

---

## Running the Project Locally

```bash
# 1. Clone the repo
git clone https://github.com/ICtu-mobile-app-project/ictu-community-org.git
cd ictu-community-org

# 2. Install Flutter dependencies
flutter pub get

# 3. Set up Supabase credentials
#    Copy your .env or configure lib/core/supabase/supabase_instance.dart
#    (Never commit real credentials)

# 4. Run the app
flutter run

# Useful commands
flutter analyze          # Static analysis
dart format .            # Auto-format code
flutter test             # Run all tests
flutter clean            # Clear build cache
```

For Edge Function deployment see `supabase/README_AUTH_FUNCTIONS.md`.
