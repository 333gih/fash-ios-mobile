#!/usr/bin/env bash
# Standalone Mac setup — no fash-android-mobile required (env/strings/fonts are in-repo).
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen not found — install: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate
echo "Generated Fash.xcodeproj"
echo "Build: ./scripts/build_mac.sh"
echo "Open:  open Fash.xcodeproj  (scheme Fash-Dev, set Development Team)"
