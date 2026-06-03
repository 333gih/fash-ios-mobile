#!/usr/bin/env bash
# Upload IPA to TestFlight via altool. Treats Apple daily upload limit (90382) as non-fatal so CI stays green when archive succeeded.
set -euo pipefail

IPA="${1:-build/Fash.ipa}"
LOG="${UPLOAD_LOG:-upload-testflight.log}"

: "${ISSUER_ID:?ISSUER_ID required}"
: "${API_KEY_ID:?API_KEY_ID required}"
: "${API_PRIVATE_KEY:?API_PRIVATE_KEY required}"

if [[ ! -f "${IPA}" ]]; then
  echo "::error::IPA not found: ${IPA}"
  exit 1
fi

KEY_DIR="${RUNNER_TEMP:-/tmp}/private_keys"
mkdir -p "${KEY_DIR}"
KEY_FILE="${KEY_DIR}/AuthKey_${API_KEY_ID}.p8"
printf '%s\n' "${API_PRIVATE_KEY}" > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"

set +e
xcrun altool --output-format xml --upload-app --file "${IPA}" --type ios \
  --apiKey "${API_KEY_ID}" \
  --apiIssuer "${ISSUER_ID}" 2>&1 | tee "${LOG}"
code="${PIPESTATUS[0]}"
set -e

if [[ "${code}" -eq 0 ]]; then
  echo "upload_outcome=success" >> "${GITHUB_OUTPUT}"
  exit 0
fi

if grep -qE '90382|Upload limit reached' "${LOG}"; then
  echo "::warning::TestFlight daily upload limit (90382). Archive and IPA artifact succeeded — retry upload in ~24h (re-run workflow or workflow_dispatch)."
  echo "upload_outcome=rate_limited" >> "${GITHUB_OUTPUT}"
  exit 0
fi

echo "::error::TestFlight upload failed (see ${LOG})"
echo "upload_outcome=failure" >> "${GITHUB_OUTPUT}"
exit "${code}"
