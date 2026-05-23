#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/android_strings_to_ios.py
python3 scripts/env_to_xcconfig.py
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Install XcodeGen: brew install xcodegen"
  exit 1
fi
xcodegen generate
echo "Generated Fash.xcodeproj"
echo "Build from terminal:  ./scripts/build_mac.sh"
echo "Or open in Xcode, set Development Team, then Cmd+R (scheme Fash-Dev)."
