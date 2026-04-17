# Git Workflow & Strategy — ICTU Community

> This document is the single source of truth for how the team works with Git.  
> Every contributor must read this before opening their first branch.

---

## Table of Contents

1. [Branch Model](#1-branch-model)
2. [Branch Naming Rules](#2-branch-naming-rules)
3. [Commit Convention](#3-commit-convention)
4. [Pull Request Process](#4-pull-request-process)
5. [Merge Strategy](#5-merge-strategy)
6. [Release Process](#6-release-process)
7. [What To Do When Things Go Wrong](#7-what-to-do-when-things-go-wrong)
8. [Branch Protection Rules](#8-branch-protection-rules)
9. [CI/CD Pipeline](#9-cicd-pipeline)
10. [Quick Reference Card](#10-quick-reference-card)

---

## 1. Branch Model

We use a **GitFlow-inspired two-track model** suited to a small mobile team
shipping to a single production target (Android, with iOS planned).

```
main ──────────────────────────────────────────────────────► production
        ▲                                            ▲
        │  (PR, squash-merge, tagged release)        │
develop ─────────┬──────────┬───────────┬────────────┘
                 │          │           │
          feat/..│   fix/...│  chore/...│
                 ▼          ▼           ▼
             (short-lived feature branches, deleted after merge)
```

### The two permanent branches

| Branch    | Purpose | Who can push directly |
|-----------|---------|----------------------|
| `main`    | Production-ready releases only. Every commit here is a tag. | Nobody — PRs only |
| `develop` | Integration branch. All finished features land here first. | Nobody — PRs only |

### The rule in one sentence

> **Branch from `develop`. Merge back to `develop`. Never touch `main` directly.**

---

## 2. Branch Naming Rules

All branches use **kebab-case** with a mandatory type prefix.

```
<type>/<short-description>
```

### Allowed types

| Prefix      | When to use                                         | Example |
|-------------|-----------------------------------------------------|---------|
| `feat/`     | Any new user-facing feature                         | `feat/alerts-push-notifications` |
| `fix/`      | Bug fix (found in develop or reported by testers)   | `fix/timetable-monday-overflow` |
| `hotfix/`   | Critical fix that must go straight from main        | `hotfix/auth-token-null-crash` |
| `chore/`    | Deps, config, tooling, CI — no production code change | `chore/upgrade-supabase-sdk` |
| `docs/`     | Documentation only                                  | `docs/update-api-endpoints` |
| `refactor/` | Code restructure with no behaviour change           | `refactor/auth-repository-cleanup` |
| `test/`     | Adding or fixing tests only                         | `test/courses-widget-coverage` |

### Hard rules

- **kebab-case only.** No PascalCase (`Feature-1-Auth`), no spaces, no underscores.
- **Keep names short but descriptive.** Aim for 3–5 words after the prefix.
- **One purpose per branch.** Don't mix a feature and a refactor.
- **Delete your branch the moment it is merged.** Never let branches sit stale.
- **Copilot/AI auto-branches must be reviewed and renamed or deleted immediately.**  
  Names like `copilot/sub-pr-1` are not acceptable for long-lived branches.

### ✅ Good branch names
```
feat/community-feed-pagination
fix/auth-session-not-persisting
chore/update-flutter-3-29
docs/contributing-guide-update
refactor/transcription-repository-extract
hotfix/crash-on-null-user-role
```

### ❌ Bad branch names
```
Feature-1-Authentication-branch   # PascalCase + number prefix
feature-8-Course-feature          # Mixed case
bug fixes                         # Spaces, no type prefix
dev                               # Meaningless
copilot/sub-pr-1                  # Auto-generated, not descriptive
wip                               # Tells us nothing
```

---

## 3. Commit Convention

We follow **[Conventional Commits v1.0.0](https://www.conventionalcommits.org/)**.

### Format

```
<type>(<scope>): <short imperative description>

[optional body — explain WHY, not what the diff shows]

[optional footer — Closes #<issue>, BREAKING CHANGE: ...]
```

- Subject line: **max 72 characters**, no period at the end
- Use the **imperative mood**: "add", "fix", "remove" — not "added" / "fixes"
- Body: wrap at 80 characters, explain the reason not the mechanism

### Types

| Type        | When                                                   |
|-------------|--------------------------------------------------------|
| `feat`      | A new feature visible to users                         |
| `fix`       | A bug fix                                              |
| `chore`     | Build scripts, deps, tooling, CI                       |
| `docs`      | Documentation only                                     |
| `refactor`  | Code change that neither fixes a bug nor adds a feature|
| `test`      | Adding or updating tests                               |
| `style`     | Formatting, whitespace — zero logic changes            |
| `perf`      | Measurable performance improvement                     |
| `revert`    | Reverting a previous commit                            |

### Scopes (use the feature folder name)

`auth` · `alerts` · `community` · `courses` · `home` · `navigation` ·
`news` · `notifications` · `profile` · `transcription` · `core` · `ci` ·
`deps` · `supabase`

### ✅ Good commit messages
```
feat(alerts): add push notification for CA announcements

Used Supabase Realtime to subscribe to the alerts table and trigger
a local notification via the flutter_local_notifications package.

Closes #14
```
```
fix(timetable): resolve overflow on Monday schedule for small screens

The Monday column was exceeding viewport width on phones with
screen width < 380dp. Added flexible column widths with constraints.
```
```
chore(deps): upgrade supabase_flutter to 2.10.2
chore(ci): add build-android job to CI pipeline
docs(api): document transcribe-audio edge function response schema
refactor(auth): extract token refresh logic into AuthRepository
test(courses): add widget tests for CourseCard component
```

### ❌ Bad commit messages
```
bug fixes          # Zero information
timetable bug fix 2    # What bug? What fix?
update             # Update what?
WIP                # Never commit WIP to a shared branch
asdfghjkl          # This has actually happened
```

---

## 4. Pull Request Process

### Step-by-step

```
1.  Branch off develop:
      git checkout develop && git pull
      git checkout -b feat/my-feature

2.  Work in small, logical commits (follow Conventional Commits).

3.  Before pushing — always run locally:
      flutter analyze        # must be zero warnings
      dart format .          # must show no changes
      flutter test           # all tests must pass

4.  Push and open a PR against develop (NOT main):
      git push -u origin feat/my-feature

5.  Fill in the PR template completely.

6.  Request review from at least one teammate.

7.  Respond to all review comments before merging.

8.  CI must be green (Lint + Tests).

9.  Merge using Squash-merge (see section 5).

10. Delete the branch immediately after merge.
```

### PR size guidelines

| Size   | Lines changed | Guideline |
|--------|--------------|-----------|
| Small  | < 200        | Ideal — fast to review |
| Medium | 200–500      | Acceptable for full features |
| Large  | > 500        | Split into smaller PRs if possible |

If a PR is unavoidably large, add a detailed description and walkthrough
in the PR body so the reviewer knows where to focus.

### Review checklist (for reviewers)

- [ ] Does the code do what the PR title claims?
- [ ] Are there obvious bugs, edge cases, or null-safety issues?
- [ ] Is error handling user-friendly (no raw exception messages shown to users)?
- [ ] Are there `print()` statements left in production code?
- [ ] Are hardcoded strings, URLs, or keys present?
- [ ] Does the UI work on small screens (< 380dp width)?
- [ ] Are new Supabase calls protected by RLS policies?
- [ ] Are new features behind role-based access control?

---

## 5. Merge Strategy

### develop ← feature branches → **Squash Merge only**

Every feature branch is squash-merged into `develop`. This keeps the
`develop` history clean — one meaningful commit per feature, not a
sprawl of "fix typo" and "WIP" commits.

```
Before merge (feature branch):
  abc1234  WIP
  def5678  fix typo
  ghi9012  add alerts screen
  jkl3456  add alerts controller
  mno7890  add alerts data layer

After squash merge into develop:
  pqr1234  feat(alerts): add push notification for CA announcements
```

### main ← develop → **Merge Commit (release only)**

When releasing to production, `develop` is merged into `main` with a
standard merge commit (preserving the full integration history) and
**tagged with the version number**.

```bash
git checkout main
git merge --no-ff develop -m "release: v1.2.0"
git tag -a v1.2.0 -m "Release v1.2.0 — alerts + timetable fixes"
git push origin main --tags
```

### GitHub Settings to enforce this

Go to **Settings → General → Pull Requests**:
- ✅ Allow squash merging
- ❌ Disable merge commits (for feature PRs)
- ❌ Disable rebase merging
- ✅ Automatically delete head branches

---

## 6. Release Process

```
develop (stable, all tests green)
   │
   ├── Create PR: develop → main
   │     Title:  "release: v<MAJOR>.<MINOR>.<PATCH>"
   │     Body:   paste the changelog entries
   │
   ├── Get at least 1 approval
   ├── Merge with merge commit (not squash — releases keep full history)
   │
   ├── Tag the merge commit:
   │     git tag -a v1.0.0 -m "Release v1.0.0"
   │     git push origin main --tags
   │
   └── GitHub Actions automatically builds the release APK
         and uploads it as a GitHub Release artifact.
```

### Version numbering (Semantic Versioning)

```
v<MAJOR>.<MINOR>.<PATCH>

MAJOR — breaking change or complete feature milestone
MINOR — new feature, backwards compatible
PATCH — bug fix, backwards compatible
```

---

## 7. What To Do When Things Go Wrong

### "I accidentally committed to main/develop directly"

```bash
# Undo the commit but keep changes staged
git reset --soft HEAD~1

# Create a proper branch for your changes
git stash
git checkout -b fix/accidental-direct-commit
git stash pop
git add -A && git commit -m "fix(...): ..."
git push -u origin fix/accidental-direct-commit
# Then open a PR normally
```

### "I have a merge conflict"

```bash
git checkout develop
git pull origin develop
git checkout feat/my-feature
git merge develop         # bring develop into your branch
# Resolve conflicts in your editor
git add <resolved-files>
git merge --continue
git push origin feat/my-feature
```

### "I pushed a secret / API key"

1. **Immediately** rotate the exposed key in Supabase / Firebase dashboard.
2. Remove the key from history:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch path/to/file' \
     --prune-empty --tag-name-filter cat -- --all
   git push --force-with-lease origin --all
   ```
3. Notify the team immediately so they re-clone.

### "My branch is very behind develop"

```bash
git checkout feat/my-feature
git fetch origin
git rebase origin/develop
# Fix any conflicts, then:
git push --force-with-lease origin feat/my-feature
```

Use `rebase` (not `merge`) when updating a feature branch from develop,
to keep your branch's history linear.

---

## 8. Branch Protection Rules

These must be configured by a repo admin on GitHub.

### Settings → Branches → Add ruleset

**Ruleset: Protect main**
- Target branch: `main`
- Require a pull request before merging: **ON**
  - Required approvals: **1**
  - Dismiss stale reviews when new commits are pushed: **ON**
- Require status checks to pass:
  - `CI / Lint & Analyze`
  - `CI / Run Tests`
- Require branches to be up to date before merging: **ON**
- Block force pushes: **ON**
- Restrict deletions: **ON**

**Ruleset: Protect develop**
- Target branch: `develop`
- Require a pull request before merging: **ON**
  - Required approvals: **1**
- Require status checks to pass:
  - `CI / Lint & Analyze`
  - `CI / Run Tests`
- Block force pushes: **ON**

---

## 9. CI/CD Pipeline

Every push to `develop` and every PR triggers the pipeline defined in
`.github/workflows/ci.yml`.

```
PR opened / push to develop
        │
        ├─► Lint & Analyze job
        │     flutter pub get
        │     dart format --check
        │     flutter analyze --fatal-infos
        │
        └─► Test job (runs after Lint passes)
              flutter pub get
              flutter test --coverage
              Upload coverage to Codecov

Push to develop (after merge)
        │
        └─► Build Android job
              flutter build apk --debug
              Upload APK as GitHub Actions artifact (kept 7 days)

Push to main (release tag)
        │
        └─► [Planned] Firebase App Distribution deployment
```

### Running CI checks locally before pushing

```bash
# Run all three checks in sequence — fix anything that fails
dart format --output=none --set-exit-if-changed . && \
flutter analyze --fatal-infos && \
flutter test
```

Make this a habit. Every PR where CI catches something that could have
been caught locally wastes a reviewer's time.

---

## 10. Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                  ICTU Community Git Cheatsheet              │
├─────────────────────────────────────────────────────────────┤
│  Start a new task                                           │
│    git checkout develop && git pull                         │
│    git checkout -b feat/my-feature                          │
│                                                             │
│  Commit (Conventional Commits format)                       │
│    git commit -m "feat(alerts): add CA notification"        │
│    git commit -m "fix(auth): resolve null session on cold start"│
│    git commit -m "chore(deps): upgrade supabase_flutter"    │
│                                                             │
│  Before every push                                          │
│    dart format .                                            │
│    flutter analyze                                          │
│    flutter test                                             │
│                                                             │
│  Open a PR                                                  │
│    Target branch: develop (never main)                      │
│    Fill PR template · request 1 reviewer                    │
│                                                             │
│  Branch naming                                              │
│    feat/  fix/  chore/  docs/  refactor/  test/  hotfix/   │
│    kebab-case · short · descriptive                         │
│                                                             │
│  Branch lifetimes                                           │
│    Delete immediately after merge — no stale branches       │
│                                                             │
│  Never                                                      │
│    Push directly to main or develop                         │
│    Commit secrets, build logs, or binary artefacts          │
│    Leave print() statements in production code              │
│    Use "bug fixes" or "update" as a commit message          │
└─────────────────────────────────────────────────────────────┘
```

---

*Questions? Open a discussion issue tagged `docs` or message the team lead.*
