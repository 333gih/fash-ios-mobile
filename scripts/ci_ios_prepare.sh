#!/usr/bin/env bash
# GitHub Actions / TestFlight prep: validate committed source → xcodegen → SPM.
# Does NOT sync from fash-android-mobile (no sibling on CI). Strings/icons must be committed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${1:?usage: ci_ios_prepare.sh <Fash-Dev|Fash-Prod>}"

bash scripts/ci_validate_i18n.sh

echo "==> Validate Swift syntax"
python3 scripts/validate_swift_syntax.py

echo "==> Install XcodeGen"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen --version

echo "==> Generate Xcode project"
xcodegen generate

if grep -qE 'README\.md.*in Resources|path = .*README\.md' Fash.xcodeproj/project.pbxproj 2>/dev/null; then
  echo "error: README.md must not be a Copy Bundle Resource (breaks archive)." >&2
  grep 'README\.md' Fash.xcodeproj/project.pbxproj || true
  exit 1
fi

object_version="$(sed -n 's/.*objectVersion = \([0-9]*\);.*/\1/p' Fash.xcodeproj/project.pbxproj | head -1)"
echo "objectVersion=${object_version}"
if [[ "${object_version}" -gt 60 ]]; then
  sed -i '' -E 's/objectVersion = [0-9]+/objectVersion = 60/' Fash.xcodeproj/project.pbxproj
  echo "Downgraded objectVersion to 60 for Xcode 15/16 compatibility"
fi

echo "==> Resolve Swift packages (scheme=${SCHEME})"
xcodebuild -resolvePackageDependencies \
  -project Fash.xcodeproj \
  -scheme "${SCHEME}"
