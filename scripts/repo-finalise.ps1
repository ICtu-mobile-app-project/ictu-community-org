# =============================================================================
# repo-finalise.ps1
#
# Master cleanup script for ictu-community-org.
# Run ONCE from the repo root on a machine with push access:
#
#   cd S:\ictu-community-org
#   .\scripts\repo-finalise.ps1
#
# What this script does (in order):
#   1.  Creates missing Clean Architecture layer folders for every feature
#   2.  Removes duplicate lib/assets/ images from Git tracking
#   3.  Removes LaTeX build artifacts in pdfs/ from Git tracking
#   4.  Removes supabase/.temp/ from Git tracking
#   5.  Removes old root-level 0-byte garbage files from Git tracking
#   6.  Stages the package.json / package-lock.json move (root -> supabase/)
#   7.  Stages the docs/ flat-file moves (-> docs/guides/)
#   8.  Updates .gitignore with all new exclusion rules
#   9.  Commits all staged changes with a clean conventional commit
#   10. Deletes 6 stale remote branches
#   11. Verifies final branch state
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = $PSScriptRoot | Split-Path -Parent   # S:\ictu-community-org

function Step($n, $msg) {
    Write-Host "`n[$n] $msg" -ForegroundColor Cyan
}
function Ok($msg)   { Write-Host "    OK  $msg" -ForegroundColor Green }
function Skip($msg) { Write-Host "    --  $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "    !!  $msg" -ForegroundColor Yellow }

Set-Location $repo
Write-Host "`n==========================================================" -ForegroundColor Magenta
Write-Host "  ICTU Community — Repository Finalise Script" -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

# ── 0. Sanity check ──────────────────────────────────────────────────────────
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Run this from the repo root (S:\ictu-community-org)" -ForegroundColor Red
    exit 1
}

# ── 1. Create missing Clean Architecture layer folders ───────────────────────
Step 1 "Creating missing feature layer folders"

$layers = @("screens", "widgets", "controllers", "models", "data")
$features = @(
    "alerts", "auth", "community", "courses",
    "home", "navigation", "news", "notifications",
    "profile", "transcription"
)

foreach ($feature in $features) {
    foreach ($layer in $layers) {
        $path = "lib\features\$feature\$layer"
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            # Git won't track empty dirs — add a .gitkeep
            $keepFile = "$path\.gitkeep"
            Set-Content $keepFile "# placeholder — replace with real files as the feature grows"
            Ok "Created $path"
        }
    }
}

# Also ensure core has standard subdirs
$coreDirs = @("lib\core\constants", "lib\core\services", "lib\core\supabase",
              "lib\core\theme", "lib\core\validation", "lib\core\utils")
foreach ($dir in $coreDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Set-Content "$dir\.gitkeep" "# placeholder"
        Ok "Created $dir"
    }
}

# ── 2. Remove duplicate lib/assets/ from Git tracking ────────────────────────
Step 2 "Removing duplicate lib/assets/ from Git (images live in root assets/)"

$libAssets = @(
    "lib/assets/Logo.png",
    "lib/assets/madam.jpg",
    "lib/assets/school.jpeg",
    "lib/assets/students.jpg"
)
foreach ($file in $libAssets) {
    $tracked = git ls-files $file 2>$null
    if ($tracked) {
        git rm --cached $file 2>$null
        # Delete the physical duplicate too — the real copy is in assets/
        if (Test-Path $file) { Remove-Item $file -Force }
        Ok "Untracked + deleted duplicate: $file"
    } else {
        Skip "$file already untracked"
    }
}
# Remove the now-empty lib/assets directory from Git
$libAssetsDir = "lib\assets"
if (Test-Path $libAssetsDir) {
    $remaining = Get-ChildItem $libAssetsDir -Recurse -File
    if (-not $remaining) {
        Remove-Item $libAssetsDir -Recurse -Force
        Ok "Deleted empty directory: lib/assets/"
    }
}

# ── 3. Remove LaTeX build artifacts in pdfs/ from Git tracking ───────────────
Step 3 "Removing LaTeX build artifacts from Git (pdfs/*.aux, *.fls, etc.)"

$latexArtifacts = @(
    "pdfs/ICTU_Community.aux",
    "pdfs/ICTU_Community.fdb_latexmk",
    "pdfs/ICTU_Community.fls",
    "pdfs/ICTU_Community.out",
    "pdfs/ICTU_Community.synctex.gz"
)
foreach ($file in $latexArtifacts) {
    $tracked = git ls-files $file 2>$null
    if ($tracked) {
        git rm --cached $file 2>$null
        if (Test-Path $file) { Remove-Item $file -Force }
        Ok "Untracked + deleted: $file"
    } else {
        Skip "$file already untracked"
    }
}

# The .tex and .pdf were already moved to docs/srs/ — untrack old pdfs/ location
$pdfTracked = git ls-files "pdfs/ICTU_Community.pdf" 2>$null
if ($pdfTracked) {
    git rm --cached "pdfs/ICTU_Community.pdf" 2>$null
    Ok "Untracked old pdfs/ICTU_Community.pdf (now in docs/srs/)"
}
$texTracked = git ls-files "pdfs/ICTU_Community.tex" 2>$null
if ($texTracked) {
    git rm --cached "pdfs/ICTU_Community.tex" 2>$null
    Ok "Untracked old pdfs/ICTU_Community.tex (now in docs/srs/)"
}

# Stage the docs/srs/ moves so Git sees them as renames
git add "docs/srs/ICTU_Community.pdf" 2>$null
git add "docs/srs/ICTU_Community.tex" 2>$null

# Remove the now-empty pdfs/ directory
if (Test-Path "pdfs") {
    $remaining = Get-ChildItem "pdfs" -Recurse -File
    if (-not $remaining) {
        Remove-Item "pdfs" -Recurse -Force
        Ok "Deleted empty pdfs/ directory"
    }
}

# ── 4. Remove supabase/.temp/ from Git tracking ──────────────────────────────
Step 4 "Removing supabase/.temp/ from Git tracking"

$tempFile = "supabase/.temp/cli-latest"
$tracked = git ls-files $tempFile 2>$null
if ($tracked) {
    git rm --cached -r "supabase/.temp/" 2>$null
    Ok "Untracked supabase/.temp/"
} else {
    Skip "supabase/.temp/ already untracked"
}

# ── 5. Remove remaining 0-byte garbage files from Git + disk ─────────────────
Step 5 "Removing 0-byte garbage files from root"

$garbageFiles = @(
    "_isWorking",
    "AlertDialog(",
    "Navigator.of(context).pop(false)",
    "Navigator.of(context).pop(true)",
    "NoteDetailsScreen(note"
)
foreach ($file in $garbageFiles) {
    $tracked = git ls-files $file 2>$null
    if ($tracked) {
        # git rm can struggle with special chars — use cached then delete
        git rm --cached "$file" 2>$null
    }
    if (Test-Path $file) {
        Remove-Item $file -Force
        Ok "Deleted: $file"
    } else {
        Skip "Already gone: $file"
    }
}

# ── 6. Stage the package.json / package-lock.json move ───────────────────────
Step 6 "Staging package.json move (root -> supabase/)"

# Untrack old locations
foreach ($f in @("package.json", "package-lock.json")) {
    $tracked = git ls-files $f 2>$null
    if ($tracked) {
        git rm --cached $f 2>$null
        Ok "Untracked root $f"
    } else {
        Skip "root $f already untracked"
    }
}
# Stage new locations
git add "supabase/package.json" 2>$null
git add "supabase/package-lock.json" 2>$null
Ok "Staged supabase/package.json + supabase/package-lock.json"

# ── 7. Stage docs/ flat-file moves ───────────────────────────────────────────
Step 7 "Staging docs/guides/ moves"

foreach ($f in @("docs/guides/API_ENDPOINTS.md", "docs/guides/FEATURE_WORKFLOW.md",
                  "docs/guides/OFFLINE_IMPLEMENTATION.md", "docs/guides/UI_WORKFLOW.md")) {
    if (Test-Path $f) {
        git add $f 2>$null
        Ok "Staged $f"
    } else {
        Warn "$f not found — was it moved already?"
    }
}

# ── 8. Update .gitignore ──────────────────────────────────────────────────────
Step 8 "Updating .gitignore"

$newRules = @"

# --- Added by repo-finalise.ps1 ---

# LaTeX build artefacts
pdfs/*.aux
pdfs/*.fdb_latexmk
pdfs/*.fls
pdfs/*.out
pdfs/*.synctex.gz

# Supabase CLI cache
supabase/.temp/

# Dart / Flutter generated
*.g.dart
*.freezed.dart
.dart_tool/

# Build logs (never commit these)
build_log*.txt
build_log*.log

# Node (Supabase JS tooling only)
supabase/node_modules/

# Duplicate assets guard
lib/assets/

# OS
.DS_Store
Thumbs.db
"@

$gitignorePath = ".gitignore"
$current = Get-Content $gitignorePath -Raw
if ($current -notmatch "repo-finalise") {
    Add-Content $gitignorePath $newRules
    Ok ".gitignore updated"
} else {
    Skip ".gitignore already patched"
}
git add .gitignore

# ── 9. Stage all new files and commit ────────────────────────────────────────
Step 9 "Staging all changes and committing"

git add -A

$status = git status --short
if ($status) {
    Write-Host "`n    Staged changes:" -ForegroundColor DarkGray
    $status | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

    git commit -m "chore(repo): finalise structure and clean tracked artefacts

- Remove duplicate lib/assets/ (images already in root assets/)
- Remove LaTeX build artefacts from pdfs/ tracking
- Move pdfs/ICTU_Community.{tex,pdf} -> docs/srs/
- Remove supabase/.temp/cli-latest from tracking
- Remove 0-byte root garbage files (_isWorking, AlertDialog( etc.)
- Move package.json + package-lock.json -> supabase/
- Move docs flat-files -> docs/guides/
- Create missing Clean Architecture layer folders for all features
- Update .gitignore with LaTeX, Supabase temp, build log patterns"

    Ok "Committed successfully"
} else {
    Skip "Nothing to commit — working tree already clean"
}

# ── 10. Delete stale remote branches ─────────────────────────────────────────
Step 10 "Deleting stale remote branches"

$toDelete = @(
    "Feature-1-Authentication-branch",
    "feature-7-audio-rec-and-ai-transcription",
    "feature-8-Course-feature",
    "dev",
    "copilot/sub-pr-1",
    "copilot/feature-8-ui-design-summary"
)

foreach ($branch in $toDelete) {
    $exists = git ls-remote --heads origin $branch 2>$null
    if ($exists) {
        git push origin --delete $branch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Ok "Deleted remote: $branch"
        } else {
            Warn "Could not delete remote: $branch (may need admin rights on GitHub)"
        }
        # Also delete local if present
        $local = git branch --list $branch
        if ($local) {
            git branch -D $branch 2>$null
            Ok "Deleted local: $branch"
        }
    } else {
        Skip "Remote branch not found (already deleted?): $branch"
    }
}

# ── 11. Push main + develop, verify ──────────────────────────────────────────
Step 11 "Pushing changes and verifying final state"

git push origin main
git push origin develop 2>$null

Write-Host "`n    Remaining remote branches:" -ForegroundColor DarkGray
git branch -r | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host "`n==========================================================" -ForegroundColor Magenta
Write-Host "  ALL DONE — Repository is clean." -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta
Write-Host @"

  Next steps on GitHub (manual — requires repo admin):
  ─────────────────────────────────────────────────────
  1. Go to: Settings > Branches > Add branch ruleset

  RULESET for 'main':
    - Target: main
    - Require pull request before merging (min 1 approval)
    - Require status checks: CI / Lint & Analyze, CI / Run Tests
    - Block force pushes
    - Restrict deletions

  RULESET for 'develop':
    - Target: develop
    - Require pull request before merging (min 1 approval)
    - Require status checks: CI / Lint & Analyze
    - Block force pushes

  2. Go to: Settings > General > Pull Requests
    - Allow squash merging ONLY (disable merge commits + rebase)
    - Automatically delete head branches (enable this checkbox)

  See docs/GIT_WORKFLOW.md for the full team strategy.
"@
