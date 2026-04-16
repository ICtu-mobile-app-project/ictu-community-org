# ============================================================
# cleanup-root.ps1
# Deletes leftover zero-byte / misnamed files from the root.
# Run once from the repo root:  .\scripts\cleanup-root.ps1
# ============================================================

$repoRoot = Split-Path -Parent $PSScriptRoot

$filesToDelete = @(
    "_isWorking",
    "AlertDialog(",
    "Navigator.of(context).pop(false)",
    "Navigator.of(context).pop(true)",
    "NoteDetailsScreen(note"
)

foreach ($file in $filesToDelete) {
    $path = Join-Path $repoRoot $file
    if (Test-Path $path) {
        Remove-Item $path -Force
        Write-Host "Deleted: $file" -ForegroundColor Green
    } else {
        Write-Host "Not found (already clean): $file" -ForegroundColor Yellow
    }
}

Write-Host "`nRoot cleanup complete." -ForegroundColor Cyan
