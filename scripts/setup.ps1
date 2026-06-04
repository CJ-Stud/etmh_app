# ETMH — Windows setup helper.
#
# Run this from the project root in PowerShell AFTER you've installed
# Flutter and the Firebase + FlutterFire CLIs (see docs/SETUP.md
# sections 1.1–1.5):
#
#   powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
#
# It automates the boring parts of docs/SETUP.md sections 2 and 5,
# then leaves you with one final manual step (flutterfire configure).

$ErrorActionPreference = "Stop"

function Info($m)  { Write-Host "▸ $m" -ForegroundColor Green }
function Warn($m)  { Write-Host "⚠ $m" -ForegroundColor Yellow }
function Fatal($m) { Write-Host "✖ $m" -ForegroundColor Red; exit 1 }

# ── Pre-flight ───────────────────────────────────────────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Fatal "flutter not on PATH. Install from https://docs.flutter.dev/get-started/install first."
}

$flutterVer = (flutter --version | Select-Object -First 1) -replace '^Flutter (\S+).*', '$1'
Info "Flutter $flutterVer detected."

# ── 1. Generate native scaffolding (idempotent) ──────────────────────
if (-not (Test-Path "android") -or -not (Test-Path "ios")) {
  Info "Generating native scaffolding..."
  flutter create --org com.etmh --project-name etmh_app . | Out-Null
} else {
  Info "Native scaffolding already exists, skipping flutter create."
}

# ── 2. Bump Android minSdk to 23 ─────────────────────────────────────
$gradleKts    = "android\app\build.gradle.kts"
$gradleGroovy = "android\app\build.gradle"

function Patch-File($path, $find, $replace) {
  if (Test-Path $path) {
    $content = Get-Content $path -Raw
    if ($content -match [regex]::Escape($find)) {
      ($content -replace [regex]::Escape($find), $replace) | Set-Content $path -NoNewline
      Info "Patched $path"
      return $true
    }
  }
  return $false
}

$patched = Patch-File $gradleKts "minSdk = flutter.minSdkVersion" "minSdk = 23"
if (-not $patched) {
  $patched = Patch-File $gradleGroovy "minSdkVersion flutter.minSdkVersion" "minSdkVersion 23"
}
if (-not $patched) {
  Warn "Could not auto-set Android minSdk to 23. Edit android\app\build.gradle.kts manually per SETUP.md §5.1."
}

# Podfile bumping is skipped on Windows — iOS builds require macOS.

# ── 3. Install Dart packages ─────────────────────────────────────────
Info "Running 'flutter pub get'..."
flutter pub get

# ── Done ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╭──────────────────────────────────────────────────────────────────╮" -ForegroundColor Cyan
Write-Host "│  ✓ Local setup complete.                                         │" -ForegroundColor Cyan
Write-Host "│                                                                  │" -ForegroundColor Cyan
Write-Host "│  ONE LAST STEP — connect to your Firebase project:               │" -ForegroundColor Cyan
Write-Host "│                                                                  │" -ForegroundColor Cyan
Write-Host "│      flutterfire configure                                       │" -ForegroundColor Cyan
Write-Host "│                                                                  │" -ForegroundColor Cyan
Write-Host "│  (Follow the prompts. See docs\SETUP.md §4 for details.)         │" -ForegroundColor Cyan
Write-Host "│                                                                  │" -ForegroundColor Cyan
Write-Host "│  After that:                                                     │" -ForegroundColor Cyan
Write-Host "│      flutter run                                                 │" -ForegroundColor Cyan
Write-Host "╰──────────────────────────────────────────────────────────────────╯" -ForegroundColor Cyan
