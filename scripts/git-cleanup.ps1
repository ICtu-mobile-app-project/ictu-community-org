# ============================================================
# git-cleanup.ps1
# Prunes stale remote branches and sets up branch protection
# conventions locally. Run from the repo root:
#   .\scripts\git-cleanup.ps1
#
# Requirements: git must be on your PATH and you must be
# authenticated (gh CLI or HTTPS credential manager).
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "`n=== ICTU Community — Repository Cleanup ===" -ForegroundColor Cyan

# ── 1. Fetch and prune dead remote-tracking refs ─────────────
Write-Host "`n[1/4] Pruning stale remote-tracking branches..." -ForegroundColor Yellow
git fetch --prune origin
Write-Host "Done." -ForegroundColor Green

# ── 2. Delete known stale local branches ─────────────────────
Write-Host "`n[2/4] Deleting stale local branches..." -ForegroundColor Yellow

$staleBranches = @(
    "copilot/sub-pr-1",
    "Feature-1-Authentication-branch"
)

foreach ($branch in $staleBranches) {
    $exists = git branch --list $branch
    if ($exists) {
        git branch -d $branch 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Force-delete if not fully merged
            git branch -D $branch
            Write-Host "Force-deleted (unmerged): $branch" -ForegroundColor Magenta
        } else {
            Write-Host "Deleted: $branch" -ForegroundColor Green
        }
    } else {
        Write-Host "Not found locally (already clean): $branch" -ForegroundColor DarkGray
    }
}

# ── 3. List remaining local branches for review ──────────────
Write-Host "`n[3/4] Remaining local branches:" -ForegroundColor Yellow
git branch -v

# ── 4. Ensure develop branch exists ──────────────────────────
Write-Host "`n[4/4] Checking develop branch..." -ForegroundColor Yellow
$developExists = git branch --list "develop"
if (-not $developExists) {
    git checkout -b develop main
    git push -u origin develop
    Write-Host "Created and pushed 'develop' branch." -ForegroundColor Green
} else {
    Write-Host "'develop' already exists." -ForegroundColor Green
}

Write-Host "`n=== Cleanup complete ===" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Go to GitHub > Settings > Branches" -ForegroundColor Gray
Write-Host "  2. Add branch protection rule for 'main':" -ForegroundColor Gray
Write-Host "     - Require pull request before merging (1 approval)" -ForegroundColor Gray
Write-Host "     - Require status checks: CI / Lint & Analyze, CI / Run Tests" -ForegroundColor Gray
Write-Host "     - Do not allow bypassing the above settings" -ForegroundColor Gray
Write-Host "  3. Repeat protection for 'develop'" -ForegroundColor Gray
