# ================================================================
# ICTU Community — Repository Cleanup Commands
# Run these in order from the repo root on PowerShell:
#   cd S:\ictu-community-org
# ================================================================


# ----------------------------------------------------------------
# STEP 1 — Switch to develop and sync
# ----------------------------------------------------------------
git checkout develop
git pull origin develop


# ----------------------------------------------------------------
# STEP 2 — Remove tracked files that should never be committed
# ----------------------------------------------------------------

# lib/assets/ — duplicate of root assets/, pubspec.yaml uses root assets/
git rm --cached -r lib/assets/

# LaTeX build artifacts — only the .tex source and .pdf belong, not these
git rm --cached "pdfs/ICTU_Community.aux"
git rm --cached "pdfs/ICTU_Community.fdb_latexmk"
git rm --cached "pdfs/ICTU_Community.fls"
git rm --cached "pdfs/ICTU_Community.out"
git rm --cached "pdfs/ICTU_Community.synctex.gz"

# Supabase CLI cache — machine-local, never commit
git rm --cached "supabase/.temp/cli-latest"

# package.json / package-lock.json at root — belong inside supabase/
git rm --cached package.json
git rm --cached package-lock.json


# ----------------------------------------------------------------
# STEP 3 — Delete zero-byte garbage files from disk and tracking
# ----------------------------------------------------------------
git rm -f "_isWorking"
git rm -f "AlertDialog("
git rm -f "Navigator.of(context).pop(false)"
git rm -f "Navigator.of(context).pop(true)"
git rm -f "NoteDetailsScreen(note"


# ----------------------------------------------------------------
# STEP 4 — Move files to correct locations
# ----------------------------------------------------------------

# Move LaTeX source + compiled PDF into docs/srs/
New-Item -ItemType Directory -Force -Path docs\srs | Out-Null
Move-Item pdfs\ICTU_Community.tex docs\srs\ICTU_Community.tex
Move-Item pdfs\ICTU_Community.pdf docs\srs\ICTU_Community.pdf

# Move package.json files into supabase/
Move-Item package.json supabase\package.json
Move-Item package-lock.json supabase\package-lock.json

# Move docs flat files into docs/guides/ (keeps docs/ clean)
New-Item -ItemType Directory -Force -Path docs\guides | Out-Null
Move-Item docs\API_ENDPOINTS.md      docs\guides\API_ENDPOINTS.md
Move-Item docs\FEATURE_WORKFLOW.md   docs\guides\FEATURE_WORKFLOW.md
Move-Item docs\OFFLINE_IMPLEMENTATION.md docs\guides\OFFLINE_IMPLEMENTATION.md
Move-Item docs\UI_WORKFLOW.md        docs\guides\UI_WORKFLOW.md


# ----------------------------------------------------------------
# STEP 5 — Delete lib/assets/ from disk (already untracked above)
# ----------------------------------------------------------------
Remove-Item lib\assets -Recurse -Force


# ----------------------------------------------------------------
# STEP 6 — Create missing Clean Architecture layer folders
#           (.gitkeep makes git track empty directories)
# ----------------------------------------------------------------

# alerts — missing: controllers, widgets
New-Item -Force -Path lib\features\alerts\controllers\.gitkeep    | Out-Null
New-Item -Force -Path lib\features\alerts\widgets\.gitkeep        | Out-Null

# auth — missing: data, widgets
New-Item -Force -Path lib\features\auth\data\.gitkeep             | Out-Null
New-Item -Force -Path lib\features\auth\widgets\.gitkeep          | Out-Null

# community — missing: data, widgets, models, controllers
New-Item -Force -Path lib\features\community\data\.gitkeep        | Out-Null
New-Item -Force -Path lib\features\community\widgets\.gitkeep     | Out-Null
New-Item -Force -Path lib\features\community\models\.gitkeep      | Out-Null
New-Item -Force -Path lib\features\community\controllers\.gitkeep | Out-Null

# courses — missing: widgets
New-Item -Force -Path lib\features\courses\widgets\.gitkeep       | Out-Null

# home — missing: data, widgets, models, controllers
New-Item -Force -Path lib\features\home\data\.gitkeep             | Out-Null
New-Item -Force -Path lib\features\home\widgets\.gitkeep          | Out-Null
New-Item -Force -Path lib\features\home\models\.gitkeep           | Out-Null
New-Item -Force -Path lib\features\home\controllers\.gitkeep      | Out-Null

# navigation — missing: data, widgets, models
New-Item -Force -Path lib\features\navigation\data\.gitkeep       | Out-Null
New-Item -Force -Path lib\features\navigation\widgets\.gitkeep    | Out-Null
New-Item -Force -Path lib\features\navigation\models\.gitkeep     | Out-Null

# news — missing: data, widgets, models, controllers
New-Item -Force -Path lib\features\news\data\.gitkeep             | Out-Null
New-Item -Force -Path lib\features\news\widgets\.gitkeep          | Out-Null
New-Item -Force -Path lib\features\news\models\.gitkeep           | Out-Null
New-Item -Force -Path lib\features\news\controllers\.gitkeep      | Out-Null

# notifications — missing: data, widgets, models, controllers
New-Item -Force -Path lib\features\notifications\data\.gitkeep        | Out-Null
New-Item -Force -Path lib\features\notifications\widgets\.gitkeep     | Out-Null
New-Item -Force -Path lib\features\notifications\models\.gitkeep      | Out-Null
New-Item -Force -Path lib\features\notifications\controllers\.gitkeep | Out-Null

# profile — missing: data, widgets, models
New-Item -Force -Path lib\features\profile\data\.gitkeep          | Out-Null
New-Item -Force -Path lib\features\profile\widgets\.gitkeep       | Out-Null
New-Item -Force -Path lib\features\profile\models\.gitkeep        | Out-Null

# transcription — missing: widgets, models
New-Item -Force -Path lib\features\transcription\widgets\.gitkeep | Out-Null
New-Item -Force -Path lib\features\transcription\models\.gitkeep  | Out-Null


# ----------------------------------------------------------------
# STEP 7 — Append missing rules to .gitignore
# ----------------------------------------------------------------
@"

# LaTeX build artifacts (pdfs/*.tex and *.pdf are fine, these are not)
*.aux
*.fls
*.fdb_latexmk
*.synctex.gz
pdfs/*.out

# Supabase CLI cache (machine-local)
supabase/.temp/

# Build logs (never commit)
build_log*.txt
build_log*.log

# Duplicate assets folder guard
lib/assets/

# Dart generated files (hive, freezed, build_runner)
**/*.g.dart
**/*.freezed.dart
"@ | Add-Content .gitignore


# ----------------------------------------------------------------
# STEP 8 — Stage everything
# ----------------------------------------------------------------
git add -A


# ----------------------------------------------------------------
# STEP 9 — Commit with a proper conventional commit message
# ----------------------------------------------------------------
git commit -m "chore(repo): restructure folders, remove artifacts, scaffold feature layers

- Remove lib/assets/ duplicate (root assets/ is canonical per pubspec.yaml)
- Remove LaTeX build artifacts from tracking (pdfs/*.aux, *.fls, *.fdb_latexmk, *.out, *.synctex.gz)
- Remove supabase/.temp CLI cache from tracking
- Remove zero-byte garbage root files (_isWorking, AlertDialog( etc.)
- Move pdfs/SRS source and PDF to docs/srs/
- Move package.json and package-lock.json to supabase/
- Move docs flat files into docs/guides/ subdirectory
- Add missing Clean Architecture layer folders (.gitkeep) for all 10 features
- Add docs/GIT_WORKFLOW.md - branching, commit and release strategy
- Update .gitignore with LaTeX, CLI cache, build-log and generated file rules"


# ----------------------------------------------------------------
# STEP 10 — Push the clean commit to develop
# ----------------------------------------------------------------
git push origin develop


# ----------------------------------------------------------------
# STEP 11 — Delete all stale remote branches
# ----------------------------------------------------------------

# Fully merged — auth is live in main (merged via PR #7)
git push origin --delete Feature-1-Authentication-branch

# Fully merged — transcription is live in main (merged via PR #6)
git push origin --delete feature-7-audio-rec-and-ai-transcription

# Fully merged — courses are live in main (merged via PR #8)
git push origin --delete feature-8-Course-feature

# Stale duplicate of develop
git push origin --delete dev

# Copilot auto-branch — superseded entirely by auth_controller.dart on main
git push origin --delete copilot/sub-pr-1

# Copilot auto-branch — contains only build_log.txt pollution + old code
git push origin --delete copilot/feature-8-ui-design-summary


# ----------------------------------------------------------------
# STEP 12 — Verify final branch state
# ----------------------------------------------------------------
git fetch --prune
git branch -a


# ================================================================
# DONE — Only these branches should remain:
#   remotes/origin/main
#   remotes/origin/develop
#
# MANUAL STEPS LEFT (in GitHub Settings):
#
#   Settings → Branches → Add rule for "main":
#     ✅ Require pull request before merging (1 approval)
#     ✅ Require status checks: "CI / Lint & Analyze", "CI / Run Tests"
#     ✅ Require branches to be up to date before merging
#     ✅ Do not allow bypassing the above settings
#     ✅ Restrict push to project lead only
#
#   Repeat the same rule for "develop".
#
#   Settings → General → Pull Requests:
#     ✅ Automatically delete head branches
#     ✅ Default merge: Squash and merge
#
# ================================================================
