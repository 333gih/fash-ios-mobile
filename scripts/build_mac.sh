#!/usr/bin/env bash
# Standalone Mac build: validate → xcodegen → xcodebuild (iOS Simulator).
# Default destination matches .github/workflows/ios-build.yml (iPhone 15, iOS 17.5).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${1:-Fash-Dev}"
# Match GitHub Actions ios-build.yml destination when possible.
SIMULATOR_OS="${SIMULATOR_OS:-iPhone 15,OS=17.5}"
SIMULATOR="${2:-${SIMULATOR_OS}}"

die() { echo "error: $*" >&2; exit 1; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "iOS builds require macOS + Xcode. On Windows: sync locally, commit, then build on Mac."
fi

command -v xcodegen >/dev/null 2>&1 || die "XcodeGen not found — brew install xcodegen"
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found — install Xcode from the App Store"

echo "==> Validate (same as CI)"
bash scripts/ci_validate_i18n.sh
python3 scripts/validate_swift_syntax.py

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
