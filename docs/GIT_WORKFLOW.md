# Git Workflow & Strategy — ICTU Community App

> **Recommended by:** Manus AI (Senior Software Architect) + Claude (Anthropic)  
> **Applies to:** All contributors to `ICtu-mobile-app-project/ictu-community-org`  
> **Last updated:** April 2026

---

## 1. Why This Document Exists

The repository was assessed in April 2026 and received an overall grade of **C+ (Developing)**. The primary failure areas were:

- **Branching (D)** — stale branches, mixed naming conventions, direct commits to `main`
- **Commits (C-)** — non-descriptive messages with zero traceability
- **DevOps (F)** — no CI/CD pipeline, no automated testing

This document is the single source of truth for how all future development is done. Every team member must read and follow it.

---

## 2. Branch Model — GitFlow

We use a **simplified GitFlow** with two permanent branches and short-lived feature branches.

```
main
 └── develop
      ├── feat/alerts-push-notifications
      ├── fix/timetable-monday-overflow
      ├── chore/upgrade-supabase-sdk
      └── docs/update-contributing-guide
```

### 2.1 Permanent Branches

| Branch    | Purpose                                         | Who merges here        | Direct commits? |
|-----------|-------------------------------------------------|------------------------|-----------------|
| `main`    | Production-ready, deployed code                 | Project lead only      | ❌ Never        |
| `develop` | Integration branch — staging for next release   | Via PR from feat/* branches | ❌ Never   |

**`main` is sacred.** It must always build, always be deployable. No exceptions.

### 2.2 Short-lived Branches

Branch off `develop`. Never branch off `main`.

#### Naming Convention

```
<type>/<short-kebab-description>
```

| Type         | When to use                                       | Example                                  |
|--------------|---------------------------------------------------|------------------------------------------|
| `feat/`      | New user-facing feature                           | `feat/student-grade-viewer`              |
| `fix/`       | Bug fix                                           | `fix/login-null-pointer-crash`           |
| `refactor/`  | Internal restructure, no behaviour change         | `refactor/auth-repository-split`         |
| `chore/`     | Dependencies, config, tooling, CI                 | `chore/upgrade-flutter-3-22`             |
| `docs/`      | Documentation only                                | `docs/api-endpoint-transcription`        |
| `test/`      | Adding or fixing tests only                       | `test/courses-controller-unit-tests`     |
| `hotfix/`    | Emergency fix branched off `main`                 | `hotfix/auth-token-expiry-crash`         |

#### Rules

- ✅ Use **kebab-case** only — no PascalCase, no spaces, no underscores
- ✅ Be descriptive but concise — max 5 words after the prefix
- ✅ One branch = one purpose
- ❌ Do not prefix with numbers (`Feature-1-...` is invalid)
- ❌ Do not use Copilot auto-branch names as permanent branches (`copilot/...`)
- ❌ Delete your branch immediately after it is merged

#### What We Had vs What We Do Now

| Old (Bad) ❌                              | New (Correct) ✅                          |
|------------------------------------------|------------------------------------------|
| `Feature-1-Authentication-branch`        | `feat/auth-login-signup`                 |
| `feature-8-Course-feature`               | `feat/lecturer-courses`                  |
| `feature-7-audio-rec-and-ai-transcription` | `feat/lecture-audio-transcription`     |
| `dev`                                    | `develop` (single integration branch)   |
| `copilot/sub-pr-1`                       | Merged and deleted immediately           |

---

## 3. Commit Convention — Conventional Commits

We follow the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** specification. This enables automated changelog generation and makes `git log` actually useful.

### Format

```
<type>(<scope>): <short imperative description>

[optional body — explain WHY, not what the diff shows]

[optional footer — e.g. Closes #42, BREAKING CHANGE: ...]
```

- The **header** line must be ≤ 72 characters
- Use **imperative mood** — "add", "fix", "remove" not "added", "fixed", "removed"
- The **scope** is the feature folder name from `lib/features/<scope>`

### Types

| Type        | Use case                                              | Triggers version bump |
|-------------|-------------------------------------------------------|-----------------------|
| `feat`      | New feature visible to users                          | Minor (`1.x.0`)       |
| `fix`       | Bug fix                                               | Patch (`1.0.x`)       |
| `refactor`  | Code restructure, no behaviour change                 | None                  |
| `chore`     | Tooling, dependencies, CI, config                     | None                  |
| `docs`      | Documentation changes only                            | None                  |
| `test`      | Adding or updating tests                              | None                  |
| `style`     | Formatting, whitespace — zero logic changes           | None                  |
| `perf`      | Performance improvement                               | Patch                 |
| `ci`        | GitHub Actions / CI config changes                    | None                  |

### Scopes (use the feature folder name)

`auth` · `alerts` · `community` · `courses` · `home` · `navigation` · `news` · `notifications` · `profile` · `transcription` · `core` · `supabase` · `android` · `ci` · `deps`

### Good Examples ✅

```
feat(alerts): add push notification for CA exam announcements

fix(timetable): resolve Monday schedule overflow on small screens

Closes #14

chore(deps): upgrade supabase_flutter to 2.10.2

refactor(auth): extract token refresh into AuthRepository

docs(api): document transcribe-audio edge function response schema

test(courses): add unit tests for CourseCodeValidator

ci: add Android APK build step to CI pipeline

feat(transcription): implement Gladia polling with timeout handling

BREAKING CHANGE: audioUrl now expects object path, not full URL
```

### Bad Examples ❌

```
bug fixes
timetable bug fix 2
update
WIP
new changes to polish the screens
6572902 bug fixes
```

---

## 4. Pull Request Process

### 4.1 Before Opening a PR

Run these locally and fix all issues before pushing:

```bat
dart format .
flutter analyze
flutter test
```

Zero warnings from `flutter analyze` is a hard requirement. CI will reject anything else.

### 4.2 PR Rules

1. **Title** must follow Conventional Commits format — same as your commit type
2. **Base branch** is always `develop` (never `main`, except `hotfix/` branches)
3. **Fill the PR template** completely — empty sections are not acceptable
4. **One PR = one concern** — don't bundle a feature and a refactor together
5. **Minimum 1 approval** required before merging
6. **CI must be green** — all checks (lint, test, build) must pass
7. **Squash-merge** into `develop` to keep history linear and clean
8. **Delete branch** immediately after merge — GitHub can do this automatically

### 4.3 PR Size Guidelines

| Lines changed | Status      | Notes                                    |
|---------------|-------------|------------------------------------------|
| < 200         | ✅ Ideal    | Easy to review thoroughly                |
| 200–500       | ⚠️ Acceptable | Must have clear description             |
| > 500         | ❌ Too large | Split into multiple PRs if possible     |

### 4.4 Reviewer Checklist

When reviewing a PR, check:

- [ ] Code follows feature-first folder structure
- [ ] No `print()` statements (use logger)
- [ ] No hardcoded secrets or Supabase URLs
- [ ] No unresolved TODO comments
- [ ] Loading, error, and empty states are handled
- [ ] Role-based access is enforced where needed
- [ ] `dart format` and `flutter analyze` were run
- [ ] At least one test covers the new code path

---

## 5. Release Process — `develop` → `main`

Only the project lead performs releases. This is the flow:

```
1. All features for the release are merged to develop
2. develop CI is green (all tests pass, app builds)
3. Create a PR: develop → main
   Title: chore(release): v1.2.0
4. At least 1 other member reviews
5. Merge with a merge commit (NOT squash — preserves history)
6. Tag the release:
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
7. GitHub Actions automatically builds the release APK
```

### Versioning

We follow **[Semantic Versioning](https://semver.org/)**:

```
MAJOR.MINOR.PATCH

1.0.0  → Initial release
1.1.0  → New feature added (feat:)
1.1.1  → Bug fix (fix:)
2.0.0  → Breaking change (BREAKING CHANGE: in footer)
```

Update `version` in `pubspec.yaml` before every release:

```yaml
version: 1.2.0+5   # name+buildNumber
```

---

## 6. Hotfix Process

For critical production bugs that cannot wait for the next release:

```
1. Branch off main (NOT develop):
   git checkout -b hotfix/auth-token-crash main

2. Fix the bug with a proper commit:
   fix(auth): prevent null pointer on expired token refresh

3. Open PR → main (not develop)
4. After merging to main, immediately merge main back into develop:
   git checkout develop
   git merge main
   git push origin develop

5. Tag the patch release: v1.1.1
```

---

## 7. CI/CD Pipeline — GitHub Actions

Every push to `develop` and every PR targeting `main` or `develop` triggers:

```
Push / PR
    │
    ├── [Job 1] Lint & Analyze
    │       dart format --check
    │       flutter analyze --fatal-infos
    │
    ├── [Job 2] Test  (runs after Job 1 passes)
    │       flutter test --coverage
    │       Upload coverage to Codecov
    │
    └── [Job 3] Build Android APK  (only on develop push)
            flutter build apk --debug
            Upload APK as artifact (7-day retention)
```

Config lives at: `.github/workflows/ci.yml`

**CI is not optional.** A red CI blocks the merge. Do not bypass checks.

---

## 8. Branch Protection Rules (GitHub Settings)

These must be configured at **GitHub → Settings → Branches** by the project lead:

### For `main`:
- ✅ Require a pull request before merging
- ✅ Require 1 approval
- ✅ Dismiss stale reviews when new commits are pushed
- ✅ Require status checks: `CI / Lint & Analyze`, `CI / Run Tests`
- ✅ Require branches to be up to date before merging
- ✅ Do not allow bypassing the above settings
- ✅ Restrict who can push to matching branches: project lead only

### For `develop`:
- ✅ Require a pull request before merging
- ✅ Require 1 approval
- ✅ Require status checks: `CI / Lint & Analyze`, `CI / Run Tests`
- ✅ Do not allow bypassing the above settings

---

## 9. What Not to Commit

These must never appear in the repository. They are all covered in `.gitignore`:

| Category              | Examples                                              |
|-----------------------|-------------------------------------------------------|
| Build artifacts       | `build/`, `*.apk`, `build_log*.txt`                  |
| Secrets               | `.env`, `google-services.json`, `key.properties`     |
| LaTeX build artifacts | `*.aux`, `*.fls`, `*.fdb_latexmk`, `*.synctex.gz`    |
| IDE / editor files    | `.idea/`, `.vscode/settings.json`                    |
| CLI cache             | `supabase/.temp/`                                    |
| Generated Dart files  | `*.g.dart`, `*.freezed.dart`                         |
| Loose code fragments  | Files named `AlertDialog(`, `_isWorking`, etc.       |
| Log files             | `*.log`, `analyze.log`                               |
| Node modules          | `node_modules/`                                      |

---

## 10. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│              ICTU Community — Git Quick Reference           │
├─────────────────────────────────────────────────────────────┤
│  Start work:                                                │
│    git checkout develop && git pull origin develop          │
│    git checkout -b feat/your-feature-name                   │
│                                                             │
│  Before every commit:                                       │
│    dart format .                                            │
│    flutter analyze                                          │
│                                                             │
│  Commit format:                                             │
│    feat(scope): add something new                           │
│    fix(scope): resolve something broken                     │
│    chore(deps): upgrade some-package to x.y.z              │
│                                                             │
│  Open PR:                                                   │
│    Base: develop (always)                                   │
│    Fill PR template, wait for CI green + 1 approval         │
│    Squash-merge, delete branch                              │
│                                                             │
│  Never:                                                     │
│    ❌ git push origin main                                  │
│    ❌ Commit secrets, logs, or build artifacts              │
│    ❌ Write "bug fixes" as a commit message                 │
│    ❌ Leave branches alive after merging                    │
└─────────────────────────────────────────────────────────────┘
```
