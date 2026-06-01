#!/usr/bin/env bash
# Decode installed .mobileprovision and ensure Push Notifications entitlement is present.
# Usage: ci_verify_provisioning_push.sh <path-to.mobileprovision> [expected-bundle-id]
set -euo pipefail

PP="${1:?mobileprovision path required}"
EXPECTED_BUNDLE="${2:-com.pc.fash-ios-mobile}"

PLIST="${TMPDIR:-/tmp}/fash_pp_$$.plist"
security cms -D -i "${PP}" > "${PLIST}"

NAME="$(/usr/libexec/PlistBuddy -c 'Print Name' "${PLIST}")"
APP_ID="$(/usr/libexec/PlistBuddy -c 'Print Entitlements:application-identifier' "${PLIST}")"
APS="$(/usr/libexec/PlistBuddy -c 'Print Entitlements:aps-environment' "${PLIST}" 2>/dev/null || true)"

echo "Profile: ${NAME}"
echo "application-identifier: ${APP_ID}"
echo "aps-environment: ${APS:-<missing>}"

if [[ "${APP_ID}" != *".${EXPECTED_BUNDLE}" ]]; then
  echo "::error::Profile is not for bundle ${EXPECTED_BUNDLE} (got ${APP_ID})"
  rm -f "${PLIST}"
  exit 1
fi

if [[ -z "${APS}" ]]; then
  echo "::error::Provisioning profile has no aps-environment — enable Push Notifications on the App ID and regenerate the profile."
  rm -f "${PLIST}"
  exit 1
fi

rm -f "${PLIST}"
echo "Provisioning profile includes push (aps-environment=${APS})"
