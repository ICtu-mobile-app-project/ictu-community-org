param (
    [Parameter(Mandatory=$true)]
    [string]$appId,
    [string]$notes = "New version available",
    [string]$groups = "testers"
)

Write-Host "🚀 Starting ICTU App Distribution..." -ForegroundColor Cyan

# 1. Clean and Get Packages
Write-Host "📦 Cleaning and getting packages..."
flutter clean
flutter pub get

# 2. Build Release APK
Write-Host "🛠 Building Release APK..."
flutter build apk --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Distribute to Firebase
Write-Host "📤 Uploading to Firebase App Distribution..."
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk `
  --app $appId `
  --groups $groups `
  --release-notes "$notes"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Distribution Successful!" -ForegroundColor Green
} else {
    Write-Host "❌ Distribution Failed. Make sure you are logged in (firebase login)." -ForegroundColor Red
}
