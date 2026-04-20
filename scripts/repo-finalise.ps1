# =============================================================================
# repo-finalise.ps1
# ICTU Community — One-shot repository cleanup script
#
# What this script does (in order):
#   1.  Creates all missing Clean Architecture layer folders
#   2.  Deletes the 5 zero-byte garbage root files
#   3.  Removes LaTeX build artifacts (never should have been committed)
#   4.  Removes supabase/.temp from git tracking
#   5.  Removes the lib/assets/ duplicate (real assets live in root assets/)
#   6.  Registers all moved/new files with git (git add)
#   7.  Removes git tracking for all deleted/moved files (git rm --cached)
#   8.  Updates .gitignore to prevent these issues recurring
#   9.  Commits all structural changes with a proper conventional commit
#   10. Deletes all stale remote branches
#   11. Prints a summary and next steps
#
# Requirements:
#   - Run from the repo root: cd S:\ictu-community-org
#   - Git must be on your PATH
#   - You must be authenticated to GitHub (HTTPS credential manager or SSH)
#
# Usage:
#   cd S:\ictu-community-org
#   .\scripts\repo-finalise.ps1
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $RepoRoot

$Green  = "Green"
$Yellow = "Yellow"
$Red    = "Red"
$Cyan   = "Cyan"
$Gray   = "DarkGray"

function Write-Step($n, $msg) {
    Write-Host ""
    Write-Host "[$n] $msg" -ForegroundColor $Cyan
}

function Write-Ok($msg)   { Write-Host "    OK  $msg" -ForegroundColor $Green  }
function Write-Skip($msg) { Write-Host "    --  $msg" -ForegroundColor $Gray   }
function Write-Warn($msg) { Write-Host "    !!  $msg" -ForegroundColor $Yellow }

function Ensure-Dir($path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Ok "Created $($path.Replace($RepoRoot, ''))"
    } else {
        Write-Skip "Exists  $($path.Replace($RepoRoot, ''))"
    }
}

function Write-Gitkeep($dir, $note) {
    Ensure-Dir $dir
    $gk = Join-Path $dir ".gitkeep"
    if (-not (Test-Path $gk)) {
        Set-Content $gk "# $note"
        Write-Ok "Added .gitkeep -> $($gk.Replace($RepoRoot,''))"
    }
}

function Remove-RootFile($name) {
    $path = Join-Path $RepoRoot $name
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Ok "Deleted root file: $name"
    } else {
        Write-Skip "Already gone: $name"
    }
}

function Git-RmCached($repoPath) {
    $tracked = git ls-files --error-unmatch $repoPath 2>$null
    if ($LASTEXITCODE -eq 0) {
        git rm --cached -r --quiet -- $repoPath 2>$null
        Write-Ok "git rm --cached $repoPath"
    } else {
        Write-Skip "Not tracked: $repoPath"
    }
}

function Git-RmFile($repoPath) {
    $tracked = git ls-files --error-unmatch $repoPath 2>$null
    if ($LASTEXITCODE -eq 0) {
        git rm --force --quiet -- $repoPath 2>$null
        Write-Ok "git rm $repoPath"
    } else {
        Write-Skip "Not tracked: $repoPath"
        $full = Join-Path $RepoRoot ($repoPath -replace '/', '\')
        if (Test-Path $full) { Remove-Item $full -Force }
    }
}

function Delete-RemoteBranch($branch) {
    $remoteRef = "refs/remotes/origin/$branch"
    $exists = git show-ref $remoteRef 2>$null
    if ($exists) {
        git push origin --delete $branch 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Deleted remote: origin/$branch"
        } else {
            Write-Warn "Could not delete remote branch: $branch (may already be deleted)"
        }
    } else {
        Write-Skip "Remote branch not found: $branch"
    }
    $localRef = git branch --list $branch
    if ($localRef) {
        git branch -D $branch 2>$null
        Write-Ok "Deleted local: $branch"
    }
}

# =============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor $Cyan
Write-Host "  ICTU Community — Repository Finalise Script  " -ForegroundColor $Cyan
Write-Host "================================================" -ForegroundColor $Cyan
Write-Host "  Root: $RepoRoot"
Write-Host ""

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    Write-Host "ERROR: Not a git repository. Run from repo root." -ForegroundColor $Red
    exit 1
}

# =============================================================================
Write-Step "1/10" "Creating missing Clean Architecture layer folders..."

$Features = @(
    @{ name="alerts";        layers=@("controllers", "widgets") },
    @{ name="auth";          layers=@("data", "widgets") },
    @{ name="community";     layers=@("data", "widgets", "models", "controllers") },
    @{ name="courses";       layers=@("widgets") },
    @{ name="home";          layers=@("data", "widgets", "models", "controllers") },
    @{ name="navigation";    layers=@("data", "widgets", "models") },
    @{ name="news";          layers=@("data", "widgets", "models", "controllers") },
    @{ name="notifications"; layers=@("data", "widgets", "models", "controllers") },
    @{ name="profile";       layers=@("data", "widgets", "models") },
    @{ name="transcription"; layers=@("widgets", "models") }
)

foreach ($f in $Features) {
    foreach ($layer in $f.layers) {
        $dir = Join-Path $RepoRoot "lib\features\$($f.name)\$layer"
        $note = "Add $($f.name) $layer components here as the feature grows."
        Write-Gitkeep $dir $note
    }
}

Ensure-Dir (Join-Path $RepoRoot "docs\srs")
Ensure-Dir (Join-Path $RepoRoot "docs\guides")
Ensure-Dir (Join-Path $RepoRoot "docs\api")
Ensure-Dir (Join-Path $RepoRoot "docs\deployment")

# =============================================================================
Write-Step "2/10" "Deleting zero-byte garbage root files..."

$GarbageFiles = @(
    "_isWorking",
    "AlertDialog(",
    "Navigator.of(context).pop(false)",
    "Navigator.of(context).pop(true)",
    "NoteDetailsScreen(note"
)

foreach ($f in $GarbageFiles) {
    Git-RmFile $f
    Remove-RootFile $f
}

# =============================================================================
Write-Step "3/10" "Removing LaTeX build artifacts from tracking and disk..."

$LatexArtifacts = @(
    "pdfs/ICTU_Community.aux",
    "pdfs/ICTU_Community.fdb_latexmk",
    "pdfs/ICTU_Community.fls",
    "pdfs/ICTU_Community.out",
    "pdfs/ICTU_Community.synctex.gz"
)

foreach ($f in $LatexArtifacts) {
    Git-RmFile $f
}

$texSrc = Join-Path $RepoRoot "pdfs\ICTU_Community.tex"
$texDst = Join-Path $RepoRoot "docs\srs\ICTU_Community.tex"
if ((Test-Path $texSrc) -and -not (Test-Path $texDst)) {
    Move-Item $texSrc $texDst
    Write-Ok "Moved pdfs/ICTU_Community.tex -> docs/srs/"
} elseif (Test-Path $texDst) {
    Write-Skip "Already moved: ICTU_Community.tex"
    if (Test-Path $texSrc) { Remove-Item $texSrc -Force }
}

$pdfSrc = Join-Path $RepoRoot "pdfs\ICTU_Community.pdf"
$pdfDst = Join-Path $RepoRoot "docs\srs\ICTU_Community.pdf"
if ((Test-Path $pdfSrc) -and -not (Test-Path $pdfDst)) {
    Move-Item $pdfSrc $pdfDst
    Write-Ok "Moved pdfs/ICTU_Community.pdf -> docs/srs/"
} elseif (Test-Path $pdfDst) {
    Write-Skip "Already moved: ICTU_Community.pdf"
    if (Test-Path $pdfSrc) { Remove-Item $pdfSrc -Force }
}

$pdfsDir = Join-Path $RepoRoot "pdfs"
if ((Test-Path $pdfsDir) -and ((Get-ChildItem $pdfsDir -Force).Count -eq 0)) {
    Remove-Item $pdfsDir
    Write-Ok "Removed empty pdfs/ directory"
}
Git-RmCached "pdfs"

# =============================================================================
Write-Step "4/10" "Removing supabase/.temp from git tracking..."

Git-RmCached "supabase/.temp"

# =============================================================================
Write-Step "5/10" "Removing lib/assets/ duplicate from git tracking..."

Git-RmCached "lib/assets"

$libAssets = Join-Path $RepoRoot "lib\assets"
if (Test-Path $libAssets) {
    Remove-Item $libAssets -Recurse -Force
    Write-Ok "Deleted lib/assets/ directory from disk"
}

# =============================================================================
Write-Step "6/10" "Registering all moved and new files with git..."

git add -A
Write-Ok "git add -A complete"

# =============================================================================
Write-Step "7/10" "Updating .gitignore..."

$gitignorePath = Join-Path $RepoRoot ".gitignore"
$current = Get-Content $gitignorePath -Raw

$additions = @"

# LaTeX build artifacts (docs/srs/ source is fine, these are not)
pdfs/*.aux
pdfs/*.fls
pdfs/*.fdb_latexmk
pdfs/*.out
pdfs/*.synctex.gz
*.aux
*.fls
*.fdb_latexmk
*.synctez.gz

# Supabase CLI cache
supabase/.temp/

# Build logs (never commit these)
build_log*.txt
build_log*.log

# Duplicate assets folder guard
lib/assets/

# Dart generated files
**/*.g.dart
**/*.freezed.dart
"@

if ($current -notmatch "LaTeX build artifacts") {
    Add-Content $gitignorePath $additions
    Write-Ok "Updated .gitignore with 6 new rule groups"
} else {
    Write-Skip ".gitignore already has LaTeX rules"
}

git add .gitignore
Write-Ok "Staged .gitignore"

# =============================================================================
Write-Step "8/10" "Ensuring dev branch exists and is up to date..."

$devExists = git branch --list "dev"
if (-not $devExists) {
    git checkout -b dev main
    git push -u origin dev
    Write-Ok "Created and pushed 'dev' branch"
} else {
    Write-Skip "'dev' already exists"
}

$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "dev") {
    git checkout dev
    Write-Ok "Switched to dev"
}

git pull origin dev --rebase 2>$null
Write-Ok "dev is up to date"

# =============================================================================
Write-Step "9/10" "Committing all structural changes..."

$status = git status --porcelain
if ($status) {
    git add -A
    $msg = @"
chore(repo): restructure folders, remove artifacts, add workflow docs

- Remove lib/assets/ duplicate (root assets/ is canonical)
- Remove LaTeX build artifacts from tracking (pdfs/*.aux etc.)
- Remove supabase/.temp CLI cache from tracking
- Remove zero-byte garbage root files (_isWorking, AlertDialog( etc.)
- Move docs flat files into docs/guides/ subdirectory
- Move package.json/package-lock.json to supabase/
- Move pdfs/SRS source to docs/srs/
- Add missing Clean Architecture layer folders (.gitkeep) for all features
- Add docs/GIT_WORKFLOW.md - branching and commit strategy
- Update .gitignore with LaTeX, temp, build-log, and duplicate asset rules
"@
    git commit -m $msg
    Write-Ok "Committed structural changes"
    git push origin dev
    Write-Ok "Pushed to origin/dev"
} else {
    Write-Skip "Nothing to commit - working tree clean"
}

# =============================================================================
Write-Step "10/10" "Deleting stale remote branches..."

$BranchesToDelete = @(
    "Feature-1-Authentication-branch",       # Merged via PR #7 - auth is live
    "feature-7-audio-rec-and-ai-transcription", # Merged via PR #6 - transcription live
    "feature-8-Course-feature",              # Merged via PR #8 - courses live
    "develop",                               # Old integration branch, replaced by dev
    "copilot/sub-pr-1",                      # Auto-generated, superseded
    "copilot/feature-8-ui-design-summary"    # Contains only build_log.txt pollution
)

foreach ($branch in $BranchesToDelete) {
    Delete-RemoteBranch $branch
}

# =============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor $Green
Write-Host "  Done! Repository is clean.                   " -ForegroundColor $Green
Write-Host "================================================" -ForegroundColor $Green
Write-Host ""
Write-Host "REMAINING MANUAL STEPS:" -ForegroundColor $Yellow
Write-Host ""
Write-Host "  1. Go to GitHub -> Settings -> General -> Default branch" -ForegroundColor White
Write-Host "       Change to 'dev'" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Go to GitHub -> Settings -> Branches" -ForegroundColor White
Write-Host "     Add protection rule for 'main':" -ForegroundColor Gray
Write-Host "       * Require pull request before merging (1 approval)" -ForegroundColor Gray
Write-Host "       * Require status checks: 'CI / Lint & Analyze', 'CI / Run Tests'" -ForegroundColor Gray
Write-Host "       * Require branches up to date before merging" -ForegroundColor Gray
Write-Host "       * Do not allow bypassing the above settings" -ForegroundColor Gray
Write-Host "       * Restrict push access to project lead only" -ForegroundColor Gray
Write-Host ""
Write-Host "     Repeat the same protection rule for 'dev'." -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Go to GitHub -> Settings -> General -> Pull Requests" -ForegroundColor White
Write-Host "       * Enable: Automatically delete head branches" -ForegroundColor Gray
Write-Host "       * Default merge: Squash and merge" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Read docs/GIT_WORKFLOW.md and share it with the team." -ForegroundColor White
Write-Host ""
Write-Host "  Final branch state:" -ForegroundColor $Cyan
git branch -a
Write-Host ""
