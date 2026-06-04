#!/usr/bin/env bash
# ETMH — macOS / Linux setup helper.
#
# Run this from the project root AFTER you've installed Flutter and the
# Firebase + FlutterFire CLIs (see docs/SETUP.md sections 1.1–1.5):
#
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
#
# It automates the boring parts of docs/SETUP.md sections 2 and 5,
# then leaves you with one final manual step (flutterfire configure).

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}▸ %s${NC}\n" "$1"; }
warn()  { printf "${YELLOW}⚠ %s${NC}\n" "$1"; }
fatal() { printf "${RED}✖ %s${NC}\n" "$1"; exit 1; }

# ── Pre-flight ────────────────────────────────────────────────────────
command -v flutter >/dev/null 2>&1 || \
  fatal "flutter not on PATH. Install from https://docs.flutter.dev/get-started/install first."

FLUTTER_VERSION=$(flutter --version | head -n 1 | awk '{print $2}')
info "Flutter $FLUTTER_VERSION detected."

# ── 1. Generate native scaffolding (idempotent) ───────────────────────
if [ ! -d "android" ] || [ ! -d "ios" ]; then
  info "Generating Android + iOS scaffolding..."
  flutter create --org com.etmh --project-name etmh_app . >/dev/null
else
  info "Native scaffolding already exists, skipping flutter create."
fi

# ── 2. Bump Android minSdk to 23 ──────────────────────────────────────
GRADLE_KTS="android/app/build.gradle.kts"
GRADLE_GROOVY="android/app/build.gradle"

if [ -f "$GRADLE_KTS" ]; then
  if grep -q "minSdk = flutter.minSdkVersion" "$GRADLE_KTS"; then
    sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 23/' "$GRADLE_KTS"
    rm "$GRADLE_KTS.bak"
    info "Set Android minSdk = 23 in build.gradle.kts"
  else
    warn "Could not auto-edit $GRADLE_KTS. Set minSdk = 23 manually (see SETUP.md §5.1)."
  fi
elif [ -f "$GRADLE_GROOVY" ]; then
  if grep -q "minSdkVersion flutter.minSdkVersion" "$GRADLE_GROOVY"; then
    sed -i.bak 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' "$GRADLE_GROOVY"
    rm "$GRADLE_GROOVY.bak"
    info "Set Android minSdkVersion 23 in build.gradle"
  else
    warn "Could not auto-edit $GRADLE_GROOVY. Set minSdkVersion 23 manually (see SETUP.md §5.1)."
  fi
fi

# ── 3. Bump iOS deployment target to 15.0 (macOS hosts only) ──────────
if [[ "$OSTYPE" == "darwin"* ]] && [ -f "ios/Podfile" ]; then
  if grep -q "# platform :ios, '13.0'" ios/Podfile; then
    sed -i.bak "s/# platform :ios, '13.0'/platform :ios, '15.0'/" ios/Podfile
    rm ios/Podfile.bak
    info "Set iOS platform = '15.0' in ios/Podfile"
  fi
fi

# ── 4. Install Dart packages ──────────────────────────────────────────
info "Running 'flutter pub get'..."
flutter pub get

# ── 5. Pods (macOS only) ──────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]] && command -v pod >/dev/null 2>&1; then
  if [ -d "ios" ]; then
    info "Installing CocoaPods (ios)..."
    (cd ios && pod install --repo-update || warn "pod install reported warnings — review above.")
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────
cat <<'EOM'

╭──────────────────────────────────────────────────────────────────╮
│  ✓ Local setup complete.                                         │
│                                                                  │
│  ONE LAST STEP — connect to your Firebase project:               │
│                                                                  │
│      flutterfire configure                                       │
│                                                                  │
│  (Follow the prompts. See docs/SETUP.md §4 for details.)         │
│                                                                  │
│  After that:                                                     │
│      flutter run                                                 │
╰──────────────────────────────────────────────────────────────────╯
EOM
