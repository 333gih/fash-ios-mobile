#!/usr/bin/env bash
# Verify exported IPA matches project.yml MARKETING_VERSION + CURRENT_PROJECT_VERSION.
set -euo pipefail

IPA="${1:?IPA path required}"
PROJECT_YML="${2:-project.yml}"

EXPECTED_MARKETING="$(grep 'MARKETING_VERSION:' "${PROJECT_YML}" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
EXPECTED_BUILD="$(grep 'CURRENT_PROJECT_VERSION:' "${PROJECT_YML}" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
unzip -q "${IPA}" -d "${WORK}"

APP_PLIST="$(find "${WORK}/Payload" -maxdepth 2 -name Info.plist -path '*/Fash.app/*' | head -1)"
if [[ -z "${APP_PLIST}" ]]; then
  APP_PLIST="$(find "${WORK}/Payload" -maxdepth 2 -name Info.plist | head -1)"
fi
if [[ -z "${APP_PLIST}" ]]; then
  echo "::error::No Info.plist found inside ${IPA}"
  exit 1
fi

ACTUAL_MARKETING="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "${APP_PLIST}")"
ACTUAL_BUILD="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "${APP_PLIST}")"

echo "Expected: ${EXPECTED_MARKETING} (${EXPECTED_BUILD})"
echo "IPA:      ${ACTUAL_MARKETING} (${ACTUAL_BUILD})"

if [[ "${ACTUAL_MARKETING}" != "${EXPECTED_MARKETING}" || "${ACTUAL_BUILD}" != "${EXPECTED_BUILD}" ]]; then
  echo "::error::IPA version mismatch. Bump project.yml or rebuild before uploading to TestFlight."
  exit 1
fi

echo "IPA version OK"
