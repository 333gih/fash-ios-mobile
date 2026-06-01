#!/usr/bin/env bash
# Verify exported IPA includes FCM prerequisites (TestFlight / App Store).
# Usage: ci_verify_ipa_push.sh <path-to.ipa> [expected-aps-environment]
#   expected-aps-environment: production (Fash-Prod) or development (Fash-Dev). Default: production
set -euo pipefail

IPA="${1:?IPA path required}"
EXPECTED_APS="${2:-production}"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
unzip -q "${IPA}" -d "${WORK}"

APP_DIR="$(find "${WORK}/Payload" -maxdepth 1 -type d -name '*.app' | head -1)"
if [[ -z "${APP_DIR}" ]]; then
  echo "::error::No .app bundle found inside ${IPA}"
  exit 1
fi

echo "App bundle: ${APP_DIR}"

GS_PLIST="${APP_DIR}/GoogleService-Info.plist"
if [[ ! -f "${GS_PLIST}" ]]; then
  echo "::error::GoogleService-Info.plist is NOT in the app bundle — Firebase/FCM will not initialize on device."
  echo "Ensure GOOGLE_SERVICE_INFO_PLIST_BASE64 is set and the plist is written before xcodegen (see docs/CI.md)."
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "${GS_PLIST}")"
PROJECT_ID="$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "${GS_PLIST}")"
echo "GoogleService-Info.plist OK (PROJECT_ID=${PROJECT_ID}, BUNDLE_ID=${BUNDLE_ID})"

ENT_XML="${WORK}/entitlements.xml"
if ! codesign -d --entitlements :- "${APP_DIR}" > "${ENT_XML}" 2>/dev/null; then
  echo "::error::Could not read code-signed entitlements from ${APP_DIR}"
  exit 1
fi

APS="$(/usr/libexec/PlistBuddy -c 'Print :aps-environment' "${ENT_XML}" 2>/dev/null || true)"
if [[ -z "${APS}" ]]; then
  echo "::error::aps-environment entitlement missing from signed app — provisioning profile likely lacks Push Notifications."
  echo "Regenerate App Store profile for com.pc.fash-ios-mobile with Push enabled, update IOS_PROVISIONING_PROFILE_BASE64."
  exit 1
fi

echo "aps-environment=${APS}"
if [[ "${APS}" != "${EXPECTED_APS}" ]]; then
  echo "::error::Expected aps-environment=${EXPECTED_APS} for this scheme, got ${APS}."
  echo "Fash-Prod/TestFlight must use Fash-Prod.entitlements (production). Fash-Dev uses development."
  exit 1
fi

APP_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "${APP_DIR}/Info.plist")"
if [[ "${BUNDLE_ID}" != "${APP_BUNDLE_ID}" ]]; then
  echo "::error::GoogleService-Info BUNDLE_ID (${BUNDLE_ID}) != app CFBundleIdentifier (${APP_BUNDLE_ID})"
  exit 1
fi

echo "IPA push prerequisites OK (plist in bundle, aps-environment=${APS})"
