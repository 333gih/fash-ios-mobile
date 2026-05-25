#!/usr/bin/env bash
# Standalone Mac build: xcodegen → xcodebuild (iOS Simulator). No Android checkout required.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${1:-Fash-Dev}"
SIMULATOR="${2:-iPhone 16}"

die() { echo "error: $*" >&2; exit 1; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "iOS builds require macOS + Xcode. On Windows run: .\\scripts\\sync.ps1 (optional) then build on a Mac."
fi

command -v xcodegen >/dev/null 2>&1 || die "XcodeGen not found — brew install xcodegen"
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found — install Xcode from the App Store"

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
