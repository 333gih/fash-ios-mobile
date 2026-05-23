#!/usr/bin/env bash
# Full Mac build: sync → xcodegen → xcodebuild (iOS Simulator)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${1:-Fash-Dev}"
SIMULATOR="${2:-iPhone 16}"

die() { echo "error: $*" >&2; exit 1; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "iOS builds require macOS + Xcode. On Windows run: .\\scripts\\sync.ps1 then build on a Mac."
fi

command -v python3 >/dev/null 2>&1 || die "python3 not found"
command -v xcodegen >/dev/null 2>&1 || die "XcodeGen not found — brew install xcodegen"
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found — install Xcode from the App Store"

echo "==> Sync strings + env config"
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py

echo "==> Generate Xcode project"
xcodegen generate

if [[ ! -d "Fash.xcodeproj" ]]; then
  die "Fash.xcodeproj was not created"
fi

DESTINATION="platform=iOS Simulator,name=${SIMULATOR}"
echo "==> Build scheme=${SCHEME} destination=${DESTINATION}"

xcodebuild \
  -project Fash.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath build/DerivedData \
  build \
  CODE_SIGNING_ALLOWED=NO

echo ""
echo "Build succeeded."
echo "Open in Xcode:  open Fash.xcodeproj"
echo "Run on simulator: select scheme ${SCHEME}, press Cmd+R (set Development Team for device/signing)."
